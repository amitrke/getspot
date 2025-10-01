import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";

const ARCHIVE_BUCKET_NAME = "getspot01.firebasestorage.app";

/**
 * A scheduled function that runs daily to manage the data lifecycle.
 * It archives old data from Firestore to Cloud Storage.
 */
export const runDataLifecycleManagement = onSchedule(
  {schedule: "every 24 hours", region: "us-east4"},
  async () => {
    functions.logger.info("Starting data lifecycle management job.");

    const db = admin.firestore();

    try {
      // Each of these tasks will be implemented separately.
      await archiveOldEvents(db);
      await archiveOldTransactions(db);
      await archiveInactiveGroups(db);
      await archiveInactiveUsers(db);
      await deleteOldJoinRequests(db);

      functions.logger.info("Data lifecycle management job completed successfully.");
    } catch (error) {
      functions.logger.error("Error running data lifecycle management job:", error);
    }
  },
);

/**
 * Archives events that are older than 3 months.
 * @param {admin.firestore.Firestore} db Firestore instance.
 * @return {Promise<void>} Resolves when archival completes.
 */
async function archiveOldEvents(db: admin.firestore.Firestore) {
  functions.logger.info("Starting archiveOldEvents job.");

  const bucket = admin.storage().bucket(ARCHIVE_BUCKET_NAME);

  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - 3);

  const oldEventsQuery = db.collection("events").where("eventTimestamp", "<", cutoff);

  const snapshot = await oldEventsQuery.get();
  if (snapshot.empty) {
    functions.logger.info("No old events to archive.");
    return;
  }

  for (const doc of snapshot.docs) {
    const eventId = doc.id;
    const eventData = doc.data();
    functions.logger.info(`Processing event ${eventId}...`);

    const participantsSnapshot = await doc.ref.collection("participants").get();
    const participantsData = participantsSnapshot.docs.map((p) => ({
      id: p.id,
      ...p.data(),
    }));

    const archiveData = {
      eventId,
      archivedAt: new Date().toISOString(),
      eventData,
      participants: participantsData,
    };

    // Save to Cloud Storage
    const fileName = `archive/events/${eventId}.json`;
    const file = bucket.file(fileName);
    await file.save(JSON.stringify(archiveData, null, 2), {
      contentType: "application/json",
    });

    functions.logger.info(`Successfully archived ${fileName} to GCS.`);

    // Delete from Firestore
    const batch = db.batch();
    for (const pDoc of participantsSnapshot.docs) {
      batch.delete(pDoc.ref);
    }
    batch.delete(doc.ref);
    await batch.commit();
    functions.logger.info(`Successfully deleted event ${eventId} from Firestore.`);
  }

  functions.logger.info(`Archived ${snapshot.size} events.`);
}

/**
 * Archives transactions that are older than 3 months.
 * @param {admin.firestore.Firestore} db Firestore instance.
 * @return {Promise<void>} Resolves when archival completes.
 */
async function archiveOldTransactions(db: admin.firestore.Firestore) {
  functions.logger.info("Starting archiveOldTransactions job.");

  const bucket = admin.storage().bucket(ARCHIVE_BUCKET_NAME);

  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - 3);

  const oldTransactionsQuery = db.collection("transactions").where("createdAt", "<", cutoff);

  const snapshot = await oldTransactionsQuery.get();
  if (snapshot.empty) {
    functions.logger.info("No old transactions to archive.");
    return;
  }

  for (const doc of snapshot.docs) {
    const transactionId = doc.id;
    const transactionData = doc.data();
    functions.logger.info(`Processing transaction ${transactionId}...`);

    const archiveData = {
      transactionId,
      archivedAt: new Date().toISOString(),
      ...transactionData,
    };

    // Save to Cloud Storage
    const fileName = `archive/transactions/${transactionId}.json`;
    const file = bucket.file(fileName);
    await file.save(JSON.stringify(archiveData, null, 2), {
      contentType: "application/json",
    });

    functions.logger.info(`Successfully archived ${fileName} to GCS.`);

    // Delete from Firestore
    await doc.ref.delete();
    functions.logger.info(`Successfully deleted transaction ${transactionId} from Firestore.`);
  }

  functions.logger.info(`Archived ${snapshot.size} transactions.`);
}

/**
 * Archives groups that have been inactive for 3 months.
 * @param {admin.firestore.Firestore} db Firestore instance.
 */
