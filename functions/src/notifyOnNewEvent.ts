import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const notifyOnNewEvent = (db: admin.firestore.Firestore) =>
  onDocumentCreated("events/{eventId}", async (event) => {
    const eventData = event.data?.data();
    if (!eventData) {
      logger.error("No data associated with the event creation.");
      return;
    }

    const {groupId, name: eventName} = eventData;
    if (!groupId) {
      logger.warn(`Event ${event.params.eventId} created without a groupId.`);
      return;
    }

    const groupDoc = await db.collection("groups").doc(groupId).get();
    const groupName = groupDoc.data()?.name ?? "Your Group";

    const membersSnap = await db.collection("groups").doc(groupId).collection("members").get();
    if (membersSnap.empty) {
      logger.info(`No members in group ${groupId} to notify.`);
      return;
    }

    const memberIds = membersSnap.docs.map((doc) => doc.id);

    // Fetch all users and their tokens
    const usersSnap = await db.collection("users").where(admin.firestore.FieldPath.documentId(), "in", memberIds).get();

    const tokens: string[] = [];
    usersSnap.forEach((userDoc) => {
      const userData = userDoc.data();
      if (userData.fcmTokens) {
        tokens.push(...userData.fcmTokens);
      }
    });

    if (tokens.length === 0) {
      logger.info("No FCM tokens found for any members.");
      return;
    }

    const message = {
      notification: {
        title: `New Event: ${groupName}`,
        body: `${eventName} has been scheduled. Tap to see details.`,
      },
      tokens: tokens,
    };

    try {
      await admin.messaging().sendEachForMulticast(message);
      logger.info(`Sent notification for new event to ${tokens.length} tokens.`);
    } catch (error) {
      logger.error("Error sending new event notification:", error);
    }
  });
