import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

interface UpdateFcmTokenData {
  token: string;
}

/**
 * Returns a callable function that allows a user to add their FCM token
 * to their user document.
 *
 * @param {admin.firestore.Firestore} db - The Firestore database instance.
 * @return {onCall<UpdateFcmTokenData>} An HTTPS callable function.
 * @throws {HttpsError} Throws for unauthenticated requests or invalid arguments.
 */
export const updateFcmToken = (db: admin.firestore.Firestore) =>
  onCall<UpdateFcmTokenData>(async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    const {token} = request.data;
    if (!token) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required parameter: token."
      );
    }

    const {uid} = request.auth;
    const userRef = db.collection("users").doc(uid);

    try {
      await userRef.update({
        fcmTokens: admin.firestore.FieldValue.arrayUnion(token),
      });
      logger.info(`Added FCM token for user ${uid}`);
      return {status: "success", message: "Token updated successfully."};
    } catch (error) {
      logger.error(`Error updating FCM token for user ${uid}:`, error);
      // Check if the document exists, if not, create it.
      if ((error as any).code === 5) { // 5 = NOT_FOUND
        await userRef.set({
          fcmTokens: [token],
        }, {merge: true});
        logger.info(`Created user document and added FCM token for ${uid}`);
        return {status: "success", message: "Token updated successfully."};
      }
      throw new HttpsError(
        "internal",
        "An unexpected error occurred while updating the token."
      );
    }
  });
