import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const processJoinRequest = onCall(
  {region: "us-east4"},
  async (request) => {
    const db = admin.firestore();
    const {groupId, requestedUserId, action} = request.data;

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to perform this action.",
      );
    }

    if (!groupId || !requestedUserId || !action) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required parameters.",
      );
    }

    if (action !== "approve" && action !== "deny") {
      throw new HttpsError(
        "invalid-argument",
        "Action must be either 'approve' or 'deny'.",
      );
    }

    const groupRef = db.collection("groups").doc(groupId);
    const requestRef = groupRef.collection("joinRequests").doc(requestedUserId);
    const memberRef = groupRef.collection("members").doc(requestedUserId);

    try {
      const groupDoc = await groupRef.get();
      if (!groupDoc.exists) {
        throw new HttpsError("not-found", "Group not found.");
      }

      const groupData = groupDoc.data();
      if (groupData?.admin !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "You must be the group admin to perform this action.",
        );
      }

      if (action === "approve") {
        const requestDoc = await requestRef.get();
        if (!requestDoc.exists) {
          throw new HttpsError(
            "not-found",
            "Join request not found.",
          );
        }
        const requestData = requestDoc.data();

        await memberRef.set({
          uid: requestedUserId,
          displayName: requestData?.displayName,
          walletBalance: 0,
          joinedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await requestRef.delete();

      logger.info(
        `Join request for user ${requestedUserId} in group ${groupId} ` +
        `was ${action}d by admin ${request.auth.uid}`,
      );

      return {success: true};
    } catch (error) {
      logger.error("Error processing join request:", error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError(
        "internal",
        "An unexpected error occurred.",
      );
    }
  },
);
