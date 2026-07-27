/* eslint-disable @typescript-eslint/no-var-requires */
const {
  after,
  before,
  test,
} = require("node:test");
const assert = require("node:assert/strict");
const {
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

const projectId = "serviup";
let testEnv;
let db;
let acceptOffer;
let transitionServiceRequest;
let notifyUser;

/**
 * Builds the minimum v2 callable request used by direct handler tests.
 * @param {string} uid Authenticated test user.
 * @param {object} data Callable payload.
 * @return {object} Callable request.
 */
function callableRequest(uid, data) {
  return {
    data,
    auth: {uid, token: {}},
    app: undefined,
    instanceIdToken: undefined,
    rawRequest: {},
  };
}

before(async () => {
  process.env.GCLOUD_PROJECT = projectId;
  testEnv = await initializeTestEnvironment({projectId});
  ({db, notifyUser} = require("../lib/shared.js"));
  ({acceptOffer, transitionServiceRequest} = require("../lib/callables.js"));
});

after(async () => {
  await testEnv.cleanup();
});

test(
  "dos aceptaciones simultáneas dejan una sola propuesta aceptada",
  async () => {
    const suffix = Date.now().toString();
    const requestId = `concurrent-${suffix}`;
    const clientId = `client-${suffix}`;
    const providerA = `provider-a-${suffix}`;
    const providerB = `provider-b-${suffix}`;
    const requestRef = db.collection("service_requests").doc(requestId);
    const offerA = db.collection("offers").doc(`offer-a-${suffix}`);
    const offerB = db.collection("offers").doc(`offer-b-${suffix}`);
    await Promise.all([
      db.collection("users").doc(clientId).set({role: "client"}),
      db.collection("users").doc(providerA).set({role: "provider"}),
      db.collection("users").doc(providerB).set({role: "provider"}),
      requestRef.set({clientId, status: "open"}),
      offerA.set({
        requestId,
        providerId: providerA,
        proposedPrice: 100,
        status: "pending",
        chatId: `${requestId}_${providerA}`,
        createdById: providerA,
      }),
      offerB.set({
        requestId,
        providerId: providerB,
        proposedPrice: 120,
        status: "pending",
        chatId: `${requestId}_${providerB}`,
        createdById: providerB,
      }),
      db.collection("chats").doc(`${requestId}_${providerA}`).set({
        requestId,
        clientId,
        providerId: providerA,
        status: "active",
      }),
      db.collection("chats").doc(`${requestId}_${providerB}`).set({
        requestId,
        clientId,
        providerId: providerB,
        status: "active",
      }),
    ]);

    const results = await Promise.allSettled([
      acceptOffer.run(callableRequest(clientId, {offerId: offerA.id})),
      acceptOffer.run(callableRequest(clientId, {offerId: offerB.id})),
    ]);
    assert.equal(
      results.filter((result) => result.status === "fulfilled").length,
      1,
    );
    const [requestSnapshot, firstOffer, secondOffer] = await Promise.all([
      requestRef.get(),
      offerA.get(),
      offerB.get(),
    ]);
    assert.equal(requestSnapshot.data().status, "accepted");
    assert.equal(
      [firstOffer.data().status, secondOffer.data().status]
        .filter((status) => status === "accepted").length,
      1,
    );
  },
);

test("el ciclo permite devolver y confirmar el servicio", async () => {
  const suffix = Date.now().toString();
  const requestId = `lifecycle-${suffix}`;
  const clientId = `client-life-${suffix}`;
  const providerId = `provider-life-${suffix}`;
  const requestRef = db.collection("service_requests").doc(requestId);
  await Promise.all([
    db.collection("users").doc(clientId).set({role: "client"}),
    db.collection("users").doc(providerId).set({role: "provider"}),
    requestRef.set({
      clientId,
      acceptedProviderId: providerId,
      status: "accepted",
    }),
  ]);

  await transitionServiceRequest.run(
    callableRequest(providerId, {requestId, action: "start"}),
  );
  await transitionServiceRequest.run(
    callableRequest(providerId, {
      requestId,
      action: "request_completion",
    }),
  );
  await transitionServiceRequest.run(
    callableRequest(clientId, {
      requestId,
      action: "return_to_progress",
      reason: "Todavía falta ajustar la instalación.",
    }),
  );
  await transitionServiceRequest.run(
    callableRequest(providerId, {
      requestId,
      action: "request_completion",
    }),
  );
  await transitionServiceRequest.run(
    callableRequest(clientId, {
      requestId,
      action: "confirm_completion",
    }),
  );

  const completed = await requestRef.get();
  assert.equal(completed.data().status, "completed");
  assert.ok(completed.data().completedAt);
});

test("una notificación con el mismo id solo se persiste una vez", async () => {
  const suffix = Date.now().toString();
  const userId = `notification-user-${suffix}`;
  const id = `notification-${suffix}`;
  await db.collection("users").doc(userId).set({role: "client"});
  const notification = {
    id,
    userId,
    type: "test",
    title: "Prueba",
    body: "Notificación idempotente",
    payload: {requestId: "request"},
  };
  await Promise.all([notifyUser(notification), notifyUser(notification)]);
  const snapshot = await db.collection("notifications").doc(id).get();
  assert.equal(snapshot.exists, true);
});
