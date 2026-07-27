import {FieldValue, GeoPoint, WriteBatch} from "firebase-admin/firestore";

import {db} from "./shared.js";

/**
 * Produces the public approximate location used by open listings.
 * @param {unknown} location Exact Firestore location.
 * @return {GeoPoint} Rounded public location.
 */
function roundedLocation(location: unknown) {
  if (!(location instanceof GeoPoint)) return new GeoPoint(0, 0);
  return new GeoPoint(
    Math.round(location.latitude * 100) / 100,
    Math.round(location.longitude * 100) / 100,
  );
}

/**
 * Commits migration writes below Firestore's per-batch limit.
 * @param {Function[]} operations Pending writes.
 */
async function commitInChunks(
  operations: Array<(batch: WriteBatch) => void>,
) {
  for (let offset = 0; offset < operations.length; offset += 400) {
    const batch = db.batch();
    for (const operation of operations.slice(offset, offset + 400)) {
      operation(batch);
    }
    await batch.commit();
  }
}

/** Prints a dry-run summary and writes only when --apply is explicit. */
async function main() {
  const apply = process.argv.includes("--apply");
  const [users, requests] = await Promise.all([
    db
      .collection("users")
      .where("role", "==", "provider")
      .where("profileComplete", "==", true)
      .get(),
    db.collection("service_requests").get(),
  ]);
  const operations: Array<(batch: WriteBatch) => void> = [];

  for (const user of users.docs) {
    const data = user.data();
    if (typeof data.phone !== "string" || data.phone.trim().length === 0) {
      continue;
    }
    operations.push((batch) => {
      batch.set(db.collection("provider_public_profiles").doc(user.id), {
        name: data.name ?? "",
        phone: data.phone,
        photoUrl: data.photoUrl ?? null,
        serviceCategories: data.serviceCategories ?? [],
        rating: data.rating ?? 0,
        ratingCount: data.ratingCount ?? 0,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  for (const serviceRequest of requests.docs) {
    const data = serviceRequest.data();
    const isOpen = data.status === "open";
    operations.push((batch) => {
      batch.set(
        db.collection("open_request_listings").doc(serviceRequest.id),
        {
          clientId: data.clientId,
          category: data.category,
          description: data.description,
          location: isOpen ? roundedLocation(data.location) : data.location,
          address: isOpen ? "Ubicación aproximada" : data.address,
          scheduledAt: data.scheduledAt,
          status: data.status,
          acceptedProviderId: data.acceptedProviderId ?? null,
          acceptedOfferId: data.acceptedOfferId ?? null,
          price: data.price ?? null,
          createdAt: data.createdAt,
          completionRequestedAt: data.completionRequestedAt ?? null,
          completionReturnedAt: data.completionReturnedAt ?? null,
          completionReturnReason: data.completionReturnReason ?? null,
          completedAt: data.completedAt ?? null,
          updatedAt: FieldValue.serverTimestamp(),
        },
      );
    });
  }

  console.log(JSON.stringify({
    mode: apply ? "apply" : "dry-run",
    providerProfiles: users.size,
    requestListings: requests.size,
    writes: operations.length,
  }));
  if (apply) await commitInChunks(operations);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
