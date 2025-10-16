/**
 * Cloud Function: notifyOnAnnouncement
 *
 * Triggers when a new announcement is posted to a group.
 * Sends push notifications to all group members (except the author).
 *
 * Trigger: onCreate for /groups/{groupId}/announcements/{announcementId}
 */

import * as logger from "firebase-functions/logger";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

export const notifyOnAnnouncement = (db: admin.firestore.Firestore) =>
  onDocumentCreated(
    "groups/{groupId}/announcements/{announcementId}",
    async (event) => {
      const groupId = event.params.groupId;
      const announcementId = event.params.announcementId;
      const announcementData = event.data?.data();

      if (!announcementData) {
        logger.warn(`No data found for announcement ${announcementId}`);
        return;
      }

      const content = announcementData.content as string;
      const authorId = announcementData.authorId as string;
      const authorName = announcementData.authorName as string;

      logger.info(`Processing announcement notification for group ${groupId}`, {
        announcementId,
        authorId,
        authorName,
      });

      try {
        // Get group name
        const groupDoc = await db.collection("groups").doc(groupId).get();
        const groupName = groupDoc.data()?.name || "Your group";

        // Get all group members except the author
        const membersSnapshot = await db
          .collection("groups")
          .doc(groupId)
          .collection("members")
          .get();

        const memberIds = membersSnapshot.docs
          .map((doc) => doc.id)
          .filter((uid) => uid !== authorId); // Exclude author

        if (memberIds.length === 0) {
          logger.info("No members to notify (excluding author)");
          return;
        }

        logger.info(`Found ${memberIds.length} members to notify`);

        // Get FCM tokens for all members
        const userDocs = await Promise.all(
          memberIds.map((uid) => db.collection("users").doc(uid).get())
        );

        const tokens: string[] = [];
        userDocs.forEach((userDoc) => {
          const fcmTokens = userDoc.data()?.fcmTokens as string[] | undefined;
          if (fcmTokens && Array.isArray(fcmTokens)) {
            tokens.push(...fcmTokens);
          }
        });

        if (tokens.length === 0) {
          logger.info("No FCM tokens found for members");
          return;
        }

        logger.info(`Sending notifications to ${tokens.length} tokens`);

        // Truncate content for notification (max 100 chars)
        const notificationBody = content.length > 100 ?
          `${content.substring(0, 97)}...` :
          content;

        // Send notifications
        const message: admin.messaging.MulticastMessage = {
          notification: {
            title: `${groupName}: New Announcement`,
            body: notificationBody,
          },
          data: {
            type: "announcement",
            groupId: groupId,
            announcementId: announcementId,
            authorName: authorName,
          },
          tokens: tokens,
        };

        const response = await admin.messaging().sendEachForMulticast(message);

        logger.info("Announcement notifications sent", {
          successCount: response.successCount,
          failureCount: response.failureCount,
        });

        // Clean up invalid tokens
        if (response.failureCount > 0) {
          const invalidTokens: string[] = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success && resp.error) {
              const errorCode = resp.error.code;
              if (
                errorCode === "messaging/invalid-registration-token" ||
                errorCode === "messaging/registration-token-not-registered"
              ) {
                invalidTokens.push(tokens[idx]);
              }
            }
          });

          if (invalidTokens.length > 0) {
            logger.info("Removing " + invalidTokens.length + " invalid tokens");
            const batch = db.batch();
            userDocs.forEach((userDoc) => {
              const userTokens = userDoc.data()?.fcmTokens as string[] | undefined;
              if (userTokens) {
                const validTokens = userTokens.filter(
                  (token) => !invalidTokens.includes(token)
                );
                if (validTokens.length !== userTokens.length) {
                  batch.update(userDoc.ref, {fcmTokens: validTokens});
                }
              }
            });
            await batch.commit();
          }
        }
      } catch (error) {
        logger.error("Error sending announcement notifications", error);
        throw error;
      }
    }
  );
