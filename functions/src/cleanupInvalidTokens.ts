import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Processes FCM send response and removes invalid tokens from user documents.
 *
 * This function should be called after sending notifications to clean up
 * tokens that are no longer valid (unregistered, invalid, or failed).
 *
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @param {admin.messaging.BatchResponse} response - Response from sendEachForMulticast
 * @param {string[]} tokens - Array of tokens that were sent to (same order as response)
 * @param {string[]} userIds - Array of user IDs corresponding to the tokens
 */
export async function cleanupInvalidTokens(
  db: admin.firestore.Firestore,
  response: admin.messaging.BatchResponse,
  tokens: string[],
  userIds: string[],
): Promise<void> {
  const invalidTokens: string[] = [];
  const userIdToTokensMap = new Map<string, string[]>();

  // Build a map of userId -> invalid tokens
  response.responses.forEach((resp, idx) => {
    if (!resp.success) {
      const error = resp.error;
      const errorCode = error?.code;

      // These error codes indicate the token is invalid and should be removed
      if (
        errorCode === "messaging/invalid-registration-token" ||
        errorCode === "messaging/registration-token-not-registered" ||
        errorCode === "messaging/invalid-argument"
      ) {
        const token = tokens[idx];
        const userId = userIds[idx];
        invalidTokens.push(token);

        if (!userIdToTokensMap.has(userId)) {
          userIdToTokensMap.set(userId, []);
        }
        userIdToTokensMap.get(userId)?.push(token);

        logger.info(`Invalid token detected for user ${userId}: ${errorCode}`);
      }
    }
  });

  // Remove invalid tokens from user documents
  if (invalidTokens.length > 0) {
    logger.info(`Cleaning up ${invalidTokens.length} invalid tokens`);

    const batch = db.batch();
    for (const [userId, tokensToRemove] of userIdToTokensMap.entries()) {
      const userRef = db.collection("users").doc(userId);
      batch.update(userRef, {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
      });
    }

    try {
      await batch.commit();
      logger.info(`Successfully removed ${invalidTokens.length} invalid tokens from ${userIdToTokensMap.size} users`);
    } catch (error) {
      logger.error("Error removing invalid tokens:", error);
    }
  }
}

/**
 * Sends notifications to multiple users and automatically cleans up invalid tokens.
 *
 * @param {admin.firestore.Firestore} db - Firestore database instance
 * @param {string[]} userIds - Array of user IDs to send notifications to
 * @param {Object} notificationPayload - Notification title, body, and data
 * @return {Promise<number>} Number of successfully sent notifications
 */
export async function sendNotificationWithCleanup(
  db: admin.firestore.Firestore,
  userIds: string[],
  notificationPayload: {
    title: string;
    body: string;
    data?: Record<string, string>;
  },
): Promise<number> {
  if (userIds.length === 0) {
    logger.info("No users to notify");
    return 0;
  }

  // Fetch users in batches of 10 (Firestore 'in' query limit)
  const tokens: string[] = [];
  const tokenToUserIdMap: string[] = []; // Index matches token array

  for (let i = 0; i < userIds.length; i += 10) {
    const batch = userIds.slice(i, i + 10);
    const usersSnap = await db.collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", batch)
      .get();

    usersSnap.forEach((userDoc) => {
      const userData = userDoc.data();
      // Check if user has notifications enabled (default to true if not set)
      const notificationsEnabled = userData.notificationsEnabled !== false;

      if (!notificationsEnabled) {
        logger.info(`User ${userDoc.id} has notifications disabled, skipping`);
        return; // Skip this user
      }

      const userTokens = userData.fcmTokens as string[] | undefined;
      if (userTokens && Array.isArray(userTokens)) {
        userTokens.forEach((token) => {
          tokens.push(token);
          tokenToUserIdMap.push(userDoc.id);
        });
      }
    });
  }

  if (tokens.length === 0) {
    logger.info("No FCM tokens found for any users");
    return 0;
  }

  const message: admin.messaging.MulticastMessage = {
    notification: {
      title: notificationPayload.title,
      body: notificationPayload.body,
    },
    tokens: tokens,
  };

  if (notificationPayload.data) {
    message.data = notificationPayload.data;
  }

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(`Sent notification to ${tokens.length} tokens. Success: ${response.successCount}, Failures: ${response.failureCount}`);

    // Clean up invalid tokens
    await cleanupInvalidTokens(db, response, tokens, tokenToUserIdMap);

    return response.successCount;
  } catch (error) {
    logger.error("Error sending notifications:", error);
    return 0;
  }
}
