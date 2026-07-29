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
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  collection,
  deleteField,
  GeoPoint,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
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
      setDoc(doc(db, "users/client-1"), {
        email: "client@example.com",
        role: "client",
        name: "Cliente",
        phone: "3000000000",
        serviceCategories: [],
        rating: 0,
        ratingCount: 0,
        profileComplete: true,
      }),
      setDoc(doc(db, "users/provider-1"), {
        email: "provider@example.com",
        role: "provider",
        name: "Prestador",
        phone: "3111111111",
        serviceCategories: ["Plomería"],
        rating: 0,
        ratingCount: 0,
        profileComplete: true,
      }),
      setDoc(doc(db, "users/outsider-1"), {
        role: "client",
        rating: 0,
        ratingCount: 0,
      }),
      setDoc(doc(db, "users/provider-legacy"), {
        email: "legacy@example.com",
        role: "provider",
        name: "Prestador antiguo",
        phone: "3222222222",
        serviceCategories: ["Plomería"],
        profileComplete: true,
      }),
      setDoc(doc(db, `service_requests/${requestId}`), {
        clientId: "client-1",
        category: "Plomería",
        description: "Reparar una fuga de agua",
        location: new GeoPoint(4.71, -74.07),
        address: "Dirección exacta",
        scheduledAt: new Date(),
        status: "open",
        acceptedProviderId: null,
        acceptedOfferId: null,
        price: null,
        createdAt: new Date(),
      }),
      setDoc(doc(db, `open_request_listings/${requestId}`), {
        clientId: "client-1",
        category: "Plomería",
        description: "Reparar una fuga de agua",
        location: new GeoPoint(4.71, -74.07),
        address: "Ubicación aproximada",
        scheduledAt: new Date(),
        status: "open",
        acceptedProviderId: null,
        createdAt: new Date(),
      }),
      setDoc(doc(db, "provider_public_profiles/provider-1"), {
        name: "Prestador",
        phone: "3111111111",
        serviceCategories: ["Plomería"],
        rating: 0,
        ratingCount: 0,
        updatedAt: new Date(),
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

describe("perfiles privados y proyecciones", () => {
  test("solo el propietario lee users", async () => {
    const owner = testEnv.authenticatedContext("client-1").firestore();
    const provider = testEnv.authenticatedContext("provider-1").firestore();
    await assertSucceeds(getDoc(doc(owner, "users/client-1")));
    await assertFails(getDoc(doc(provider, "users/client-1")));
  });

  test("el propietario no cambia rol ni calificación", async () => {
    const db = testEnv.authenticatedContext("provider-1").firestore();
    await assertFails(updateDoc(doc(db, "users/provider-1"), {role: "client"}));
    await assertFails(updateDoc(doc(db, "users/provider-1"), {rating: 5}));
    await assertSucceeds(
      updateDoc(doc(db, "users/provider-1"), {
        name: "Prestador actualizado",
      }),
    );
  });

  test("solo un prestador sincroniza el teléfono de su token", async () => {
    const verifiedProvider = testEnv.authenticatedContext("provider-1", {
      phone_number: "+573111111111",
    }).firestore();
    const unverifiedProvider =
      testEnv.authenticatedContext("provider-1").firestore();
    const client = testEnv.authenticatedContext("client-1", {
      phone_number: "+573001111111",
    }).firestore();

    await assertSucceeds(
      updateDoc(doc(verifiedProvider, "users/provider-1"), {
        phone: "+573111111111",
        phoneVerifiedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(unverifiedProvider, "users/provider-1"), {
        phone: "+573222222222",
        phoneVerifiedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(client, "users/client-1"), {
        phone: "+573001111111",
        phoneVerifiedAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test("un perfil se completa sin exigir teléfono", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users/provider-incomplete"), {
        email: "incomplete@example.com",
        role: "provider",
        name: "",
        phone: "",
        serviceCategories: [],
        rating: 0,
        ratingCount: 0,
        profileComplete: false,
      });
    });
    const db =
      testEnv.authenticatedContext("provider-incomplete").firestore();
    await assertSucceeds(
      updateDoc(doc(db, "users/provider-incomplete"), {
        name: "Prestador nuevo",
        serviceCategories: ["Plomería"],
        profileComplete: true,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  test("un perfil antiguo puede actualizar solo su token FCM", async () => {
    const db = testEnv.authenticatedContext("provider-legacy").firestore();
    await assertSucceeds(
      setDoc(
        doc(db, "users/provider-legacy"),
        {fcmToken: "token-actualizado"},
        {merge: true},
      ),
    );
  });

  test("el propietario elimina su token FCM al cerrar sesión", async () => {
    const db = testEnv.authenticatedContext("provider-legacy").firestore();
    const profile = doc(db, "users/provider-legacy");
    await assertSucceeds(
      setDoc(profile, {fcmToken: "token-activo"}, {merge: true}),
    );
    await assertSucceeds(updateDoc(profile, {fcmToken: deleteField()}));
  });

  test("un autenticado lee la proyección pero no la escribe", async () => {
    const db = testEnv.authenticatedContext("client-1").firestore();
    const profile = doc(db, "provider_public_profiles/provider-1");
    await assertSucceeds(getDoc(profile));
    await assertFails(updateDoc(profile, {rating: 5}));
  });
});

describe("solicitudes privadas y listados", () => {
  test("un prestador solo ve el listado aproximado", async () => {
    const db = testEnv.authenticatedContext("provider-1").firestore();
    await assertSucceeds(
      getDoc(doc(db, `open_request_listings/${requestId}`)),
    );
    await assertFails(getDoc(doc(db, `service_requests/${requestId}`)));
  });

  test("un prestador consulta los listados abiertos por fecha", async () => {
    const db = testEnv.authenticatedContext("provider-legacy").firestore();
    const listings = query(
      collection(db, "open_request_listings"),
      where("status", "==", "open"),
      orderBy("createdAt", "desc"),
    );
    await assertSucceeds(getDocs(listings));
  });

  test("solo un cliente crea solicitudes", async () => {
    const payload = {
      clientId: "client-1",
      category: "Limpieza",
      description: "Necesito una limpieza completa",
      location: new GeoPoint(4.7, -74.1),
      address: "Calle 1",
      scheduledAt: new Date(),
      status: "open",
      acceptedProviderId: null,
      acceptedOfferId: null,
      price: null,
      createdAt: serverTimestamp(),
    };
    const client = testEnv.authenticatedContext("client-1", {
      email_verified: true,
    }).firestore();
    const unverifiedClient =
      testEnv.authenticatedContext("client-1").firestore();
    const provider = testEnv.authenticatedContext("provider-1").firestore();
    await assertSucceeds(
      setDoc(doc(client, "service_requests/request-2"), payload),
    );
    await assertFails(
      setDoc(doc(provider, "service_requests/request-3"), {
        ...payload,
        clientId: "provider-1",
      }),
    );
    await assertFails(
      setDoc(doc(unverifiedClient, "service_requests/request-4"), payload),
    );
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users/client-incomplete"), {
        role: "client",
        name: "",
        profileComplete: true,
      });
    });
    const incompleteClient = testEnv.authenticatedContext(
      "client-incomplete",
      {email_verified: true},
    ).firestore();
    await assertFails(
      setDoc(
        doc(incompleteClient, "service_requests/request-5"),
        {...payload, clientId: "client-incomplete"},
      ),
    );
  });

  test("las transiciones directas están bloqueadas", async () => {
    const db = testEnv.authenticatedContext("client-1").firestore();
    await assertFails(
      updateDoc(doc(db, `service_requests/${requestId}`), {
        status: "cancelled",
      }),
    );
  });
});

describe("negociación y chat", () => {
  test("ofertas y chats solo se crean desde Functions", async () => {
    const db = testEnv.authenticatedContext("provider-1").firestore();
    await assertFails(
      setDoc(doc(db, "offers/offer-1"), {
        requestId,
        providerId: "provider-1",
        status: "pending",
      }),
    );
    await assertFails(
      setDoc(doc(db, "chats/new-chat"), {
        requestId,
        clientId: "client-1",
        providerId: "provider-1",
      }),
    );
  });

  test("los participantes escriben mensajes y terceros no", async () => {
    const client = testEnv.authenticatedContext("client-1").firestore();
    const outsider = testEnv.authenticatedContext("outsider-1").firestore();
    const message = {
      senderId: "client-1",
      type: "text",
      text: "Necesito confirmar el horario.",
      imageUrl: null,
      createdAt: serverTimestamp(),
    };
    await assertSucceeds(
      setDoc(doc(client, `chats/${chatId}/messages/message-1`), message),
    );
    await assertFails(
      setDoc(doc(outsider, `chats/${chatId}/messages/message-2`), {
        ...message,
        senderId: "outsider-1",
      }),
    );
  });
});

describe("calificaciones reservadas", () => {
  test("solo el cliente del servicio completado crea una reseña", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await updateDoc(
        doc(context.firestore(), `service_requests/${requestId}`),
        {
          status: "completed",
          acceptedProviderId: "provider-1",
        },
      );
    });
    const client = testEnv.authenticatedContext("client-1").firestore();
    const provider = testEnv.authenticatedContext("provider-1").firestore();
    const outsider = testEnv.authenticatedContext("outsider-1").firestore();
    const review = {
      requestId,
      clientId: "client-1",
      providerId: "provider-1",
      rating: 5,
      comment: "Excelente servicio",
      createdAt: serverTimestamp(),
    };
    await assertSucceeds(getDoc(doc(client, `reviews/${requestId}`)));
    await assertFails(getDoc(doc(outsider, `reviews/${requestId}`)));
    await assertSucceeds(setDoc(doc(client, `reviews/${requestId}`), review));
    await assertFails(
      setDoc(doc(provider, "reviews/other-request"), {
        ...review,
        requestId: "other-request",
        clientId: "provider-1",
      }),
    );
  });
});
