import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Scheduled function to clean up ended events and refund waitlisted users.
 * Runs periodically (e.g., every 6 hours).
 * @param {admin.firestore.Firestore} db Firestore instance
 * @return {*} Cloud Scheduler handler
 */
export const cleanupEndedEvents = (db: admin.firestore.Firestore) =>
  onSchedule({schedule: "every 6 hours"}, async (event) => {
    logger.info("Running cleanupEndedEvents scheduled job.", event);

    const now = admin.firestore.Timestamp.now();

    try {
      // 1. Find events that have ended and haven't been cleaned up yet.
      const eventsToCleanQuery = db.collection("events")
        .where("eventTimestamp", "<", now)
        .limit(50); // Process in batches

      const eventsToCleanSnap = await eventsToCleanQuery.get();

      if (eventsToCleanSnap.empty) {
        logger.info("No ended events to clean up.");
        return;
      }

      for (const eventDoc of eventsToCleanSnap.docs) {
        const eventId = eventDoc.id;
        const eventData = eventDoc.data();

        // Skip events that have already been cleaned up.
        if (eventData.isCleanedUp === true) {
          continue;
        }

        const groupId = eventData.groupId;
        const fee = eventData.fee ?? 0;

        if (!groupId) {
          logger.warn(`Event ${eventId} missing groupId. Skipping cleanup.`);
          continue;
        }

        logger.info(`Cleaning up event ${eventId}: ${eventData.name}`);

        // Process waitlisted participants for this event
        const waitlistedParticipantsQuery = db.collection("events").doc(eventId)
          .collection("participants")
          .where("status", "==", "waitlisted");

        const waitlistedSnap = await waitlistedParticipantsQuery.get();

        if (waitlistedSnap.empty) {
          logger.info(`No waitlisted participants for event ${eventId}.`);
        } else {
          const batch = db.batch();
          for (const participantDoc of waitlistedSnap.docs) {
            const participantId = participantDoc.id;
            const memberRef = db.collection("groups").doc(groupId).collection("members").doc(participantId);

            // Refund the fee
            batch.update(memberRef, {walletBalance: admin.firestore.FieldValue.increment(fee)});
            // Update participant status
            batch.update(participantDoc.ref, {status: "refunded_after_event_end"});
            // Log credit transaction
            const txRef = db.collection("transactions").doc();
            batch.set(txRef, {
              uid: participantId,
              groupId: groupId,
              eventId: eventId,
              type: "credit",
              amount: fee,
              description: `Refund for event '${eventData.name}' (event ended, never got spot)`,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.info(`Refunded ${fee} to waitlisted user ${participantId} for event ${eventId}.`);
          }
          await batch.commit();
        }

        // Mark event as cleaned up
        await eventDoc.ref.update({isCleanedUp: true});
        logger.info(`Event ${eventId} marked as cleaned up.`);
      }
    } catch (error) {
      logger.error("Error in cleanupEndedEvents:", error);
    }
  });
