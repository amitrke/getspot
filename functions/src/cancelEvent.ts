
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {HttpsError} from "firebase-functions/v1/https";

export const cancelEvent = (db: admin.firestore.Firestore) => functions.https.onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const {eventId} = request.data;
  if (!eventId) {
    throw new HttpsError("invalid-argument", "Event ID is required.");
  }

  const eventRef = db.collection("events").doc(eventId);

  try {
    const eventDoc = await eventRef.get();
    if (!eventDoc.exists) {
      throw new HttpsError("not-found", "Event not found.");
    }

    const eventData = eventDoc.data()!;
    const groupId = eventData.groupId;
    const groupRef = db.collection("groups").doc(groupId);
    const groupDoc = await groupRef.get();

    if (!groupDoc.exists) {
      throw new HttpsError("not-found", "Group not found.");
    }

    const groupData = groupDoc.data()!;
    if (groupData.admin !== request.auth.uid) {
      throw new HttpsError("permission-denied", "User is not the group admin.");
    }

    const participantsSnapshot = await eventRef.collection("participants").get();

    await db.runTransaction(async (transaction) => {
      participantsSnapshot.forEach((participantDoc) => {
        const participantData = participantDoc.data();
        const memberRef = db.collection("groups").doc(groupId).collection("members").doc(participantData.uid);

        transaction.update(memberRef, {
          walletBalance: admin.firestore.FieldValue.increment(eventData.fee),
        });

        const transactionRef = db.collection("transactions").doc();
        transaction.set(transactionRef, {
          uid: participantData.uid,
          groupId: groupId,
          eventId: eventId,
          type: "credit",
          amount: eventData.fee,
          description: `Refund for cancelled event: ${eventData.name}`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      transaction.update(eventRef, {status: "cancelled"});
    });

    // Post-transaction notifications
    const userIds = participantsSnapshot.docs.map((doc) => doc.data().uid);
    if (userIds.length > 0) {
      const usersSnapshot = await db.collection("users").where(admin.firestore.FieldPath.documentId(), "in", userIds).get();
      const tokens: string[] = [];
      usersSnapshot.forEach((userDoc) => {
        const userData = userDoc.data();
        if (userData.fcmTokens) {
          tokens.push(...userData.fcmTokens);
        }
      });

      if (tokens.length > 0) {
        const message = {
          notification: {
            title: "Event Cancelled",
            body: `The event '${eventData.name}' has been cancelled. Your wallet has been refunded.`,
          },
          tokens: tokens,
        };
        await admin.messaging().sendEachForMulticast(message);
      }
    }


    return {status: "success", message: "Event cancelled and all participants refunded."};
  } catch (error) {
    functions.logger.error("Error cancelling event:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "An internal error occurred.");
  }
});
