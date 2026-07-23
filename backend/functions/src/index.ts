import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";
import {setGlobalOptions} from "firebase-functions";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";

initializeApp();
setGlobalOptions({maxInstances: 10});

const db = getFirestore();

/**
 * Sends an FCM push when the recipient has a registered token.
 *
 * @param {string} userId Recipient user identifier.
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
  const userDoc = await db.collection("users").doc(userId).get();
  const token = userDoc.data()?.fcmToken as string | undefined;
  if (!token) {
    logger.warn("No FCM token for user", {userId});
    return;
  }

  try {
    await getMessaging().send({
      token,
      notification: {title, body},
      data: payload,
    });
  } catch (error) {
    logger.error("Could not send push notification", {userId, error});
  }
}

/**
 * Persists an in-app notification and sends its matching push.
 *
 * @param {string} userId Recipient user identifier.
 * @param {string} type Notification type.
 * @param {string} title Notification title.
 * @param {string} body Notification body.
 * @param {Record<string, string>} payload Navigation payload.
 */
async function notifyUser(
  userId: string,
  type: string,
  title: string,
  body: string,
  payload: Record<string, string>,
) {
  await db.collection("notifications").add({
    userId,
    type,
    title,
    body,
    payload,
    read: false,
    createdAt: new Date(),
  });
  await sendPush(userId, title, body, payload);
}

export const onOfferCreated = onDocumentCreated(
  "offers/{offerId}",
  async (event) => {
    const offer = event.data?.data();
    if (!offer) return;

    const requestDoc = await db
      .collection("service_requests")
      .doc(offer.requestId as string)
      .get();
    const clientId = requestDoc.data()?.clientId as string | undefined;
    const providerId = offer.providerId as string;
    const creatorId = (offer.createdById as string | undefined) ?? providerId;
    const recipientId = creatorId === clientId ? providerId : clientId;
    if (!recipientId) return;

    const title = "Nueva propuesta";
    const body = `Precio propuesto: $${offer.proposedPrice}`;
    const payload = {
      requestId: offer.requestId as string,
      offerId: event.params.offerId,
      chatId: (offer.chatId as string | undefined) ?? "",
    };

    await notifyUser(
      recipientId,
      "offer_created",
      title,
      body,
      payload,
    );
  },
);

export const onOfferAccepted = onDocumentUpdated(
  "offers/{offerId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status || after.status !== "accepted") return;

    const requestDoc = await db
      .collection("service_requests")
      .doc(after.requestId as string)
      .get();
    const clientId = requestDoc.data()?.clientId as string | undefined;
    const providerId = after.providerId as string;
    const creatorId = (after.createdById as string | undefined) ?? providerId;
    const recipientId = creatorId;
    if (!recipientId) return;

    const title = "Propuesta aceptada";
    const body = recipientId === providerId ?
      "El cliente aceptó tu propuesta." :
      "El proveedor aceptó tu propuesta.";
    const payload = {
      requestId: after.requestId as string,
      offerId: event.params.offerId,
      chatId: (after.chatId as string | undefined) ?? "",
    };

    if (recipientId === clientId || recipientId === providerId) {
      await notifyUser(
        recipientId,
        "offer_accepted",
        title,
        body,
        payload,
      );
    }
  },
);

export const onChatMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const chatDoc = await db
      .collection("chats")
      .doc(event.params.chatId)
      .get();
    const chat = chatDoc.data();
    if (!chat) return;

    const senderId = message.senderId as string;
    const recipientId = senderId === chat.clientId ?
      chat.providerId as string :
      chat.clientId as string;
    const senderName = senderId === chat.clientId ?
      (chat.clientName as string || "Cliente") :
      (chat.providerName as string || "Prestador");
    const body = message.type === "image" ?
      "Envió una imagen." :
      String(message.text).slice(0, 120);
    const payload = {
      requestId: chat.requestId as string,
      chatId: event.params.chatId,
      messageId: event.params.messageId,
    };

    await notifyUser(
      recipientId,
      "chat_message",
      `Nuevo mensaje de ${senderName}`,
      body,
      payload,
    );
  },
);

export const onServiceRequestUpdated = onDocumentUpdated(
  "service_requests/{requestId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    const status = after.status as string;
    if (!["accepted", "completed", "cancelled"].includes(status)) return;

    const chats = await db
      .collection("chats")
      .where("requestId", "==", event.params.requestId)
      .where("status", "==", "active")
      .get();
    const batch = db.batch();
    for (const chat of chats.docs) {
      if (
        status === "accepted" &&
        chat.data().providerId === after.acceptedProviderId
      ) {
        continue;
      }
      batch.update(chat.ref, {
        status: "read_only",
        updatedAt: new Date(),
      });
    }
    if (status === "accepted") {
      const pendingOffers = await db
        .collection("offers")
        .where("requestId", "==", event.params.requestId)
        .where("status", "==", "pending")
        .get();
      for (const offer of pendingOffers.docs) {
        if (offer.id !== after.acceptedOfferId) {
          batch.update(offer.ref, {status: "rejected"});
        }
      }
    }
    await batch.commit();
  },
);
