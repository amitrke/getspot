import {manageGroupMember} from "../src/manageGroupMember";
import {
  db,
  testEnv,
  clearFirestore,
  seedGroup,
  seedMember,
  getMemberBalance,
  getTransactionsFor,
  callableAuth,
} from "./testHelpers";

const wrapped = testEnv.wrap(manageGroupMember(db));

const ADMIN_UID = "admin-uid";
const MEMBER_UID = "member-uid";

afterEach(async () => {
  await clearFirestore();
});

describe("manageGroupMember", () => {
  it("rejects unauthenticated callers", async () => {
    await expect(
      wrapped({data: {groupId: "g", targetUserId: "u", action: "remove"}} as never)
    ).rejects.toMatchObject({code: "unauthenticated"});
  });

  it("rejects requests missing required parameters", async () => {
    await expect(
      wrapped({data: {groupId: "g"}, auth: callableAuth(ADMIN_UID)} as never)
    ).rejects.toMatchObject({code: "invalid-argument"});
  });

  describe("credit", () => {
    it("rejects a non-admin caller", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, MEMBER_UID, {walletBalance: 0});

      await expect(
        wrapped({
          data: {groupId, targetUserId: MEMBER_UID, action: "credit", amount: 10},
          auth: callableAuth(MEMBER_UID),
        } as never)
      ).rejects.toMatchObject({code: "permission-denied"});
    });

    it("rejects a non-positive amount", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, MEMBER_UID, {walletBalance: 0});

      await expect(
        wrapped({
          data: {groupId, targetUserId: MEMBER_UID, action: "credit", amount: 0},
          auth: callableAuth(ADMIN_UID),
        } as never)
      ).rejects.toMatchObject({code: "invalid-argument"});
    });

    it("increases the member's wallet balance and logs a transaction", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, MEMBER_UID, {walletBalance: 15});

      const result = await wrapped({
        data: {groupId, targetUserId: MEMBER_UID, action: "credit", amount: 25, description: "Cash top-up"},
        auth: callableAuth(ADMIN_UID),
      } as never);

      expect(result).toMatchObject({status: "credited", balance: 40});
      expect(await getMemberBalance(groupId, MEMBER_UID)).toBe(40);

      const txs = await getTransactionsFor(MEMBER_UID);
      expect(txs).toHaveLength(1);
      expect(txs[0]).toMatchObject({type: "credit", amount: 25, groupId, description: "Cash top-up"});
    });
  });

  describe("remove (admin-initiated)", () => {
    it("rejects a non-admin caller", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, MEMBER_UID, {walletBalance: 0});

      await expect(
        wrapped({
          data: {groupId, targetUserId: MEMBER_UID, action: "remove"},
          auth: callableAuth(MEMBER_UID),
        } as never)
      ).rejects.toMatchObject({code: "permission-denied"});
    });

    it("refuses to remove the group admin", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, ADMIN_UID, {walletBalance: 0});

      await expect(
        wrapped({
          data: {groupId, targetUserId: ADMIN_UID, action: "remove"},
          auth: callableAuth(ADMIN_UID),
        } as never)
      ).rejects.toMatchObject({code: "failed-precondition"});
    });

    it("refuses to remove a member with a non-zero wallet balance", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, MEMBER_UID, {walletBalance: 5});

      await expect(
        wrapped({
          data: {groupId, targetUserId: MEMBER_UID, action: "remove"},
          auth: callableAuth(ADMIN_UID),
        } as never)
      ).rejects.toMatchObject({code: "failed-precondition"});

      const memberDoc = await db.collection("groups").doc(groupId).collection("members").doc(MEMBER_UID).get();
      expect(memberDoc.exists).toBe(true);
    });

    it("removes an eligible member and their membership index entry", async () => {
      const groupId = await seedGroup({admin: ADMIN_UID});
      await seedMember(groupId, MEMBER_UID, {walletBalance: 0});

      const result = await wrapped({
        data: {groupId, targetUserId: MEMBER_UID, action: "remove"},
        auth: callableAuth(ADMIN_UID),
      } as never);

      expect(result).toMatchObject({status: "removed"});
      const memberDoc = await db.collection("groups").doc(groupId).collection("members").doc(MEMBER_UID).get();
      expect(memberDoc.exists).toBe(false);
      const indexDoc = await db
        .collection("userGroupMemberships")
        .doc(MEMBER_UID)
        .collection("groups")
        .doc(groupId)
        .get();
      expect(indexDoc.exists).toBe(false);
    });
  });

  it("rejects an unsupported action", async () => {
    const groupId = await seedGroup({admin: ADMIN_UID});
    await seedMember(groupId, MEMBER_UID, {walletBalance: 0});

    await expect(
      wrapped({
        data: {groupId, targetUserId: MEMBER_UID, action: "not-a-real-action"},
        auth: callableAuth(ADMIN_UID),
      } as never)
    ).rejects.toMatchObject({code: "invalid-argument"});
  });
});
