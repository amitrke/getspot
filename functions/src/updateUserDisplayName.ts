import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {onCall, CallableContext} from "firebase-functions/v1/https";

// This should be initialized in your index.ts
// admin.initializeApp();

export const updateUserDisplayName = (db: admin.firestore.Firestore) => onCall(async (data: any, context: CallableContext) => {
    // 1. Authentication Check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to update your display name."
      );
    }

    const uid = context.auth.uid;
    const newDisplayName = data.displayName;

    // 2. Input Validation
    if (!newDisplayName || typeof newDisplayName !== "string" || newDisplayName.trim().length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid display name must be provided."
      );
    }

    const batch = db.batch();

    try {
      // 3. Update the user's primary document in the 'users' collection
      const userRef = db.collection("users").doc(uid);
      batch.update(userRef, {displayName: newDisplayName});

      // 4. Find all group memberships for the user
      const membershipsSnapshot = await db
        .collectionGroup("members")
        .where("uid", "==", uid)
        .get();

      // 5. Update the 'displayName' in each member document
      membershipsSnapshot.forEach((doc) => {
        batch.update(doc.ref, {displayName: newDisplayName});
      });

      // 6. Find all pending join requests for the user
      const joinRequestsSnapshot = await db
        .collectionGroup("joinRequests")
        .where("uid", "==", uid)
        .get();

      // 7. Update the 'displayName' in each join request document
      joinRequestsSnapshot.forEach((doc) => {
        batch.update(doc.ref, {displayName: newDisplayName});
      });

      // 8. Commit all the updates atomically
      await batch.commit();

      return {success: true, message: "Display name updated successfully."};
    } catch (error) {
      console.error("Error updating display name for UID:", uid, error);
      throw new functions.https.HttpsError(
        "internal",
        "An error occurred while updating the display name."
      );
    }
  });
