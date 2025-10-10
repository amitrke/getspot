import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {processWaitlist} from "./processWaitlist";

/**
 * Callable function to update the maxParticipants capacity for an event.
 *
 * Rationale: Allows admins to adjust event capacity before the event starts.
 * When increasing capacity, automatically promotes waitlisted users.
 * When decreasing capacity, prevents reduction below current confirmed count.
 *
 * Validation:
 * - User must be authenticated and be the group admin
 * - Event must exist and not be cancelled
 * - Event must not have started yet
 * - New capacity must be positive
 * - New capacity cannot be less than current confirmed count
 *
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {CloudFunction} A callable function
 */
export const updateEventCapacity = (db: admin.firestore.Firestore) =>
  onCall(async (request) => {
    // 1. Check authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be logged in to update event capacity.");
    }

    const {eventId, newMaxParticipants} = request.data;

    // 2. Validate input
    if (!eventId || typeof eventId !== "string") {
      throw new HttpsError("invalid-argument", "Event ID is required.");
    }

    if (!newMaxParticipants || typeof newMaxParticipants !== "number" || newMaxParticipants <= 0) {
      throw new HttpsError("invalid-argument", "New max participants must be a positive number.");
    }

    const eventRef = db.collection("events").doc(eventId);

    try {
      const result = await db.runTransaction(async (transaction) => {
        const eventDoc = await transaction.get(eventRef);

        if (!eventDoc.exists) {
          throw new HttpsError("not-found", "Event not found.");
        }

        const eventData = eventDoc.data();

        // 3. Check if event is cancelled
        if (eventData?.status === "cancelled") {
          throw new HttpsError("failed-precondition", "Cannot update capacity for a cancelled event.");
        }

        // 4. Check if event has already started
        const eventTimestamp = eventData?.eventTimestamp;
        if (eventTimestamp && eventTimestamp.toDate() <= new Date()) {
          throw new HttpsError("failed-precondition", "Cannot update capacity after the event has started.");
        }

        // 5. Verify the user is the group admin
        const groupId = eventData?.groupId;
        if (!groupId) {
          throw new HttpsError("internal", "Event is missing group ID.");
        }

        const groupRef = db.collection("groups").doc(groupId);
        const groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw new HttpsError("not-found", "Group not found.");
        }

        const groupData = groupDoc.data();
        if (groupData?.admin !== request.auth?.uid) {
          throw new HttpsError("permission-denied", "Only the group admin can update event capacity.");
        }

        // 6. Check if new capacity is valid
        const currentMaxParticipants = eventData?.maxParticipants ?? 0;
        const confirmedCount = eventData?.confirmedCount ?? 0;
        const waitlistCount = eventData?.waitlistCount ?? 0;

        if (newMaxParticipants < confirmedCount) {
          throw new HttpsError(
            "failed-precondition",
            `Cannot reduce capacity to ${newMaxParticipants}. There are already ${confirmedCount} confirmed participants.`,
          );
        }

        // 7. Update the capacity
        transaction.update(eventRef, {
          maxParticipants: newMaxParticipants,
        });

        logger.info(`Updated event ${eventId} capacity from ${currentMaxParticipants} to ${newMaxParticipants}`);

        // 8. If capacity increased, process waitlist to promote users
        const promotedUsers: string[] = [];
        if (newMaxParticipants > currentMaxParticipants) {
          const spotsAvailable = newMaxParticipants - confirmedCount;
          const usersToPromote = Math.min(spotsAvailable, waitlistCount);

          logger.info(`Attempting to promote up to ${usersToPromote} users from waitlist for event ${eventId}`);

          for (let i = 0; i < usersToPromote; i++) {
            const promotedUserId = await processWaitlist(db, transaction, eventId);
            if (promotedUserId) {
              promotedUsers.push(promotedUserId);
            } else {
              // No more users to promote
              break;
            }
          }

          logger.info(`Promoted ${promotedUsers.length} users from waitlist for event ${eventId}`);
        }

        return {
          oldCapacity: currentMaxParticipants,
          newCapacity: newMaxParticipants,
          confirmedCount,
          waitlistCount,
          promotedCount: promotedUsers.length,
          promotedUsers,
        };
      });

      return {
        success: true,
        message: result.promotedCount > 0 ?
          `Capacity updated to ${result.newCapacity}. ${result.promotedCount} user(s) promoted from waitlist.` :
          `Capacity updated to ${result.newCapacity}.`,
        ...result,
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error(`Error updating event capacity for event ${eventId}:`, error);
      throw new HttpsError("internal", "An internal error occurred while updating event capacity.");
    }
  });
