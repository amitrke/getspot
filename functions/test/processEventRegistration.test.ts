import {processEventRegistration} from "../src/processEventRegistration";
import {
  db,
  testEnv,
  clearFirestore,
  seedGroup,
  seedMember,
  seedEvent,
  seedParticipant,
  getMemberBalance,
  getParticipantStatus,
  getTransactionsFor,
} from "./testHelpers";

const wrapped = testEnv.wrap(processEventRegistration(db));

const ADMIN_UID = "admin-uid";
const USER_UID = "user-uid";

async function getEvent(eventId: string) {
  const doc = await db.collection("events").doc(eventId).get();
  return doc.data()!;
}

/**
 * Builds the fake CloudEvent the onDocumentWritten trigger receives.
 * testEnv.wrap() builds the actual before/after DocumentSnapshots itself
 * from plain data objects — pass `{}` for a snapshot that doesn't exist
 * (e.g. `before` on a create). Firestore state for the event/group/member
 * docs the handler's own transaction reads is real emulator data, seeded
 * separately — this only fakes the trigger envelope.
 */
function participantWriteEvent(
  eventId: string,
  userId: string,
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined
) {
  return {
    data: {
      before: before ?? {},
      after: after ?? {},
    },
    params: {eventId, userId},
  } as never;
}

afterEach(async () => {
  await clearFirestore();
});

describe("processEventRegistration", () => {
  it("confirms and debits the wallet when a spot is open and funds are sufficient", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID, negativeBalanceLimit: 0});
    await seedMember(groupId, USER_UID, {walletBalance: 100});
    const eventId = await seedEvent(groupId, {fee: 20, confirmedCount: 0, maxParticipants: 10});
    await seedParticipant(eventId, USER_UID, {status: "requested"});

    await wrapped(participantWriteEvent(eventId, USER_UID, undefined, {status: "requested"}));

    expect(await getParticipantStatus(eventId, USER_UID)).toBe("confirmed");
    expect(await getMemberBalance(groupId, USER_UID)).toBe(80);
    expect((await getEvent(eventId)).confirmedCount).toBe(1);

    const txs = await getTransactionsFor(USER_UID, eventId);
    expect(txs).toHaveLength(1);
    expect(txs[0]).toMatchObject({type: "debit", amount: 20});
  });

  it("waitlists but still charges the fee when the event is full", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID, negativeBalanceLimit: 0});
    await seedMember(groupId, USER_UID, {walletBalance: 100});
    const eventId = await seedEvent(groupId, {fee: 20, confirmedCount: 5, maxParticipants: 5, waitlistCount: 0});
    await seedParticipant(eventId, USER_UID, {status: "requested"});

    await wrapped(participantWriteEvent(eventId, USER_UID, undefined, {status: "requested"}));

    expect(await getParticipantStatus(eventId, USER_UID)).toBe("waitlisted");
    expect(await getMemberBalance(groupId, USER_UID)).toBe(80); // still charged up front
    const finalEvent = await getEvent(eventId);
    expect(finalEvent.confirmedCount).toBe(5);
    expect(finalEvent.waitlistCount).toBe(1);
  });

  it("denies without touching the wallet when funds are insufficient", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID, negativeBalanceLimit: 0});
    await seedMember(groupId, USER_UID, {walletBalance: 5});
    const eventId = await seedEvent(groupId, {fee: 20, confirmedCount: 0, maxParticipants: 10});
    await seedParticipant(eventId, USER_UID, {status: "requested"});

    await wrapped(participantWriteEvent(eventId, USER_UID, undefined, {status: "requested"}));

    expect(await getParticipantStatus(eventId, USER_UID)).toBe("denied");
    expect(await getMemberBalance(groupId, USER_UID)).toBe(5); // unchanged
    expect((await getEvent(eventId)).confirmedCount).toBe(0);
    expect(await getTransactionsFor(USER_UID, eventId)).toHaveLength(0);
  });

  it("allows registration exactly at the negativeBalanceLimit boundary (balance + limit == fee)", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID, negativeBalanceLimit: 20});
    await seedMember(groupId, USER_UID, {walletBalance: 0});
    const eventId = await seedEvent(groupId, {fee: 20, confirmedCount: 0, maxParticipants: 10});
    await seedParticipant(eventId, USER_UID, {status: "requested"});

    await wrapped(participantWriteEvent(eventId, USER_UID, undefined, {status: "requested"}));

    expect(await getParticipantStatus(eventId, USER_UID)).toBe("confirmed");
    expect(await getMemberBalance(groupId, USER_UID)).toBe(-20);
  });

  it("denies when one dollar short of the negativeBalanceLimit boundary", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID, negativeBalanceLimit: 19});
    await seedMember(groupId, USER_UID, {walletBalance: 0});
    const eventId = await seedEvent(groupId, {fee: 20, confirmedCount: 0, maxParticipants: 10});
    await seedParticipant(eventId, USER_UID, {status: "requested"});

    await wrapped(participantWriteEvent(eventId, USER_UID, undefined, {status: "requested"}));

    expect(await getParticipantStatus(eventId, USER_UID)).toBe("denied");
    expect(await getMemberBalance(groupId, USER_UID)).toBe(0);
  });

  it("does nothing when the write isn't a transition into 'requested'", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID});
    await seedMember(groupId, USER_UID, {walletBalance: 100});
    const eventId = await seedEvent(groupId, {fee: 20, confirmedCount: 0, maxParticipants: 10});
    await seedParticipant(eventId, USER_UID, {status: "confirmed"});

    // Some other write set the status directly to 'confirmed' (not via the
    // requested->processed flow) — the guard clause should short-circuit.
    await wrapped(participantWriteEvent(eventId, USER_UID, {status: "requested"}, {status: "confirmed"}));

    expect(await getMemberBalance(groupId, USER_UID)).toBe(100); // untouched
    expect((await getEvent(eventId)).confirmedCount).toBe(0);
  });

  it("does nothing when the status was already 'requested' (avoids reprocessing)", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID});
    await seedMember(groupId, USER_UID, {walletBalance: 100});
    const eventId = await seedEvent(groupId, {fee: 20, confirmedCount: 0, maxParticipants: 10});
    await seedParticipant(eventId, USER_UID, {status: "requested"});

    await wrapped(
      participantWriteEvent(eventId, USER_UID, {status: "requested"}, {status: "requested"})
    );

    expect(await getMemberBalance(groupId, USER_UID)).toBe(100); // untouched
  });

  it("marks the participant denied if the transaction fails (e.g. event missing)", async () => {
    // No group/event seeded — only the participant doc exists, mirroring a
    // dangling/corrupt write the transaction can't resolve.
    const eventId = "missing-event";
    await db.collection("events").doc(eventId).collection("participants").doc(USER_UID).set({
      uid: USER_UID,
      status: "requested",
    });

    await wrapped(participantWriteEvent(eventId, USER_UID, undefined, {status: "requested"}));

    expect(await getParticipantStatus(eventId, USER_UID)).toBe("denied");
  });
});
