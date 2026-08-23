import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

interface ManageGroupMemberData {
  groupId: string;
  targetUserId: string;
  action: "remove" | "credit" | "leave";
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
 * This function supports three actions, determined by the `action` parameter
 * in the request data:
 *  - `remove`: Admin-only. Deletes a member from a group and removes their
 *    corresponding entry from the `userGroupMemberships` collection. Has
 *    preconditions: the member cannot be the group admin, must have a
 *    wallet balance of zero, and cannot have a confirmed/waitlisted
 *    registration for any upcoming active event in the group.
 *  - `leave`: Self-service equivalent of `remove` — a member removes
 *    themselves, with the same preconditions.
 *  - `credit`: Adds a specified amount to a member's wallet balance and creates
 *    a corresponding transaction record in the `transactions` collection.
 *
 * @param {admin.firestore.Firestore} db - The Firestore database instance.
 * @return {onCall<ManageGroupMemberData>} An HTTPS callable function that can be
 * invoked from the client.
 * @throws {HttpsError} Throws various HTTPS errors for unauthenticated requests,
 * invalid arguments, permission denied (not an admin), not found (group or
 * member), and failed preconditions (e.g., trying to remove an admin or a
 * member with a non-zero balance).
 */
export const manageGroupMember = (db: admin.firestore.Firestore) =>
  onCall<ManageGroupMemberData>(async (request) => {
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
      if (!groupData) {
        throw new HttpsError("not-found", "Group not found.");
      }

      if (action === "leave") {
        if (callerUid !== targetUserId) {
          throw new HttpsError(
            "permission-denied",
            "You can only remove yourself with the leave action."
          );
        }
      } else if (groupData.admin !== callerUid) {
        throw new HttpsError(
          "permission-denied",
          "Only the group admin may manage members."
        );
      }

      if (action === "remove" || action === "leave") {
        if (targetUserId === groupData.admin) {
          throw new HttpsError(
            "failed-precondition",
            action === "leave" ?
              "Group admins can't leave their own group. Transfer ownership or delete the group instead." :
              "Cannot remove the group admin."
          );
        }

        // Find any upcoming active events in this group so we can check
        // (transactionally, below) whether the member still has a live
        // registration that needs withdrawing first — applies to both a
        // self-service leave and an admin-initiated remove, since either
        // way a stale participant doc would be left behind (and the
        // member's spot wouldn't be freed up for the waitlist).
        const upcomingEvents = await db
          .collection("events")
          .where("groupId", "==", groupId)
          .where("status", "==", "active")
          .where("eventTimestamp", ">", admin.firestore.Timestamp.now())
          .get();
        const upcomingEventRefs = upcomingEvents.docs.map((doc) => doc.ref);

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
              action === "leave" ?
                "Settle your wallet balance with the group admin before leaving." :
                "Member has non-zero balance; cannot remove."
            );
          }

          if (upcomingEventRefs.length > 0) {
            const participantSnaps = await Promise.all(
              upcomingEventRefs.map((eventRef) =>
                tx.get(eventRef.collection("participants").doc(targetUserId))
              )
            );
            const hasLiveRegistration = participantSnaps.some((snap) => {
              const status = snap.data()?.status;
              return status === "confirmed" || status === "waitlisted";
            });
            if (hasLiveRegistration) {
              throw new HttpsError(
                "failed-precondition",
                action === "leave" ?
                  "Withdraw from your upcoming event registrations before leaving the group." :
                  "This member has an upcoming event registration. They must withdraw themselves, " +
                    "or the event must be cancelled, before they can be removed."
              );
            }
          }

          // Remove membership docs (group side + user index)
          const userIndexRef = db
            .collection("userGroupMemberships")
            .doc(targetUserId)
            .collection("groups")
            .doc(groupId);
          tx.delete(memberRef);
          tx.delete(userIndexRef);
          logger.info(action === "leave" ? "Member left group" : "Member removed", {
            groupId,
            targetUserId,
            callerUid,
          });
          return {status: action === "leave" ? "left" : "removed"};
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
            type: "credit",
            amount,
            uid: targetUserId,
            groupId,
            description: description || "Admin credit",
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
