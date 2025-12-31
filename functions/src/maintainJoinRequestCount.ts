import {onDocumentCreated, onDocumentDeleted, onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Maintains the pendingJoinRequestsCount field on the group document.
 *
 * Triggers when join request documents are created, updated, or deleted.
 * Updates the group's pendingJoinRequestsCount field to reflect the
 * current number of pending requests.
 */

/**
 * Increment count when a new pending join request is created
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {CloudFunction} Firestore trigger function
 */
export const onJoinRequestCreated = (db: admin.firestore.Firestore) =>
  onDocumentCreated("groups/{groupId}/joinRequests/{requestId}", async (event) => {
    const data = event.data?.data();
    if (!data) return;

    // Only increment for pending requests
    if (data.status !== "pending") return;

    const groupId = event.params.groupId;
    const groupRef = db.collection("groups").doc(groupId);

    try {
      await groupRef.update({
        pendingJoinRequestsCount: admin.firestore.FieldValue.increment(1),
      });
      logger.info(`Incremented pendingJoinRequestsCount for group ${groupId}`);
    } catch (error) {
      logger.error(`Error incrementing count for group ${groupId}:`, error);
    }
  });

/**
 * Update count when a join request status changes
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {CloudFunction} Firestore trigger function
 */
export const onJoinRequestUpdated = (db: admin.firestore.Firestore) =>
  onDocumentUpdated("groups/{groupId}/joinRequests/{requestId}", async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) return;

    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;

    // Only update count if status changed
    if (beforeStatus === afterStatus) return;

    const groupId = event.params.groupId;
    const groupRef = db.collection("groups").doc(groupId);

    try {
      // Was pending, now not pending: decrement
      if (beforeStatus === "pending" && afterStatus !== "pending") {
        await groupRef.update({
          pendingJoinRequestsCount: admin.firestore.FieldValue.increment(-1),
        });
        logger.info(`Decremented pendingJoinRequestsCount for group ${groupId}`);
      } else if (beforeStatus !== "pending" && afterStatus === "pending") {
        // Was not pending, now pending: increment
        await groupRef.update({
          pendingJoinRequestsCount: admin.firestore.FieldValue.increment(1),
        });
        logger.info(`Incremented pendingJoinRequestsCount for group ${groupId}`);
      }
    } catch (error) {
      logger.error(`Error updating count for group ${groupId}:`, error);
    }
  });

/**
 * Decrement count when a pending join request is deleted
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {CloudFunction} Firestore trigger function
 */
export const onJoinRequestDeleted = (db: admin.firestore.Firestore) =>
  onDocumentDeleted("groups/{groupId}/joinRequests/{requestId}", async (event) => {
    const data = event.data?.data();
    if (!data) return;

    // Only decrement if it was a pending request
    if (data.status !== "pending") return;

    const groupId = event.params.groupId;
    const groupRef = db.collection("groups").doc(groupId);

    try {
      await groupRef.update({
        pendingJoinRequestsCount: admin.firestore.FieldValue.increment(-1),
      });
      logger.info(`Decremented pendingJoinRequestsCount for group ${groupId}`);
    } catch (error) {
      logger.error(`Error decrementing count for group ${groupId}:`, error);
    }
  });
