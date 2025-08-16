import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

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

          // 1. Check wallet balance
          if (walletBalance + negativeBalanceLimit < fee) {
            transaction.update(participantRef, {
              status: "denied",
              denialReason: "Insufficient funds",
            });
            logger.log(`User ${userId} denied for event ${eventId} due to ` +
            "insufficient funds.");
            return;
          }

          // 2. Check for available spots
          const confirmedCount = eventData?.confirmedCount ?? 0;
          const maxParticipants = eventData?.maxParticipants ?? 0;

          if (confirmedCount < maxParticipants) {
          // Promote to confirmed
            transaction.update(participantRef, {status: "confirmed"});
            transaction.update(eventRef, {
              confirmedCount: admin.firestore.FieldValue.increment(1),
            });
            logger.log(`User ${userId} confirmed for event ${eventId}.`);
          } else {
          // Add to waitlist
            transaction.update(participantRef, {status: "waitlisted"});
            transaction.update(eventRef, {
              waitlistCount: admin.firestore.FieldValue.increment(1),
            });
            logger.log(`User ${userId} waitlisted for event ${eventId}.`);
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
