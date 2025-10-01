import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const sendEventReminders = (db: admin.firestore.Firestore) =>
  onSchedule({
    schedule: "every 1 hours",
    region: "us-east4",
  }, async (event) => {
    const now = new Date();
    const twentyFourHoursFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const twentyFiveHoursFromNow = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    const eventsSnap = await db.collection("events")
      .where("eventTimestamp", ">=", twentyFourHoursFromNow)
      .where("eventTimestamp", "<", twentyFiveHoursFromNow)
      .where("status", "==", "active")
      .get();

    if (eventsSnap.empty) {
      logger.info("No events requiring reminders in the next hour.");
      return;
    }

    for (const eventDoc of eventsSnap.docs) {
      const eventData = eventDoc.data();
      const eventName = eventData.name ?? "Your Event";

      const participantsSnap = await eventDoc.ref.collection("participants")
        .where("status", "==", "confirmed")
        .get();

      if (participantsSnap.empty) {
        continue;
      }

      const userIds = participantsSnap.docs.map((doc) => doc.id);
      const usersSnap = await db.collection("users").where(admin.firestore.FieldPath.documentId(), "in", userIds).get();

      const tokens: string[] = [];
      usersSnap.forEach((userDoc) => {
        const userData = userDoc.data();
        if (userData.fcmTokens) {
          tokens.push(...userData.fcmTokens);
        }
      });

      if (tokens.length > 0) {
        const message = {
          notification: {
            title: `Reminder: ${eventName}`,
            body: "Your event is tomorrow. Don't forget!",
          },
          tokens: tokens,
        };
        await admin.messaging().sendEachForMulticast(message);
        logger.info(`Sent reminders for event ${eventDoc.id} to ${tokens.length} tokens.`);
      }
    }
  });
