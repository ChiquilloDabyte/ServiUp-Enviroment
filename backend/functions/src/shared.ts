import {getApp, getApps, initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";
import {HttpsError} from "firebase-functions/v2/https";

export const app = getApps().length === 0 ? initializeApp() : getApp();
export const db = getFirestore(app);

/**
 * Returns an authenticated user id or raises a callable error.
 * @param {string|undefined} uid Callable authentication identifier.
 * @return {string} Authenticated user identifier.
 */
export function requireAuthUid(uid: string | undefined): string {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }
  return uid;
}

/**
 * Validates and normalizes a required string received by a callable.
 * @param {unknown} value Raw callable value.
 * @param {string} field Public field name used in the error.
 * @param {number} maxLength Maximum accepted length.
 * @return {string} Trimmed validated value.
 */
export function requireString(
  value: unknown,
  field: string,
  maxLength = 128,
): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${field} no es válido.`);
  }
  const normalized = value.trim();
  if (normalized.length === 0 || normalized.length > maxLength) {
    throw new HttpsError("invalid-argument", `${field} no es válido.`);
  }
  return normalized;
}

/**
 * Loads the private domain profile for an authenticated user.
 * @param {string} uid Authenticated user identifier.
 */
export async function requireUser(uid: string) {
  const snapshot = await db.collection("users").doc(uid).get();
  const data = snapshot.data();
  if (!data) {
    throw new HttpsError("failed-precondition", "El perfil no existe.");
  }
  return data;
}

/**
 * Sends a push when the recipient still has a valid device token.
 * @param {string} userId Recipient identifier.
 * @param {string} title Notification title.
 * @param {string} body Notification body.
 * @param {Record<string, string>} payload Navigation payload.
 */
async function sendPush(
  userId: string,
  title: string,
  body: string,
  payload: Record<string, string>,
) {
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  const token = userDoc.data()?.fcmToken as string | undefined;
  if (!token) return;

  try {
    await getMessaging(app).send({
      token,
      notification: {title, body},
      data: payload,
    });
  } catch (error) {
    const code = (error as {code?: string}).code;
    logger.error("Could not send push notification", {userId, code});
    if (
      code === "messaging/invalid-registration-token" ||
      code === "messaging/registration-token-not-registered"
    ) {
      await userRef.update({fcmToken: FieldValue.delete()});
    }
  }
}

/**
 * Persists a notification once and sends its corresponding push once.
 * @param {object} params Notification contract.
 */
export async function notifyUser(params: {
  id: string;
  userId: string;
  type: string;
  title: string;
  body: string;
  payload: Record<string, string>;
}) {
  const notificationRef = db.collection("notifications").doc(params.id);
  const created = await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(notificationRef);
    if (existing.exists) return false;
    transaction.create(notificationRef, {
      userId: params.userId,
      type: params.type,
      title: params.title,
      body: params.body,
      payload: params.payload,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (created) {
    await sendPush(
      params.userId,
      params.title,
      params.body,
      params.payload,
    );
  }
}
