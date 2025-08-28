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
  const fee = eventData?.fee ?? 0;
  const groupId = eventData?.groupId;
  const negativeBalanceLimit = eventData?.negativeBalanceLimit ?? 0; // Assuming this is stored on event or group

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

  const memberData = memberDoc.data();
  const walletBalance = memberData?.walletBalance ?? 0;

  // Check if user has sufficient funds
  if (walletBalance + negativeBalanceLimit >= fee) {
    // Promote user
    transaction.update(nextWaitlistedDoc.ref, {status: "confirmed"});
    transaction.update(eventRef, {
      confirmedCount: admin.firestore.FieldValue.increment(1),
      waitlistCount: admin.firestore.FieldValue.increment(-1),
    });
    // Deduct fee
    transaction.update(memberRef, {walletBalance: admin.firestore.FieldValue.increment(-fee)});
    // Log debit transaction
    const txRef = db.collection("transactions").doc();
    transaction.set(txRef, {
      uid: nextWaitlistedUserId,
      groupId: groupId,
      eventId: eventId,
      type: "debit",
      amount: fee,
      description: `Fee for event '${eventData?.name ?? "Unnamed Event"}' (promoted from waitlist)`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    logger.info(`User ${nextWaitlistedUserId} promoted to confirmed for event ${eventId}. Charged ${fee}.`);
  } else {
    // User does not have sufficient funds, skip and try next (if any)
    transaction.update(nextWaitlistedDoc.ref, {status: "denied", denialReason: "Insufficient funds at promotion"});
    transaction.update(eventRef, {waitlistCount: admin.firestore.FieldValue.increment(-1)}); // Decrement waitlist count
    logger.info(`User ${nextWaitlistedUserId} denied promotion for event ${eventId} due to insufficient funds.`);
    // Recursively call processWaitlist to check the next person, if needed
    // This is tricky in a transaction, often better to let a scheduled job re-trigger or handle outside.
    // For now, we'll just process one at a time.
  }
};
