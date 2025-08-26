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
 * Callable to (a) remove a member or (b) credit wallet balance.
 * Constraints:
 *  - Single admin model: only group.admin may invoke.
 *  - Cannot remove admin (owner) account.
 *  - Cannot remove member with non-zero walletBalance.
 *  - Credit action requires positive amount.
 *  - Creates a transactions doc (planned schema) if crediting (idempotent not guaranteed yet).
 */
/**
 * Callable function for managing existing group members.
 * Supports two actions:
 *  - remove: deletes member + userGroupMembership index (if balance is zero and not admin)
 *  - credit: increments walletBalance and writes a transaction record
 * @param {admin.firestore.Firestore} db Firestore database instance
 * @return {any} HTTPS callable handler
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
