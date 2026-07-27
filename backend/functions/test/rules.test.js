/* eslint-disable @typescript-eslint/no-var-requires */
const fs = require("node:fs");
const path = require("node:path");
const {
  after,
  before,
  beforeEach,
  describe,
  test,
} = require("node:test");
const assert = require("node:assert/strict");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require("firebase/firestore");

const projectId = "serviup";
const requestId = "request-1";
const chatId = `${requestId}_provider-1`;
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../firestore.rules"),
        "utf8",
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, "users/client-1"), {role: "client"}),
      setDoc(doc(db, "users/provider-1"), {role: "provider"}),
      setDoc(doc(db, "users/outsider-1"), {role: "client"}),
      setDoc(doc(db, `service_requests/${requestId}`), {
        clientId: "client-1",
        status: "open",
      }),
      setDoc(doc(db, `chats/${chatId}`), {
        requestId,
        clientId: "client-1",
        providerId: "provider-1",
        status: "active",
        unreadByClient: 0,
        unreadByProvider: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    ]);
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("reglas privadas de chat", () => {
  test("permite crear el chat de la primera oferta", async () => {
    const newChatId = `${requestId}_provider-2`;
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users/provider-2"), {
        role: "provider",
      });
    });

    const db = testEnv.authenticatedContext("provider-2").firestore();
    const newChat = doc(db, `chats/${newChatId}`);
    await assertSucceeds(getDoc(newChat));
    await assertSucceeds(
      setDoc(newChat, {
        requestId,
        clientId: "client-1",
        providerId: "provider-2",
        clientName: "Cliente",
        providerName: "Prestador",
        status: "active",
        lastMessage: "",
        lastMessageAt: null,
        unreadByClient: 0,
        unreadByProvider: 0,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, "offers/first-offer"), {
        requestId,
        providerId: "provider-2",
        proposedPrice: 90000,
        message: "Primera oferta",
        conditions: "Primera oferta",
        status: "pending",
        chatId: newChatId,
        createdById: "provider-2",
        createdByRole: "provider",
        revision: 1,
        supersedesOfferId: null,
        createdAt: serverTimestamp(),
      }),
    );
  });

  test("los participantes leen y escriben mensajes", async () => {
    const db = testEnv.authenticatedContext("client-1").firestore();
    await assertSucceeds(getDoc(doc(db, `chats/${chatId}`)));
    await assertSucceeds(
      setDoc(doc(db, `chats/${chatId}/messages/message-1`), {
        senderId: "client-1",
        type: "text",
        text: "Necesito confirmar el horario.",
        imageUrl: null,
        createdAt: serverTimestamp(),
      }),
    );
  });

  test("un tercero no puede leer ni escribir", async () => {
    const db = testEnv.authenticatedContext("outsider-1").firestore();
    await assertFails(getDoc(doc(db, `chats/${chatId}`)));
    await assertFails(
      setDoc(doc(db, `chats/${chatId}/messages/message-2`), {
        senderId: "outsider-1",
        type: "text",
        text: "Mensaje no autorizado.",
        imageUrl: null,
        createdAt: serverTimestamp(),
      }),
    );
  });

  test("rechaza mensajes que superan el límite", async () => {
    const db = testEnv.authenticatedContext("provider-1").firestore();
    await assertFails(
      setDoc(doc(db, `chats/${chatId}/messages/message-3`), {
        senderId: "provider-1",
        type: "text",
        text: "x".repeat(2001),
        imageUrl: null,
        createdAt: serverTimestamp(),
      }),
    );
  });
});

describe("reglas de negociación", () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, "offers/offer-1"), {
        requestId,
        providerId: "provider-1",
        proposedPrice: 120000,
        message: "Incluye materiales.",
        conditions: "Incluye materiales.",
        status: "pending",
        chatId,
        createdById: "provider-1",
        createdByRole: "provider",
        revision: 1,
        supersedesOfferId: null,
        createdAt: new Date(),
      });
    });
  });

  test("el creador no acepta su propia propuesta", async () => {
    const db = testEnv.authenticatedContext("provider-1").firestore();
    await assertFails(
      updateDoc(doc(db, "offers/offer-1"), {status: "accepted"}),
    );
  });

  test("la contraparte acepta oferta y solicitud atómicamente", async () => {
    const db = testEnv.authenticatedContext("client-1").firestore();
    await assertSucceeds(
      runTransaction(db, async (transaction) => {
        transaction.update(doc(db, "offers/offer-1"), {
          status: "accepted",
        });
        transaction.update(doc(db, `service_requests/${requestId}`), {
          status: "accepted",
          acceptedProviderId: "provider-1",
          acceptedOfferId: "offer-1",
          price: 120000,
        });
      }),
    );
    const request = await getDoc(doc(db, `service_requests/${requestId}`));
    assert.equal(request.data().acceptedOfferId, "offer-1");
  });

  test("el proveedor puede aceptar una contraoferta del cliente", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "offers/client-offer"), {
        requestId,
        providerId: "provider-1",
        proposedPrice: 100000,
        message: "Contraoferta",
        conditions: "Contraoferta",
        status: "pending",
        chatId,
        createdById: "client-1",
        createdByRole: "client",
        revision: 2,
        supersedesOfferId: "offer-1",
        createdAt: new Date(),
      });
    });

    const db = testEnv.authenticatedContext("provider-1").firestore();
    await assertSucceeds(
      runTransaction(db, async (transaction) => {
        transaction.update(doc(db, "offers/client-offer"), {
          status: "accepted",
        });
        transaction.update(doc(db, `service_requests/${requestId}`), {
          status: "accepted",
          acceptedProviderId: "provider-1",
          acceptedOfferId: "client-offer",
          price: 100000,
        });
      }),
    );
  });
});
