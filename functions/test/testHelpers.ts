import * as admin from "firebase-admin";
import functionsTest from "firebase-functions-test";

// These tests exercise real Firestore transactions (wallet debits/credits,
// waitlist promotion) against the Firestore emulator — not mocks — so the
// actual transaction logic is what's under test, not a stand-in for it.
// `npm test` (see package.json) starts the emulator via
// `firebase emulators:exec`, which sets this env var for us.
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    "FIRESTORE_EMULATOR_HOST is not set. Run these tests via `npm test`, " +
      "which starts the Firestore emulator first — running `jest` directly " +
      "will not work."
  );
}

const projectId = process.env.GCLOUD_PROJECT || "demo-getspot-test";

export const testEnv = functionsTest({projectId});

if (admin.apps.length === 0) {
  admin.initializeApp({projectId});
}

export const db = admin.firestore();

/** Wipes all Firestore emulator data so each test starts from a clean slate. */
export async function clearFirestore(): Promise<void> {
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`,
    {method: "DELETE"}
  );
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status} ${await res.text()}`);
  }
}

interface SeedGroupOptions {
  groupId?: string;
  admin?: string;
  negativeBalanceLimit?: number;
  maxEventCapacity?: number;
}

/** Seeds a /groups/{groupId} doc with sensible defaults, returns its ID. */
export async function seedGroup(options: SeedGroupOptions = {}): Promise<string> {
  const groupId = options.groupId ?? db.collection("groups").doc().id;
  await db.collection("groups").doc(groupId).set({
    name: "Test Group",
    description: "A group for tests",
    admin: options.admin ?? "admin-uid",
    groupCode: "TES-TCO-DE1",
    groupCodeSearch: "TESTCODE1",
    negativeBalanceLimit: options.negativeBalanceLimit ?? 0,
    maxEventCapacity: options.maxEventCapacity ?? 60,
    pendingJoinRequestsCount: 0,
  });
  return groupId;
}

interface SeedMemberOptions {
  walletBalance?: number;
  displayName?: string;
}

/** Seeds a /groups/{groupId}/members/{uid} doc, and its userGroupMemberships index entry. */
export async function seedMember(
  groupId: string,
  uid: string,
  options: SeedMemberOptions = {}
): Promise<void> {
  await db.collection("groups").doc(groupId).collection("members").doc(uid).set({
    uid,
    displayName: options.displayName ?? `Member ${uid}`,
    walletBalance: options.walletBalance ?? 0,
    joinedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db
    .collection("userGroupMemberships")
    .doc(uid)
    .collection("groups")
    .doc(groupId)
    .set({groupId, groupName: "Test Group", isAdmin: false});
}

interface SeedEventOptions {
  eventId?: string;
  fee?: number;
  confirmedCount?: number;
  waitlistCount?: number;
  maxParticipants?: number;
  status?: string;
  commitmentDeadline?: Date;
  eventTimestamp?: Date;
}

/** Seeds an /events/{eventId} doc, returns its ID. */
export async function seedEvent(groupId: string, options: SeedEventOptions = {}): Promise<string> {
  const eventId = options.eventId ?? db.collection("events").doc().id;
  await db
    .collection("events")
    .doc(eventId)
    .set({
      groupId,
      name: "Test Event",
      fee: options.fee ?? 0,
      confirmedCount: options.confirmedCount ?? 0,
      waitlistCount: options.waitlistCount ?? 0,
      maxParticipants: options.maxParticipants ?? 10,
      status: options.status ?? "active",
      eventTimestamp: admin.firestore.Timestamp.fromDate(
        options.eventTimestamp ?? new Date(Date.now() + 24 * 60 * 60 * 1000)
      ),
      commitmentDeadline: admin.firestore.Timestamp.fromDate(
        options.commitmentDeadline ?? new Date(Date.now() + 12 * 60 * 60 * 1000)
      ),
    });
  return eventId;
}

interface SeedParticipantOptions {
  status?: string;
  registeredAt?: Date;
}

/** Seeds an /events/{eventId}/participants/{uid} doc. */
export async function seedParticipant(
  eventId: string,
  uid: string,
  options: SeedParticipantOptions = {}
): Promise<void> {
  await db
    .collection("events")
    .doc(eventId)
    .collection("participants")
    .doc(uid)
    .set({
      uid,
      displayName: `Member ${uid}`,
      status: options.status ?? "requested",
      registeredAt: admin.firestore.Timestamp.fromDate(options.registeredAt ?? new Date()),
    });
}

export async function getMemberBalance(groupId: string, uid: string): Promise<number> {
  const doc = await db.collection("groups").doc(groupId).collection("members").doc(uid).get();
  return doc.data()?.walletBalance ?? null;
}

export async function getParticipantStatus(eventId: string, uid: string): Promise<string | undefined> {
  const doc = await db.collection("events").doc(eventId).collection("participants").doc(uid).get();
  return doc.data()?.status;
}

export async function getTransactionsFor(uid: string, eventId?: string) {
  let query: admin.firestore.Query = db.collection("transactions").where("uid", "==", uid);
  if (eventId) {
    query = query.where("eventId", "==", eventId);
  }
  const snap = await query.get();
  return snap.docs.map((d) => d.data());
}

/** Builds a fake auth context for a CallableRequest, for use with testEnv.wrap(). */
export function callableAuth(uid: string) {
  return {uid, token: {} as admin.auth.DecodedIdToken};
}
