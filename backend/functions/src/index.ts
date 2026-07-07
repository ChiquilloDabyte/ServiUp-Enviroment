import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {initializeApp} from "firebase-admin/app";
import * as logger from "firebase-functions/logger";

initializeApp();
setGlobalOptions({maxInstances: 10});

const db = getFirestore();

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

  await getMessaging().send({
    token,
    notification: {title, body},
    data: payload,
  });
}

async function createNotification(
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
    if (!clientId) return;

    const title = "Nueva oferta recibida";
    const body = `Precio propuesto: $${offer.proposedPrice}`;
    const payload = {
      requestId: offer.requestId as string,
      offerId: event.params.offerId,
    };

    await createNotification(clientId, "offer_created", title, body, payload);
    await sendPush(clientId, title, body, payload);
  },
);

export const onOfferAccepted = onDocumentUpdated(
  "offers/{offerId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "accepted") return;

    const providerId = after.providerId as string;
    const title = "Oferta aceptada";
    const body = "El cliente aceptó tu oferta.";
    const payload = {
      requestId: after.requestId as string,
      offerId: event.params.offerId,
    };

    await createNotification(providerId, "offer_accepted", title, body, payload);
    await sendPush(providerId, title, body, payload);
  },
);