async function archiveInactiveGroups(db: admin.firestore.Firestore) {
  functions.logger.info("Starting archiveInactiveGroups job.");
  const bucket = admin.storage().bucket(ARCHIVE_BUCKET_NAME);
  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - 3);

  const groupsSnapshot = await db.collection("groups").get();
  if (groupsSnapshot.empty) {
    functions.logger.info("No groups to process.");
    return;
  }

  let archivedCount = 0;
  for (const groupDoc of groupsSnapshot.docs) {
    const groupId = groupDoc.id;

    const recentEventsQuery = db.collection("events")
      .where("groupId", "==", groupId)
      .where("createdAt", ">", cutoff)
      .limit(1);
    const recentEventsSnapshot = await recentEventsQuery.get();
    if (!recentEventsSnapshot.empty) continue;

    const recentMembersQuery = groupDoc.ref.collection("members")
      .where("joinedAt", ">", cutoff)
      .limit(1);
    const recentMembersSnapshot = await recentMembersQuery.get();
    if (!recentMembersSnapshot.empty) continue;

    functions.logger.info(`Archiving inactive group ${groupId}...`);

    const groupData = groupDoc.data();
    const membersSnapshot = await groupDoc.ref.collection("members").get();
    const membersData = membersSnapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    const announcementsSnapshot = await groupDoc.ref.collection("announcements").get();
    const announcementsData = announcementsSnapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));

    const archiveData = {
      groupId,
      archivedAt: new Date().toISOString(),
      groupData,
      members: membersData,
      announcements: announcementsData,
    };

    const fileName = `archive/groups/${groupId}.json`;
    await bucket.file(fileName).save(JSON.stringify(archiveData, null, 2), {contentType: "application/json"});
    functions.logger.info(`Successfully archived ${fileName} to GCS.`);

    await deleteSubCollection(groupDoc.ref.collection("members"));
    await deleteSubCollection(groupDoc.ref.collection("announcements"));
    await deleteSubCollection(groupDoc.ref.collection("joinRequests"));

    for (const member of membersData) {
      if ((member as any).uid) {
        await db.collection("userGroupMemberships").doc((member as any).uid).collection("groups").doc(groupId).delete();
      }
    }

    await groupDoc.ref.delete();
    functions.logger.info(`Successfully deleted group ${groupId} from Firestore.`);
    archivedCount++;
  }
  functions.logger.info(`Archived ${archivedCount} inactive groups.`);
}

/**
 * Archives users who have been inactive for 3 months.
 * @param {admin.firestore.Firestore} db Firestore instance.
 */
async function archiveInactiveUsers(db: admin.firestore.Firestore) {
  functions.logger.info("Starting archiveInactiveUsers job.");
  const bucket = admin.storage().bucket(ARCHIVE_BUCKET_NAME);
  const auth = admin.auth();
  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - 3);

  let archivedCount = 0;
  let pageToken: string | undefined = undefined;

  do {
    const listUsersResult = await auth.listUsers(1000, pageToken);
    pageToken = listUsersResult.pageToken;

    const inactiveUsers = listUsersResult.users.filter((user) => {
      const lastSignInTime = new Date(user.metadata.lastSignInTime);
      return lastSignInTime < cutoff;
    });

    for (const user of inactiveUsers) {
      const userId = user.uid;
      functions.logger.info(`Archiving inactive user ${userId}...`);

      const userDocRef = db.collection("users").doc(userId);
      const userDoc = await userDocRef.get();
      const userData = userDoc.exists ? userDoc.data() : null;

      const membershipsRef = db.collection("userGroupMemberships").doc(userId).collection("groups");
      const membershipsSnapshot = await membershipsRef.get();
      const membershipsData = membershipsSnapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));

      const archiveData = {
        userId,
        authData: user.toJSON(),
        archivedAt: new Date().toISOString(),
        firestoreData: userData,
        groupMemberships: membershipsData,
      };

      const fileName = `archive/users/${userId}.json`;
      await bucket.file(fileName).save(JSON.stringify(archiveData, null, 2), {contentType: "application/json"});
      functions.logger.info(`Successfully archived ${fileName} to GCS.`);

      if (userDoc.exists) {
        await userDocRef.delete();
      }
      await deleteSubCollection(membershipsRef);

      functions.logger.info(`Successfully deleted user ${userId} data from Firestore.`);
      archivedCount++;
    }
  } while (pageToken);

  functions.logger.info(`Archived ${archivedCount} inactive users.`);
}

/**
 * Deletes join requests that were resolved more than 7 days ago.
 * @param {admin.firestore.Firestore} db Firestore instance.
 * @return {Promise<void>} Resolves when cleanup completes.
 */
async function deleteOldJoinRequests(db: admin.firestore.Firestore) {
  functions.logger.info("Starting deleteOldJoinRequests job.");

  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 7);

  const oldRequestsQuery = db
    .collectionGroup("joinRequests")
    .where("resolvedAt", "<", cutoff);

  const snapshot = await oldRequestsQuery.get();
  if (snapshot.empty) {
    functions.logger.info("No old join requests to delete.");
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  functions.logger.info(`Deleted ${snapshot.size} old join requests.`);
}

/**
 * Deletes all documents in a subcollection in batches.
 * @param {admin.firestore.CollectionReference} collectionRef The subcollection to delete.
 */
async function deleteSubCollection(collectionRef: admin.firestore.CollectionReference) {
  const snapshot = await collectionRef.limit(500).get();
  if (snapshot.empty) return;

  const batch = collectionRef.firestore.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  if (snapshot.size >= 500) {
    await deleteSubCollection(collectionRef);
  }
}
