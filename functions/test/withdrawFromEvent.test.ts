import {withdrawFromEvent} from "../src/withdrawFromEvent";
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
  callableAuth,
} from "./testHelpers";

const wrapped = testEnv.wrap(withdrawFromEvent(db));

const ADMIN_UID = "admin-uid";
const USER_UID = "user-uid";
const WAITLISTED_UID = "waitlisted-uid";

const HOUR_MS = 60 * 60 * 1000;

async function getEvent(eventId: string) {
  const doc = await db.collection("events").doc(eventId).get();
  return doc.data()!;
}

afterEach(async () => {
  await clearFirestore();
});

describe("withdrawFromEvent", () => {
  it("rejects unauthenticated callers", async () => {
    await expect(wrapped({data: {eventId: "e"}} as never)).rejects.toMatchObject({code: "unauthenticated"});
  });

  it("rejects requests missing eventId", async () => {
    await expect(wrapped({data: {}, auth: callableAuth(USER_UID)} as never)).rejects.toMatchObject({
      code: "invalid-argument",
    });
  });

  it("rejects when the event or participant record doesn't exist", async () => {
    await expect(
      wrapped({data: {eventId: "does-not-exist"}, auth: callableAuth(USER_UID)} as never)
    ).rejects.toMatchObject({code: "not-found"});
  });

  it("rejects withdrawing from a status that isn't confirmed or waitlisted", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID});
    await seedMember(groupId, USER_UID, {walletBalance: 0});
    const eventId = await seedEvent(groupId, {fee: 10});
    await seedParticipant(eventId, USER_UID, {status: "denied"});

    await expect(
      wrapped({data: {eventId}, auth: callableAuth(USER_UID)} as never)
    ).rejects.toMatchObject({code: "failed-precondition"});
  });

  describe("withdrawing from the waitlist", () => {
    it("always issues a full refund, regardless of deadline", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, USER_UID, {walletBalance: 0});
      const eventId = await seedEvent(groupId, {
        fee: 15,
        waitlistCount: 1,
        commitmentDeadline: new Date(Date.now() - HOUR_MS), // already past
      });
      await seedParticipant(eventId, USER_UID, {status: "waitlisted"});

      const result = await wrapped({data: {eventId}, auth: callableAuth(USER_UID)} as never);

      expect(result).toMatchObject({status: "success"});
      expect(await getParticipantStatus(eventId, USER_UID)).toBe("withdrawn");
      expect(await getMemberBalance(groupId, USER_UID)).toBe(15);
      expect((await getEvent(eventId)).waitlistCount).toBe(0);

      const txs = await getTransactionsFor(USER_UID, eventId);
      expect(txs).toHaveLength(1);
      expect(txs[0]).toMatchObject({type: "credit", amount: 15});
    });
  });

  describe("withdrawing while confirmed, before the commitment deadline", () => {
    it("refunds the fee and frees the spot", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, USER_UID, {walletBalance: 0});
      const eventId = await seedEvent(groupId, {
        fee: 20,
        confirmedCount: 1,
        commitmentDeadline: new Date(Date.now() + HOUR_MS), // still open
      });
      await seedParticipant(eventId, USER_UID, {status: "confirmed"});

      const result = await wrapped({data: {eventId}, auth: callableAuth(USER_UID)} as never);

      expect(result).toMatchObject({status: "success"});
      expect(await getParticipantStatus(eventId, USER_UID)).toBe("withdrawn");
      expect(await getMemberBalance(groupId, USER_UID)).toBe(20);
      expect((await getEvent(eventId)).confirmedCount).toBe(0);

      const txs = await getTransactionsFor(USER_UID, eventId);
      expect(txs).toHaveLength(1);
      expect(txs[0]).toMatchObject({type: "credit", amount: 20});
    });

    it("promotes the next waitlisted user without charging them again", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, USER_UID, {walletBalance: 0});
      await seedMember(groupId, WAITLISTED_UID, {walletBalance: 0});
      const eventId = await seedEvent(groupId, {
        fee: 20,
        confirmedCount: 1,
        waitlistCount: 1,
        commitmentDeadline: new Date(Date.now() + HOUR_MS),
      });
      await seedParticipant(eventId, USER_UID, {status: "confirmed"});
      // Fee was already collected from this member at registration time —
      // their balance reflects that, and promotion must not touch it again.
      await seedParticipant(eventId, WAITLISTED_UID, {
        status: "waitlisted",
        registeredAt: new Date(Date.now() - HOUR_MS),
      });

      await wrapped({data: {eventId}, auth: callableAuth(USER_UID)} as never);

      expect(await getParticipantStatus(eventId, WAITLISTED_UID)).toBe("confirmed");
      expect(await getMemberBalance(groupId, WAITLISTED_UID)).toBe(0);
      const finalEvent = await getEvent(eventId);
      expect(finalEvent.confirmedCount).toBe(1);
      expect(finalEvent.waitlistCount).toBe(0);
    });
  });

  describe("withdrawing while confirmed, after the commitment deadline", () => {
    it("forfeits the fee when no one is on the waitlist", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, USER_UID, {walletBalance: 0});
      const eventId = await seedEvent(groupId, {
        fee: 20,
        confirmedCount: 1,
        waitlistCount: 0,
        commitmentDeadline: new Date(Date.now() - HOUR_MS), // already past
      });
      await seedParticipant(eventId, USER_UID, {status: "confirmed"});

      const result = await wrapped({data: {eventId}, auth: callableAuth(USER_UID)} as never);

      expect(result).toMatchObject({status: "success"});
      expect(await getParticipantStatus(eventId, USER_UID)).toBe("withdrawn_penalty");
      expect(await getMemberBalance(groupId, USER_UID)).toBe(0); // no refund
      expect((await getEvent(eventId)).confirmedCount).toBe(0);
      expect(await getTransactionsFor(USER_UID, eventId)).toHaveLength(0);
    });

    it("still refunds if someone on the waitlist can take the spot", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, USER_UID, {walletBalance: 0});
      await seedMember(groupId, WAITLISTED_UID, {walletBalance: 0});
      const eventId = await seedEvent(groupId, {
        fee: 20,
        confirmedCount: 1,
        waitlistCount: 1,
        commitmentDeadline: new Date(Date.now() - HOUR_MS), // already past
      });
      await seedParticipant(eventId, USER_UID, {status: "confirmed"});
      await seedParticipant(eventId, WAITLISTED_UID, {status: "waitlisted"});

      const result = await wrapped({data: {eventId}, auth: callableAuth(USER_UID)} as never);

      expect(result).toMatchObject({status: "success"});
      expect(await getParticipantStatus(eventId, USER_UID)).toBe("withdrawn");
      expect(await getMemberBalance(groupId, USER_UID)).toBe(20);
      expect(await getParticipantStatus(eventId, WAITLISTED_UID)).toBe("confirmed");
    });
  });
});
