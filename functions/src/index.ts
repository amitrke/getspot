/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {processEventRegistration} from "./processEventRegistration";
import {manageJoinRequest} from "./manageJoinRequest";
import {manageGroupMember} from "./manageGroupMember";
import {withdrawFromEvent} from "./withdrawFromEvent";
import {cleanupEndedEvents} from "./cleanupEndedEvents";


// Initialize the Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Set global options for all functions
setGlobalOptions({maxInstances: 10});

const per = processEventRegistration(db);
const mjr = manageJoinRequest(db);
const mgm = manageGroupMember(db);
const wfe = withdrawFromEvent(db);
const cee = cleanupEndedEvents(db);


/**
 * Creates a new group, generates a unique group code, and adds the creator
 * as the first member.
 *
 * This function is callable directly by an authenticated client. It performs
 * validation to ensure the user is logged in and provides the necessary data.
 * It atomically creates the group document, the initial member document for the
 * creator, and an entry in the user's group membership list.
 *
 * @param {onCall.Request} request - The request object from the client.
 * @param {object} request.auth - The authentication information for the user.
 * @param {object} request.data - The data sent from the client.
 * @param {string} request.data.name - The desired name for the new group.
 * @param {string} request.data.description - A description of the group.
 * @param {number} request.data.negativeBalanceLimit - The allowed negative
 * balance for members.
 * @returns {Promise<{groupCode: string}>} A promise that resolves with the
 * newly generated group code.
 * @throws {HttpsError} Throws an error if the user is not authenticated, if
 * the data is invalid, or if an internal error occurs.
 */
export const createGroup = onCall({region: "us-east4"}, async (request) => {
  const {customAlphabet} = await import("nanoid");
  // 1. Authentication: Ensure the user is authenticated.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to create a group.",
    );
  }

  const {uid, token} = request.auth;
  const {displayName, email} = token;

  // 2. Data Validation: Ensure the required data is present.
  const {name, description, negativeBalanceLimit} = request.data;
  if (!name || !description || typeof negativeBalanceLimit !== "number") {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with " +
      "'name', 'description', and 'negativeBalanceLimit' arguments.",
    );
  }

  // 3. Generate Unique Group Code
  // Using a custom alphabet to avoid ambiguous characters (e.g., 0/O, 1/I).
  const nanoid = customAlphabet("23456789ABCDEFGHJKLMNPQRSTUVWXYZ", 9);
  const rawCode = nanoid();
  // Format the code for readability (e.g., ABC-DEF-GHI)
  const groupCode = [
    rawCode.slice(0, 3),
    rawCode.slice(3, 6),
    rawCode.slice(6, 9),
  ].join("-");

  // 4. Create Firestore Documents Atomically
  const groupRef = db.collection("groups").doc();
  const memberRef = groupRef.collection("members").doc(uid);
  const userGroupMembershipRef = db
    .collection("userGroupMemberships")
    .doc(uid)
    .collection("groups")
    .doc(groupRef.id);

  try {
    const batch = db.batch();

    // Create the group document
    batch.set(groupRef, {
      name,
      description,
      admin: uid,
      groupCode,
      groupCodeSearch: rawCode, // Standardized version for searching
      negativeBalanceLimit,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Add the creator as the first member
    batch.set(memberRef, {
      uid,
      displayName: displayName || email || "Group Admin",
      walletBalance: 0, // Initial balance is always 0
      joinedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Add to the user's group membership list for easy lookup
    batch.set(userGroupMembershipRef, {
      groupId: groupRef.id,
      groupName: name,
      isAdmin: true,
    });

    await batch.commit();

    logger.info(`Group created successfully by user ${uid}`, {
      groupId: groupRef.id,
      groupCode,
    });

    // 5. Return the group code to the client
    return {groupCode};
  } catch (error) {
    logger.error("Error creating group:", error);
    throw new HttpsError(
      "internal",
      "An error occurred while creating the group.",
    );
  }
});

export {
  per as processEventRegistration,
  mjr as manageJoinRequest,
  mgm as manageGroupMember,
  wfe as withdrawFromEvent,
  cee as cleanupEndedEvents,
};

