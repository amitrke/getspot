import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {processWaitlist} from "./processWaitlist";

interface WithdrawFromEventData {
  eventId: string;
}

/**
 * Factory creating callable function allowing an authenticated user to withdraw from an event.
 * Handles refunds based on status (confirmed / waitlisted) and commitment deadline rules.
 * @param {admin.firestore.Firestore} db Firestore database instance
 * @return {*} HTTPS callable handler
 */
export const withdrawFromEvent = (db: admin.firestore.Firestore) =>
  onCall<WithdrawFromEventData>(async (request) => {
    // 1. Authentication & Validation
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const {eventId} = request.data;
    if (!eventId) {
      throw new HttpsError("invalid-argument", "Missing required parameter: eventId.");
    }

    const userId = request.auth.uid;

    logger.info(`User ${userId} attempting to withdraw from event ${eventId}.`);

    try {
      return await db.runTransaction(async (transaction) => {
        const eventRef = db.collection("events").doc(eventId);
        const participantRef = eventRef.collection("participants").doc(userId);

        const eventDoc = await transaction.get(eventRef);
        const participantDoc = await transaction.get(participantRef);

        if (!eventDoc.exists || !participantDoc.exists) {
          throw new HttpsError("not-found", "Event or participant record not found.");
        }

        const eventData = eventDoc.data() as {
          groupId?: string;
          fee?: number;
          name?: string;
          waitlistCount?: number;
          commitmentDeadline?: admin.firestore.Timestamp;
        } | undefined;
        const participantData = participantDoc.data() as {status?: string} | undefined;
        if (!eventData) {
          throw new HttpsError("internal", "Event data missing.");
        }
        if (!participantData) {
          throw new HttpsError("internal", "Participant data missing.");
        }
        const groupId = eventData.groupId;

        if (!groupId) {
          throw new HttpsError("internal", "Event is missing group information.");
        }

        const memberRef = db.collection("groups").doc(groupId).collection("members").doc(userId);
        const memberDoc = await transaction.get(memberRef);

        if (!memberDoc.exists) {
          throw new HttpsError("not-found", "Group membership not found.");
        }

        const fee = eventData.fee ?? 0;
        const userStatus = participantData.status ?? "unknown";

        // --- Main Logic ---

        // Case 1: User is on the waitlist. Always a full refund.
        if (userStatus === "waitlisted") {
          transaction.update(participantRef, {status: "withdrawn"});
          transaction.update(eventRef, {waitlistCount: admin.firestore.FieldValue.increment(-1)});
          // Refund the fee
          transaction.update(memberRef, {walletBalance: admin.firestore.FieldValue.increment(fee)});
          // Log the credit transaction
          const txRef = db.collection("transactions").doc();
          transaction.set(txRef, {
            uid: userId,
            groupId: groupId,
            eventId: eventId,
            type: "credit",
            amount: fee,
            description: `Refund for event '${eventData.name}' (withdrew from waitlist)`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logger.info(`User ${userId} withdrew from waitlist for event ${eventId}. Refunded ${fee}.`);
          return {status: "success", message: "Successfully withdrew from waitlist and received a refund."};
        }

        // Case 2: User is confirmed.
        if (userStatus === "confirmed") {
          if (!eventData.commitmentDeadline) {
            throw new HttpsError("internal", "Event missing commitment deadline.");
          }
          const commitmentDeadline = eventData.commitmentDeadline.toDate();
          const now = new Date();

          const isBeforeDeadline = now < commitmentDeadline;
          const waitlistHasUsers = (eventData.waitlistCount ?? 0) > 0;

          // Refund if before deadline OR if after deadline but someone is on the waitlist to take the spot.
          if (isBeforeDeadline || waitlistHasUsers) {
            transaction.update(participantRef, {status: "withdrawn"});
            transaction.update(eventRef, {confirmedCount: admin.firestore.FieldValue.increment(-1)});
            // Refund the fee
            transaction.update(memberRef, {walletBalance: admin.firestore.FieldValue.increment(fee)});
            // Log the credit transaction
            const txRef = db.collection("transactions").doc();
            transaction.set(txRef, {
              uid: userId,
              groupId: groupId,
              eventId: eventId,
              type: "credit",
              amount: fee,
              description: `Refund for event '${eventData.name}'`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Promote the next user from the waitlist if a spot opened up
            await processWaitlist(db, transaction, eventId);
            logger.info(`User ${userId} withdrew from event ${eventId}. Refunded ${fee}.`);
            return {status: "success", message: "Successfully withdrew and received a refund."};
          } else {
            // After deadline and no one on the waitlist to take the spot. Fee is forfeited.
            transaction.update(participantRef, {status: "withdrawn_penalty"}); // A more descriptive status
            transaction.update(eventRef, {confirmedCount: admin.firestore.FieldValue.increment(-1)});
            // No refund is issued.
            logger.info(`User ${userId} withdrew from event ${eventId} after deadline. Fee of ${fee} forfeited.`);
            return {status: "success", message: "Successfully withdrew. The fee was forfeited as per the commitment deadline."};
          }
        }

        throw new HttpsError("failed-precondition", `Cannot withdraw with current status: ${userStatus}`);
      });
    } catch (err) {
      logger.error("Error withdrawing from event:", err);
      if (err instanceof HttpsError) {
        throw err;
      }
      throw new HttpsError("internal", "An unexpected error occurred.");
    }
  });
