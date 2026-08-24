import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

interface FindGroupByCodeData {
  code: string;
}

/**
 * Returns a callable function that looks up a group by its shareable code.
 *
 * Firestore Security Rules deny arbitrary `list` queries on `/groups` to
 * prevent an authenticated user from enumerating every group (and its
 * admin uid, negativeBalanceLimit, etc.) they aren't a member of. This
 * function runs with Admin SDK privileges and is the only way a
 * non-member can look up a group before joining — it returns just the
 * fields needed for the "you've been invited to join X" preview screen.
 *
 * @param {admin.firestore.Firestore} db - The Firestore database instance.
 * @return {onCall<FindGroupByCodeData>} An HTTPS callable function.
 * @throws {HttpsError} Throws for unauthenticated requests, invalid
 * arguments, or if no group matches the code.
 */
export const findGroupByCode = (db: admin.firestore.Firestore) =>
  onCall<FindGroupByCodeData>(async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const {code} = request.data;
    if (!code || typeof code !== "string") {
      throw new HttpsError("invalid-argument", "Missing required parameter: code.");
    }

    // Standardize the same way the group's groupCodeSearch field is stored
    // (uppercase, no dashes) at creation time — see createGroup in index.ts.
    const standardizedCode = code.trim().toUpperCase().replace(/-/g, "");

    try {
      const snapshot = await db
        .collection("groups")
        .where("groupCodeSearch", "==", standardizedCode)
        .limit(1)
        .get();

      if (snapshot.empty) {
        throw new HttpsError("not-found", "No group found with that code.");
      }

      const doc = snapshot.docs[0];
      const data = doc.data();
      return {
        groupId: doc.id,
        name: data.name ?? "",
        description: data.description ?? "",
        groupCode: data.groupCode ?? "",
      };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logger.error("findGroupByCode error", err);
      throw new HttpsError("internal", "Unexpected error.");
    }
  });
