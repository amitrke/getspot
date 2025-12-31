import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * A callable function to request the deletion of a user's account.
 * @param {admin.firestore.Firestore} db The Firestore database instance.
 * @return {*} A Cloud Scheduler handler.
 */
export const requestAccountDeletion = (db: admin.firestore.Firestore) =>
  onCall(async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const userId = request.auth.uid;
    logger.info(`User ${userId} is requesting to delete their account.`);

    const userGroupsSnapshot = await db.collection(`userGroupMemberships/${userId}/groups`).get();

    for (const groupDoc of userGroupsSnapshot.docs) {
      const groupId = groupDoc.id;
      const memberDoc = await db.collection(`groups/${groupId}/members`).doc(userId).get();

      if (memberDoc.exists) {
        const memberData = memberDoc.data();
        if (memberData && memberData.walletBalance < 0) {
          logger.warn(`User ${userId} has a negative balance in group ${groupId}. Account deletion is pended.`);
          throw new HttpsError(
            "failed-precondition",
            "You have an outstanding balance in one or more of your groups. Please contact your group admin to settle your balance before deleting your account.",
          );
        }
      }
    }

    logger.info(`User ${userId} has no outstanding balances. Proceeding with account deletion.`);

    try {
      // This will trigger the onDelete function in dataLifecycle.ts
      await admin.auth().deleteUser(userId);
      logger.info(`Successfully deleted user ${userId} from Firebase Authentication.`);
      return {status: "success", message: "Account deletion successful."};
    } catch (error) {
      logger.error(`Error deleting user ${userId}:`, error);
      throw new HttpsError("internal", "An unexpected error occurred while deleting your account.");
    }
  });
