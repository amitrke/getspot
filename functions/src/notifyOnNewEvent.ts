import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {sendNotificationWithCleanup} from "./cleanupInvalidTokens";

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

    // Send notifications with automatic token cleanup
    await sendNotificationWithCleanup(db, memberIds, {
      title: `New Event: ${groupName}`,
      body: `${eventName} has been scheduled. Tap to see details.`,
      data: {
        type: "new_event",
        eventId: event.params.eventId,
        groupId: groupId,
      },
    });
  });
