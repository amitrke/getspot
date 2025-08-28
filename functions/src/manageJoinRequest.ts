import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

interface ManageJoinRequestData {
  groupId: string;
  requestedUserId: string;
  action: "approve" | "deny" | "delete";
}

/**
 * Returns a callable function for group admins to manage join requests.
 *
 * This function allows an admin to perform one of three actions on a join request:
 *  - `approve`: Adds the requesting user as a member of the group, initializes
 *    their wallet, creates a `userGroupMemberships` entry, and deletes the
 *    original join request. This is performed as an atomic transaction.
 *  - `deny`: Updates the status of the join request to 'denied', leaving the
 *    request in place for the user to see the result.
 *  - `delete`: Removes the join request document entirely.
 *
 * @param {admin.firestore.Firestore} db - The Firestore database instance.
 * @return {onCall<ManageJoinRequestData>} An HTTPS callable function.
 * @throws {HttpsError} Throws for unauthenticated requests, invalid arguments,
 * permission denied (not an admin), or if the request document is not found.
 */
export const manageJoinRequest = (db: admin.firestore.Firestore) =>
  onCall<ManageJoinRequestData>(
    {region: "us-east4"},
    async (request) => {
      // 1. Authentication & Authorization
      if (!request.auth) {
        throw new HttpsError(
          "unauthenticated",
          "The function must be called while authenticated."
        );
      }

      const {groupId, requestedUserId, action} = request.data;
      if (!groupId || !requestedUserId || !action) {
        throw new HttpsError(
          "invalid-argument",
          "Missing required parameters: groupId, requestedUserId, action."
        );
      }

      const adminUid = request.auth.uid;
      const groupRef = db.collection("groups").doc(groupId);
      const requestRef = groupRef
        .collection("joinRequests")
        .doc(requestedUserId);
      const memberRef = groupRef.collection("members").doc(requestedUserId);

      try {
        const groupDoc = await groupRef.get();
        if (!groupDoc.exists || groupDoc.data()?.admin !== adminUid) {
          throw new HttpsError(
            "permission-denied",
            "You must be the admin of this group to perform this action."
          );
        }

        // 2. Perform Action
        switch (action) {
        case "approve": {
          const requestDoc = await requestRef.get();
          if (!requestDoc.exists) {
            throw new HttpsError(
              "not-found",
              "The join request does not exist."
            );
          }
          const requestData = requestDoc.data();
          if (!requestData) {
            throw new HttpsError(
              "internal",
              "Request data is missing."
            );
          }

          // Create a new member and delete the request atomically
          await db.runTransaction(async (transaction) => {
            const groupData = (await transaction.get(groupRef)).data();
            const userGroupMembershipRef = db
              .collection("userGroupMemberships")
              .doc(requestedUserId)
              .collection("groups")
              .doc(groupId);

            transaction.set(memberRef, {
              uid: requestedUserId,
              displayName: requestData.displayName,
              walletBalance: 0, // Initial wallet balance
              joinedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            transaction.set(userGroupMembershipRef, {
              groupId: groupId,
              groupName: groupData?.name ?? "Unnamed Group",
              isAdmin: false,
            });

            transaction.delete(requestRef);
          });

          return {status: "success", message: "User approved successfully."};
        }

        case "deny": {
          // Update the request status to 'denied'
          await requestRef.update({status: "denied"});
          return {status: "success", message: "User request denied."};
        }

        case "delete": {
          // Delete the request document
          await requestRef.delete();
          return {status: "success", message: "Request deleted."};
        }

        default: {
          throw new HttpsError(
            "invalid-argument",
            "Invalid action specified. Must be 'approve', 'deny', or 'delete'."
          );
        }
        }
      } catch (error) {
        logger.error("Error managing join request:", error);
        if (error instanceof HttpsError) {
          throw error;
        }
        throw new HttpsError(
          "internal",
          "An unexpected error occurred."
        );
      }
    }
  );

