import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

interface ManageGroupMemberData {
  groupId: string;
  targetUserId: string;
  action: "remove" | "credit";
  amount?: number; // required for credit
  description?: string; // optional note for credit
}

interface GroupDoc {
  admin?: string;
  name?: string;
}

interface MemberDoc {
  walletBalance?: number;
  displayName?: string;
  uid?: string;
}

/**
 * Returns a callable function for managing existing group members.
 *
 * This function supports two primary actions, determined by the `action` parameter
 * in the request data:
 *  - `remove`: Deletes a member from a group and removes their corresponding
 *    entry from the `userGroupMemberships` collection. This action has
 *    preconditions: the member cannot be the group admin and must have a
 *    wallet balance of zero.
 *  - `credit`: Adds a specified amount to a member's wallet balance and creates
 *    a corresponding transaction record in the `transactions` collection.
 *
 * @param {admin.firestore.Firestore} db - The Firestore database instance.
 * @returns {onCall<ManageGroupMemberData>} An HTTPS callable function that can be
 * invoked from the client.
 * @throws {HttpsError} Throws various HTTPS errors for unauthenticated requests,
 * invalid arguments, permission denied (not an admin), not found (group or
 * member), and failed preconditions (e.g., trying to remove an admin or a
 * member with a non-zero balance).
 */
export const manageGroupMember = (db: admin.firestore.Firestore) =>
  onCall<ManageGroupMemberData>({region: "us-east4"}, async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const {groupId, targetUserId, action, amount, description} = request.data;
    if (!groupId || !targetUserId || !action) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required parameters: groupId, targetUserId, action."
      );
    }

    const callerUid = request.auth.uid;
    const groupRef = db.collection("groups").doc(groupId);
    const memberRef = groupRef.collection("members").doc(targetUserId);

    try {
      const groupSnap = await groupRef.get();
      if (!groupSnap.exists) {
        throw new HttpsError("not-found", "Group not found.");
      }
      const groupData = groupSnap.data() as GroupDoc | undefined;
      if (!groupData || groupData.admin !== callerUid) {
        throw new HttpsError(
          "permission-denied",
          "Only the group admin may manage members."
        );
      }

      if (action === "remove") {
        if (targetUserId === groupData.admin) {
          throw new HttpsError(
            "failed-precondition",
            "Cannot remove the group admin."
          );
        }
        return await db.runTransaction(async (tx) => {
          const memberSnap = await tx.get(memberRef);
          if (!memberSnap.exists) {
            throw new HttpsError("not-found", "Member does not exist.");
          }
          const memberData = memberSnap.data() as MemberDoc;
          const balance = memberData.walletBalance ?? 0;
          if (balance !== 0) {
            throw new HttpsError(
              "failed-precondition",
              "Member has non-zero balance; cannot remove."
            );
          }
          // Remove membership docs (group side + user index)
          const userIndexRef = db
            .collection("userGroupMemberships")
            .doc(targetUserId)
            .collection("groups")
            .doc(groupId);
          tx.delete(memberRef);
          tx.delete(userIndexRef);
          logger.info("Member removed", {groupId, targetUserId, callerUid});
          return {status: "removed"};
        });
      } else if (action === "credit") {
        if (typeof amount !== "number" || amount <= 0) {
          throw new HttpsError(
            "invalid-argument",
            "Amount must be a positive number for credit action."
          );
        }
        return await db.runTransaction(async (tx) => {
          const memberSnap = await tx.get(memberRef);
          if (!memberSnap.exists) {
            throw new HttpsError("not-found", "Member does not exist.");
          }
          const memberData = memberSnap.data() as MemberDoc;
          const currentBalance = memberData.walletBalance ?? 0;
          const newBalance = currentBalance + amount;
          tx.update(memberRef, {walletBalance: newBalance});
          // Basic transaction record (if transactions collection used later)
          const txRef = db.collection("transactions").doc();
          tx.set(txRef, {
            type: "credit_manual",
            amount,
            userId: targetUserId,
            groupId,
            description: description || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logger.info("Member credited", {groupId, targetUserId, amount});
          return {status: "credited", balance: newBalance};
        });
      } else {
        throw new HttpsError("invalid-argument", "Unsupported action.");
      }
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logger.error("manageGroupMember error", err);
      throw new HttpsError("internal", "Unexpected error.");
    }
  });
