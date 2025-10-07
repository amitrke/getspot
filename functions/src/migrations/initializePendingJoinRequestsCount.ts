import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Migration script to initialize pendingJoinRequestsCount for existing groups.
 *
 * This script:
 * 1. Fetches all groups in the database
 * 2. For each group, counts pending join requests
 * 3. Updates the group document with the correct count
 *
 * This is a one-time migration script that should be run after deploying
 * the maintainJoinRequestCount triggers.
 *
 * Usage:
 * - Deploy this as a callable function
 * - Call it once from the Firebase Console or via curl
 * - Remove or comment out after successful migration
 *
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @return {Function} Callable function for migration
 */
export const initializePendingJoinRequestsCount = (
  db: admin.firestore.Firestore
) => {
  return async () => {
    logger.info("Starting migration: initializePendingJoinRequestsCount");

    try {
      // Fetch all groups
      const groupsSnapshot = await db.collection("groups").get();
      logger.info(`Found ${groupsSnapshot.size} groups to process`);

      let successCount = 0;
      let errorCount = 0;
      const errors: Array<{groupId: string; error: string}> = [];

      // Process each group
      for (const groupDoc of groupsSnapshot.docs) {
        try {
          const groupId = groupDoc.id;
          const groupData = groupDoc.data();

          // Skip if already has the field
          if (
            groupData.pendingJoinRequestsCount !== undefined &&
            groupData.pendingJoinRequestsCount !== null
          ) {
            logger.info(
              `Group ${groupId} already has pendingJoinRequestsCount: ${groupData.pendingJoinRequestsCount}`
            );
            successCount++;
            continue;
          }

          // Count pending join requests
          const joinRequestsSnapshot = await db
            .collection("groups")
            .doc(groupId)
            .collection("joinRequests")
            .where("status", "==", "pending")
            .get();

          const count = joinRequestsSnapshot.size;

          // Update the group document
          await db.collection("groups").doc(groupId).update({
            pendingJoinRequestsCount: count,
          });

          logger.info(
            `Updated group ${groupId} with pendingJoinRequestsCount: ${count}`
          );
          successCount++;
        } catch (error) {
          errorCount++;
          const errorMessage =
            error instanceof Error ? error.message : String(error);
          errors.push({groupId: groupDoc.id, error: errorMessage});
          logger.error(`Error processing group ${groupDoc.id}:`, error);
        }
      }

      // Summary
      const summary = {
        total: groupsSnapshot.size,
        success: successCount,
        errors: errorCount,
        errorDetails: errors,
      };

      logger.info("Migration completed", summary);

      return {
        status: "completed",
        message: `Migration completed. ${successCount} groups updated successfully, ${errorCount} errors.`,
        summary,
      };
    } catch (error) {
      logger.error("Migration failed:", error);
      throw error;
    }
  };
};
