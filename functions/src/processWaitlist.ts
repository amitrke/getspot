import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Processes the waitlist for a given event, promoting the next eligible user if a spot is available.
 * This function is designed to be called within an existing Firestore transaction.
 * @param {admin.firestore.Firestore} db Firestore database instance
 * @param {admin.firestore.Transaction} transaction Active transaction
 * @param {string} eventId Event identifier
 * @return {Promise<void>} Resolves when processing ends
 */
export const processWaitlist = async (
  db: admin.firestore.Firestore,
  transaction: admin.firestore.Transaction,
  eventId: string,
) => {
  logger.info(`Processing waitlist for event ${eventId}.`);

  const eventRef = db.collection("events").doc(eventId);
  const eventDoc = await transaction.get(eventRef);

  if (!eventDoc.exists) {
    logger.warn(`Event ${eventId} not found during waitlist processing.`);
    return; // Event doesn't exist, nothing to do.
  }

  const eventData = eventDoc.data();
  const groupId = eventData?.groupId;

  if (!groupId) {
    logger.error(`Event ${eventId} is missing groupId.`);
    return; // Cannot process without group ID.
  }

  // Find the next waitlisted user
  const waitlistQuery = eventRef.collection("participants")
    .where("status", "==", "waitlisted")
    .orderBy("registeredAt", "asc")
    .limit(1);

  const waitlistSnap = await transaction.get(waitlistQuery);

  if (waitlistSnap.empty) {
    logger.info(`No waitlisted users for event ${eventId}.`);
    return; // No one on waitlist.
  }

  const nextWaitlistedDoc = waitlistSnap.docs[0];
  const nextWaitlistedUserId = nextWaitlistedDoc.id;

  const memberRef = db.collection("groups").doc(groupId).collection("members").doc(nextWaitlistedUserId);
  const memberDoc = await transaction.get(memberRef);

  if (!memberDoc.exists) {
    logger.warn(`Waitlisted user ${nextWaitlistedUserId} member doc not found for event ${eventId}. Skipping.`);
    // Optionally, mark participant as denied due to missing member doc
    transaction.update(nextWaitlistedDoc.ref, {status: "denied", denialReason: "Member profile missing"});
    return; // Cannot process if member doc is missing.
  }

  // Since the fee was already collected at registration, we can directly promote the user.
  transaction.update(nextWaitlistedDoc.ref, {status: "confirmed"});
  transaction.update(eventRef, {
    confirmedCount: admin.firestore.FieldValue.increment(1),
    waitlistCount: admin.firestore.FieldValue.increment(-1),
  });

  // No fee deduction or transaction log is needed here as it was handled during the initial registration.
  logger.info(`User ${nextWaitlistedUserId} promoted to confirmed for event ${eventId}. Fee was collected at registration.`);
};
