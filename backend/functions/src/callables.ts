import {
  FieldValue,
  Transaction,
} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {
  db,
  requireAuthUid,
  requireString,
  requireUser,
} from "./shared.js";

type RequestData = Record<string, unknown>;

// Add specific fieles interface for update profile request
interface UpdateProfileRequest {
  name: unknown;
  phone: unknown;
  photoUrl?: unknown;
  latitude?: unknown;
  longitude?: unknown;
  serviceCategories?: unknown;
}

/**
 * function to validate updateProfile feature and avoid duplicate numbers
 */
export const updateProfile = onCall(
  {enforceAppCheck: false},
  async (request) => {
    // Authentication
    const actorId = requireAuthUid(request.auth?.uid);

    const actor = await requireUser(actorId);

    const data = request.data as UpdateProfileRequest;

    const name = requireString(data.name, "name");
    const phone = requirePhone(data.phone);

    // Read request

    // Validate request

    // Load current user

    // Transaction

    // Return result
  },
);

/**
 * Builds the deterministic chat identifier for a request and provider.
 * @param {string} requestId Service request identifier.
 * @param {string} providerId Provider identifier.
 * @return {string} Deterministic chat identifier.
 */
function chatIdFor(requestId: string, providerId: string) {
  return `${requestId}_${providerId}`;
}

/**
 * Creates a deterministic chat in the current transaction when necessary.
 * @param {object} params Transaction and chat participants.
 */
