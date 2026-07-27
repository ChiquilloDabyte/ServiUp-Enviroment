import {FieldValue, GeoPoint} from "firebase-admin/firestore";
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";

import {db, notifyUser} from "./shared.js";

/**
 * Reduces exact coordinates to roughly one-kilometer precision.
 * @param {unknown} location Exact Firestore location.
 * @return {GeoPoint} Rounded public location.
 */
function roundedLocation(location: unknown) {
  if (!(location instanceof GeoPoint)) return new GeoPoint(0, 0);
  const latitude = Math.round(location.latitude * 100) / 100;
  const longitude = Math.round(location.longitude * 100) / 100;
  return new GeoPoint(latitude, longitude);
}

export const onUserWritten = onDocumentWritten(
  "users/{userId}",
  async (event) => {
    const userId = event.params.userId;
    const user = event.data?.after.data();
    const publicRef = db.collection("provider_public_profiles").doc(userId);
    if (
      !user ||
      user.role !== "provider" ||
      user.profileComplete !== true ||
      typeof user.phone !== "string" ||
      user.phone.trim().length === 0
    ) {
      await publicRef.delete();
      return;
    }
    await publicRef.set({
      name: user.name ?? "",
      phone: user.phone,
      photoUrl: user.photoUrl ?? null,
      serviceCategories: user.serviceCategories ?? [],
      rating: user.rating ?? 0,
      ratingCount: user.ratingCount ?? 0,
      updatedAt: FieldValue.serverTimestamp(),
    });
  },
);

export const onServiceRequestWritten = onDocumentWritten(
  "service_requests/{requestId}",
  async (event) => {
    const requestId = event.params.requestId;
    const serviceRequest = event.data?.after.data();
    const listingRef = db.collection("open_request_listings").doc(requestId);
    if (!serviceRequest) {
      await listingRef.delete();
      return;
    }
    const isOpen = serviceRequest.status === "open";
    await listingRef.set({
      clientId: serviceRequest.clientId,
      category: serviceRequest.category,
      description: serviceRequest.description,
      location:
        isOpen ?
          roundedLocation(serviceRequest.location) :
          serviceRequest.location,
      address: isOpen ? "Ubicación aproximada" : serviceRequest.address,
      scheduledAt: serviceRequest.scheduledAt,
      status: serviceRequest.status,
      acceptedProviderId: serviceRequest.acceptedProviderId ?? null,
      acceptedOfferId: serviceRequest.acceptedOfferId ?? null,
      price: serviceRequest.price ?? null,
      createdAt: serviceRequest.createdAt,
      completionRequestedAt:
        serviceRequest.completionRequestedAt ?? null,
      completionReturnedAt:
        serviceRequest.completionReturnedAt ?? null,
      completionReturnReason:
        serviceRequest.completionReturnReason ?? null,
      completedAt: serviceRequest.completedAt ?? null,
      updatedAt: FieldValue.serverTimestamp(),
    });
  },
);

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
    await notifyUser({
      id: `offer_created_${event.id}`,
      userId: recipientId,
      type: "offer_created",
      title: "Nueva propuesta",
      body: `Precio propuesto: $${offer.proposedPrice}`,
      payload: {
        requestId: offer.requestId as string,
        offerId: event.params.offerId,
        chatId: (offer.chatId as string | undefined) ?? "",
      },
    });
  },
);

export const onOfferAccepted = onDocumentUpdated(
  "offers/{offerId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === after.status || after.status !== "accepted") return;
    const recipientId = after.createdById as string | undefined;
    if (!recipientId) return;
    await notifyUser({
      id: `offer_accepted_${event.id}`,
      userId: recipientId,
      type: "offer_accepted",
      title: "Propuesta aceptada",
      body: "La contraparte aceptó tu propuesta.",
      payload: {
        requestId: after.requestId as string,
        offerId: event.params.offerId,
        chatId: (after.chatId as string | undefined) ?? "",
      },
    });
  },
);

export const onChatMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const chatDoc = await db.collection("chats").doc(event.params.chatId).get();
    const chat = chatDoc.data();
    if (!chat) return;
    const senderId = message.senderId as string;
    const recipientId =
      senderId === chat.clientId ?
        chat.providerId as string :
        chat.clientId as string;
    const senderName =
      senderId === chat.clientId ?
        (chat.clientName as string || "Cliente") :
        (chat.providerName as string || "Prestador");
    const body =
      message.type === "image" ?
        "Envió una imagen." :
        String(message.text).slice(0, 120);
    await notifyUser({
      id: `chat_message_${event.id}`,
      userId: recipientId,
      type: "chat_message",
      title: `Nuevo mensaje de ${senderName}`,
      body,
      payload: {
        requestId: chat.requestId as string,
        chatId: event.params.chatId,
        messageId: event.params.messageId,
      },
    });
  },
);

export const onServiceRequestUpdated = onDocumentUpdated(
  "service_requests/{requestId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    const requestId = event.params.requestId;
    const payload = {requestId};

    if (after.status === "pending_confirmation") {
      await notifyUser({
        id: `completion_requested_${event.id}`,
        userId: after.clientId as string,
        type: "completion_requested",
        title: "Confirma el servicio",
        body: "El prestador indicó que terminó el trabajo.",
        payload,
      });
    } else if (
      before.status === "pending_confirmation" &&
      after.status === "in_progress"
    ) {
      await notifyUser({
        id: `completion_returned_${event.id}`,
        userId: after.acceptedProviderId as string,
        type: "completion_returned",
        title: "El servicio requiere ajustes",
        body: String(after.completionReturnReason).slice(0, 120),
        payload,
      });
    } else if (after.status === "completed") {
      await notifyUser({
        id: `service_completed_${event.id}`,
        userId: after.acceptedProviderId as string,
        type: "service_completed",
        title: "Servicio completado",
        body: "El cliente confirmó la finalización.",
        payload,
      });
    }

    if (!["completed", "cancelled"].includes(after.status as string)) return;
    const chats = await db
      .collection("chats")
      .where("requestId", "==", requestId)
      .where("status", "==", "active")
      .get();
    const batch = db.batch();
    for (const chat of chats.docs) {
      batch.update(chat.ref, {
        status: "read_only",
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  },
);

export const onReviewCreated = onDocumentCreated(
  "reviews/{reviewId}",
  async (event) => {
    const review = event.data?.data();
    if (!review) return;
    const providerId = review.providerId as string;
    const markerRef = db
      .collection("_review_events")
      .doc(event.params.reviewId);
    const userRef = db.collection("users").doc(providerId);
    await db.runTransaction(async (transaction) => {
      const [marker, user] = await Promise.all([
        transaction.get(markerRef),
        transaction.get(userRef),
      ]);
      if (marker.exists || !user.exists) return;
      const currentRating = Number(user.data()?.rating ?? 0);
      const currentCount = Number(user.data()?.ratingCount ?? 0);
      const rating = Number(review.rating);
      transaction.update(userRef, {
        rating:
          (currentRating * currentCount + rating) /
          (currentCount + 1),
        ratingCount: currentCount + 1,
      });
      transaction.create(markerRef, {
        processedAt: FieldValue.serverTimestamp(),
      });
    });
  },
);
