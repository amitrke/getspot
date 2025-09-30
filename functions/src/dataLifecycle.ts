import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";

const db = admin.firestore();
const storage = admin.storage();
const bucket = storage.bucket("getspot01.firebasestorage.app");

/**
 * A scheduled function that runs daily to manage the data lifecycle.
 * It archives old data from Firestore to Cloud Storage.
 */
export const runDataLifecycleManagement = onSchedule(
  "every 24 hours",
  async () => {
    functions.logger.info("Starting data lifecycle management job.");

    try {
      // Each of these tasks will be implemented separately.
      await archiveOldEvents();
      await archiveOldTransactions();
      // await archiveInactiveGroups();
      // await archiveInactiveUsers();
      await deleteOldJoinRequests();

      functions.logger.info("Data lifecycle management job completed successfully.");
    } catch (error) {
      functions.logger.error("Error running data lifecycle management job:", error);
    }
  },
);

// Placeholder for the actual implementation functions
// TODO: Implement the functions below.

/**
 * Archives events that are older than 3 months.
 */
async function archiveOldEvents() {
  functions.logger.info("Starting archiveOldEvents job.");

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
    batch.delete(doc.ref);
    for (const pDoc of participantsSnapshot.docs) {
      batch.delete(pDoc.ref);
    }
    await batch.commit();
    functions.logger.info(`Successfully deleted event ${eventId} from Firestore.`);
  }

  functions.logger.info(`Archived ${snapshot.size} events.`);
}

/**
 * Archives transactions that are older than 3 months.
 */
async function archiveOldTransactions() {
  functions.logger.info("Starting archiveOldTransactions job.");

  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - 3);

  const oldTransactionsQuery = db.collection("transactions").where("timestamp", "<", cutoff);

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

// TODO: Add archiveInactiveGroups implementation
// TODO: Add archiveInactiveUsers implementation

/**
 * Deletes join requests that were denied more than 7 days ago.
 */
async function deleteOldJoinRequests() {
  functions.logger.info("Starting deleteOldJoinRequests job.");

  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 7);

  const oldRequestsQuery = db
    .collectionGroup("joinRequests")
    .where("status", "==", "denied")
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