async function createChatIfMissing(params: {
  transaction: Transaction;
  requestId: string;
  providerId: string;
  clientId: string;
}) {
  const chatId = chatIdFor(params.requestId, params.providerId);
  const chatRef = db.collection("chats").doc(chatId);
  const clientRef = db.collection("users").doc(params.clientId);
  const providerRef = db.collection("users").doc(params.providerId);
  const [chat, client, provider] = await Promise.all([
    params.transaction.get(chatRef),
    params.transaction.get(clientRef),
    params.transaction.get(providerRef),
  ]);
  if (provider.data()?.role !== "provider") {
    throw new HttpsError("permission-denied", "El prestador no es válido.");
  }
  if (!chat.exists) {
    params.transaction.create(chatRef, {
      requestId: params.requestId,
      clientId: params.clientId,
      providerId: params.providerId,
      clientName: client.data()?.name ?? "Cliente",
      providerName: provider.data()?.name ?? "Prestador",
      status: "active",
      lastMessage: "",
      lastMessageAt: null,
      unreadByClient: 0,
      unreadByProvider: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  return {chatId, chatRef};
}

export const ensureChat = onCall({enforceAppCheck: false}, async (request) => {
  const actorId = requireAuthUid(request.auth?.uid);
  const requestId = requireString(request.data?.requestId, "requestId");
  const providerId = requireString(request.data?.providerId, "providerId");
  const requestRef = db.collection("service_requests").doc(requestId);

  const chatId = await db.runTransaction(async (transaction) => {
    const serviceRequest = await transaction.get(requestRef);
    const data = serviceRequest.data() as RequestData | undefined;
    if (!data) {
      throw new HttpsError("not-found", "La solicitud no existe.");
    }
    const clientId = data.clientId as string;
    const status = data.status as string;
    if (
      actorId !== clientId &&
      actorId !== providerId
    ) {
      throw new HttpsError("permission-denied", "No puedes abrir este chat.");
    }
    if (
      status !== "open" &&
      data.acceptedProviderId !== providerId
    ) {
      throw new HttpsError(
        "failed-precondition",
        "La solicitud no admite este chat.",
      );
    }
    const chat = await createChatIfMissing({
      transaction,
      requestId,
      providerId,
      clientId,
    });
    return chat.chatId;
  });
  return {chatId};
});

export const createProposal = onCall(
  {enforceAppCheck: false},
  async (request) => {
    const actorId = requireAuthUid(request.auth?.uid);
    const chatId = requireString(request.data?.chatId, "chatId", 300);
    const proposedPrice = request.data?.proposedPrice;
    const conditions =
      typeof request.data?.conditions === "string" ?
        request.data.conditions.trim() :
        "";
    if (
      typeof proposedPrice !== "number" ||
      !Number.isFinite(proposedPrice) ||
      proposedPrice <= 0
    ) {
      throw new HttpsError("invalid-argument", "El precio no es válido.");
    }
    if (conditions.length > 1000) {
      throw new HttpsError("invalid-argument", "El mensaje es muy largo.");
    }

    let requestId =
      typeof request.data?.requestId === "string" ?
        request.data.requestId :
        undefined;
    let providerId =
      typeof request.data?.providerId === "string" ?
        request.data.providerId :
        undefined;
    if (!requestId || !providerId) {
      const chat = await db.collection("chats").doc(chatId).get();
      requestId = chat.data()?.requestId as string | undefined;
      providerId = chat.data()?.providerId as string | undefined;
    }
    if (
      !requestId ||
      !providerId ||
      chatId !== chatIdFor(requestId, providerId)
    ) {
      throw new HttpsError("invalid-argument", "El chat no es válido.");
    }
    const proposalRequestId = requestId;
    const proposalProviderId = providerId;

    const actor = await requireUser(actorId);
    const offerRef = db.collection("offers").doc();
    const requestRef = db
      .collection("service_requests")
      .doc(proposalRequestId);
    const offersQuery = db
      .collection("offers")
      .where("requestId", "==", proposalRequestId)
      .where("providerId", "==", proposalProviderId);

    await db.runTransaction(async (transaction) => {
      const [serviceRequest, offers] = await Promise.all([
        transaction.get(requestRef),
        transaction.get(offersQuery),
      ]);
      const requestData = serviceRequest.data() as RequestData | undefined;
      if (!requestData) {
        throw new HttpsError("not-found", "La solicitud no existe.");
      }
      if (requestData.status !== "open") {
        throw new HttpsError(
          "failed-precondition",
          "La solicitud ya no está abierta.",
        );
      }
      const clientId = requestData.clientId as string;
      if (actorId !== clientId && actorId !== proposalProviderId) {
        throw new HttpsError(
          "permission-denied",
          "No puedes crear esta propuesta.",
        );
      }
      if (actorId === proposalProviderId && actor.role !== "provider") {
        throw new HttpsError(
          "permission-denied",
          "Solo un prestador puede ofertar.",
        );
      }
      const chat = await createChatIfMissing({
        transaction,
        requestId: proposalRequestId,
        providerId: proposalProviderId,
        clientId,
      });

      let highestRevision = 0;
      let supersedesOfferId: string | null = null;
      for (const offer of offers.docs) {
        const data = offer.data();
        highestRevision = Math.max(
          highestRevision,
          typeof data.revision === "number" ? data.revision : 0,
        );
        if (data.status === "pending") {
          supersedesOfferId ??= offer.id;
          transaction.update(offer.ref, {status: "superseded"});
        }
      }
      transaction.create(offerRef, {
        requestId: proposalRequestId,
        providerId: proposalProviderId,
        proposedPrice,
        message: conditions,
        conditions,
        status: "pending",
        chatId,
        createdById: actorId,
        createdByRole: actor.role,
        revision: highestRevision + 1,
        supersedesOfferId,
        createdAt: FieldValue.serverTimestamp(),
      });
      transaction.update(chat.chatRef, {
        lastMessage: `Nueva propuesta: $${proposedPrice}`,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    return {offerId: offerRef.id, requestId: proposalRequestId};
  },
);

export const acceptOffer = onCall(
  {enforceAppCheck: false},
  async (request) => {
    const actorId = requireAuthUid(request.auth?.uid);
    const offerId = requireString(request.data?.offerId, "offerId");
    const offerRef = db.collection("offers").doc(offerId);

    await db.runTransaction(async (transaction) => {
      const offer = await transaction.get(offerRef);
      const offerData = offer.data();
      if (!offerData) {
        throw new HttpsError("not-found", "La propuesta no existe.");
      }
      const requestId = offerData.requestId as string;
      const requestRef = db.collection("service_requests").doc(requestId);
      const serviceRequest = await transaction.get(requestRef);
      const requestData = serviceRequest.data();
      if (!requestData || requestData.status !== "open") {
        throw new HttpsError(
          "failed-precondition",
          "La solicitud ya no está abierta.",
        );
      }
      if (offerData.status !== "pending") {
        throw new HttpsError(
          "failed-precondition",
          "La propuesta ya no está disponible.",
        );
      }
      const providerId = offerData.providerId as string;
      const clientId = requestData.clientId as string;
      if (actorId !== clientId && actorId !== providerId) {
        throw new HttpsError(
          "permission-denied",
          "No puedes aceptar esta propuesta.",
        );
      }
      if (offerData.createdById === actorId) {
        throw new HttpsError(
          "permission-denied",
          "No puedes aceptar tu propia propuesta.",
        );
      }

      const pendingQuery =
        actorId === clientId ?
          db
            .collection("offers")
            .where("requestId", "==", requestId)
            .where("status", "==", "pending") :
          db
            .collection("offers")
            .where("chatId", "==", offerData.chatId)
            .where("status", "==", "pending");
      const chatsQuery = db
        .collection("chats")
        .where("requestId", "==", requestId);
      const [pendingOffers, chats] = await Promise.all([
        transaction.get(pendingQuery),
        transaction.get(chatsQuery),
      ]);

      transaction.update(offerRef, {status: "accepted"});
      for (const pending of pendingOffers.docs) {
        if (pending.id !== offerId) {
          transaction.update(pending.ref, {status: "rejected"});
        }
      }
      transaction.update(requestRef, {
        status: "accepted",
        acceptedProviderId: providerId,
        acceptedOfferId: offerId,
        price: offerData.proposedPrice,
      });
      for (const chat of chats.docs) {
        if (chat.data().providerId !== providerId) {
          transaction.update(chat.ref, {
            status: "read_only",
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
      }
    });
    return {offerId};
  },
);

export const rejectOffer = onCall(
  {enforceAppCheck: false},
  async (request) => {
    const actorId = requireAuthUid(request.auth?.uid);
    const offerId = requireString(request.data?.offerId, "offerId");
    const offerRef = db.collection("offers").doc(offerId);
    await db.runTransaction(async (transaction) => {
      const offer = await transaction.get(offerRef);
      const data = offer.data();
      if (!data) {
        throw new HttpsError("not-found", "La propuesta no existe.");
      }
      const serviceRequest = await transaction.get(
        db.collection("service_requests").doc(data.requestId as string),
      );
      const clientId = serviceRequest.data()?.clientId;
      if (
        (actorId !== clientId && actorId !== data.providerId) ||
        actorId === data.createdById
      ) {
        throw new HttpsError(
          "permission-denied",
          "No puedes rechazar esta propuesta.",
        );
      }
      if (data.status !== "pending") {
        throw new HttpsError(
          "failed-precondition",
          "La propuesta ya fue procesada.",
        );
      }
      transaction.update(offerRef, {status: "rejected"});
    });
    return {offerId};
  },
);

export const transitionServiceRequest = onCall(
  {enforceAppCheck: false},
  async (request) => {
    const actorId = requireAuthUid(request.auth?.uid);
    const requestId = requireString(request.data?.requestId, "requestId");
    const action = requireString(request.data?.action, "action", 40);
    const reason =
      typeof request.data?.reason === "string" ?
        request.data.reason.trim() :
        "";
    const requestRef = db.collection("service_requests").doc(requestId);
    const actor = await requireUser(actorId);

    await db.runTransaction(async (transaction) => {
      const serviceRequest = await transaction.get(requestRef);
      const data = serviceRequest.data();
      if (!data) {
        throw new HttpsError("not-found", "La solicitud no existe.");
      }
      const isClient = data.clientId === actorId && actor.role === "client";
      const isProvider =
        data.acceptedProviderId === actorId && actor.role === "provider";
      const updates: Record<string, unknown> = {};

      if (action === "cancel" && isClient && data.status === "open") {
        updates.status = "cancelled";
      } else if (
        action === "start" &&
        isProvider &&
        data.status === "accepted"
      ) {
        updates.status = "in_progress";
      } else if (
        action === "request_completion" &&
        isProvider &&
        data.status === "in_progress"
      ) {
        updates.status = "pending_confirmation";
        updates.completionRequestedAt = FieldValue.serverTimestamp();
        updates.completionReturnReason = FieldValue.delete();
      } else if (
        action === "confirm_completion" &&
        isClient &&
        data.status === "pending_confirmation"
      ) {
        updates.status = "completed";
        updates.completedAt = FieldValue.serverTimestamp();
      } else if (
        action === "return_to_progress" &&
        isClient &&
        data.status === "pending_confirmation"
      ) {
        if (reason.length < 10 || reason.length > 500) {
          throw new HttpsError(
            "invalid-argument",
            "El motivo debe tener entre 10 y 500 caracteres.",
          );
        }
        updates.status = "in_progress";
        updates.completionReturnedAt = FieldValue.serverTimestamp();
        updates.completionReturnReason = reason;
      } else {
        throw new HttpsError(
          "failed-precondition",
          "La transición no está permitida.",
        );
      }
      transaction.update(requestRef, updates);
    });
    return {requestId, action};
  },
);
