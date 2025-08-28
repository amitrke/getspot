import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Returns a Firestore trigger function that processes new event participant documents.
 *
 * This function is triggered when a new document is created in the `participants`
 * subcollection for an event. It only acts on participants with a status of
 * 'requested'.
 *
 * The function performs the following steps in a transaction:
 * 1. Validates the existence of the corresponding event, group, and member.
 * 2. Checks if the member's wallet balance (plus the group's negative balance
 *    limit) is sufficient to cover the event fee.
 * 3. If funds are insufficient, the participant's status is updated to 'denied'.
 * 4. If funds are sufficient, it checks for available spots in the event.
 * 5. If spots are available, the status is changed to 'confirmed' and the event's
 *    `confirmedCount` is incremented.
 * 6. If the event is full, the status is changed to 'waitlisted' and the event's
 *    `waitlistCount` is incremented.
 *
 * @param {admin.firestore.Firestore} db - The Firestore database instance.
 * @return {CloudFunction<DocumentSnapshot>} A Firestore trigger function.
 */
export const processEventRegistration = (db: admin.firestore.Firestore) =>
  onDocumentCreated(
    {
      document: "events/{eventId}/participants/{userId}",
      region: "us-east4",
    },
    async (event) => {
      const participantSnap = event.data;
      if (!participantSnap) {
        logger.log("No data associated with the event.");
        return;
      }


      const participantData = participantSnap.data();
      const {eventId, userId} = event.params;

      // Only process documents with 'requested' status
      if (participantData.status !== "requested") {
        return;
      }

      const eventRef = db.collection("events").doc(eventId);
      const participantRef = db
        .collection("events").doc(eventId)
        .collection("participants").doc(userId);

      try {
        await db.runTransaction(async (transaction) => {
          const eventDoc = await transaction.get(eventRef);
          if (!eventDoc.exists) {
            throw new Error("Event not found!");
          }

          const eventData = eventDoc.data();
          const groupId = eventData?.groupId;
          if (!groupId) {
            throw new Error("Group ID not found on event!");
          }

          const memberRef = db
            .collection("groups")
            .doc(groupId)
            .collection("members")
            .doc(userId);
          const memberDoc = await transaction.get(memberRef);
          const groupRef = memberRef.parent.parent;
          if (!groupRef) {
            throw new Error("Could not get group reference.");
          }
          const groupDoc = await transaction.get(groupRef);

          if (!memberDoc.exists || !groupDoc.exists) {
            throw new Error("Member or Group not found!");
          }

          const memberData = memberDoc.data();
          const groupData = groupDoc.data();
          const fee = eventData?.fee ?? 0;
          const negativeBalanceLimit = groupData?.negativeBalanceLimit ?? 0;
          const walletBalance = memberData?.walletBalance ?? 0;

          // 1. Check wallet balance first. This is the gatekeeper.
          if (walletBalance + negativeBalanceLimit < fee) {
            transaction.update(participantRef, {
              status: "denied",
              denialReason: "Insufficient funds",
            });
            logger.log(`User ${userId} denied for event ${eventId} due to insufficient funds.`);
            return;
          }

          // 2. Balance is sufficient, so deduct fee and log transaction immediately.
          transaction.update(memberRef, {
            walletBalance: admin.firestore.FieldValue.increment(-fee),
          });
          const txRef = db.collection("transactions").doc();
          transaction.set(txRef, {
            uid: userId,
            groupId: groupId,
            eventId: eventId,
            type: "debit",
            amount: fee,
            description: `Fee for event '${eventData?.name ?? "Unnamed Event"}'`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // 3. Now, check for available spots to determine status.
          const confirmedCount = eventData?.confirmedCount ?? 0;
          const maxParticipants = eventData?.maxParticipants ?? 0;

          if (confirmedCount < maxParticipants) {
            // Promote to confirmed
            transaction.update(participantRef, {status: "confirmed"});
            transaction.update(eventRef, {
              confirmedCount: admin.firestore.FieldValue.increment(1),
            });
            logger.log(`User ${userId} confirmed for event ${eventId} and charged ${fee}.`);
          } else {
            // Add to waitlist
            transaction.update(participantRef, {status: "waitlisted"});
            transaction.update(eventRef, {
              waitlistCount: admin.firestore.FieldValue.increment(1),
            });
            logger.log(`User ${userId} waitlisted for event ${eventId} and charged ${fee}.`);
          }
        });
      } catch (error) {
        logger.error(
          `Error processing registration for user ${userId} ` +
          `in event ${eventId}:`,
          error,
        );
        // If the transaction fails, update the status to 'denied'
        // so it's not re-processed
        await participantRef.update({
          status: "denied",
          denialReason: "An internal error occurred.",
        });
      }
    },
  );
