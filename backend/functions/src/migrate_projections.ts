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
  const backupConfirmed = process.argv.includes("--backup-confirmed");
  if (apply && !backupConfirmed) {
    throw new Error(
      "Exporta Firestore y vuelve a ejecutar con --apply --backup-confirmed.",
    );
  }

  const [users, publicProfiles, requests] = await Promise.all([
    db.collection("users").get(),
    db.collection("provider_public_profiles").get(),
    db.collection("service_requests").get(),
  ]);
  const operations: Array<(batch: WriteBatch) => void> = [];
  const eligibleProviderIds = new Set<string>();
  let providerProfilesUpserted = 0;
  let providerProfilesDeleted = 0;
  let clientPhonesCleared = 0;

  for (const user of users.docs) {
    const data = user.data();
    if (
      data.role === "client" &&
      typeof data.phone === "string" &&
      data.phone.trim().length > 0
    ) {
      clientPhonesCleared++;
      operations.push((batch) => {
        batch.update(user.ref, {
          phone: "",
          phoneVerifiedAt: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });
      continue;
    }
    if (
      data.role !== "provider" ||
      data.profileComplete !== true ||
      data.phoneVerifiedAt == null ||
      typeof data.phone !== "string" ||
      data.phone.trim().length === 0
    ) continue;

    eligibleProviderIds.add(user.id);
    providerProfilesUpserted++;
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

  for (const profile of publicProfiles.docs) {
    if (eligibleProviderIds.has(profile.id)) continue;
    providerProfilesDeleted++;
    operations.push((batch) => batch.delete(profile.ref));
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
    users: users.size,
    providerProfilesUpserted,
    providerProfilesDeleted,
    clientPhonesCleared,
    requestListings: requests.size,
    writes: operations.length,
  }));
  if (apply) await commitInChunks(operations);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
