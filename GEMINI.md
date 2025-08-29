# GetSpot: Gemini Context Pack

High-signal context for the GetSpot project. Summarizes architecture, schemas, flows, security, and next steps.

### 1. Core Purpose
- **Product:** App for small sports groups (e.g., badminton) to manage membership, events, registration, and a virtual wallet/penalty system.

### 2. Architecture
- **Frontend:** Flutter (Mobile + Web)
- **Backend:** Firebase (Auth, Firestore, Functions, Hosting)
- **Key Patterns:**
    1.  **Callable Function (`createGroup`):** Atomic writes for group creation.
    2.  **Write-to-Trigger:** Event registration triggers a Function to validate and update status. (Partially implemented).
    3.  **Denormalized Index (Planned):** `/userGroupMemberships/{userId}/groups/{groupId}` for fast group lookups, avoiding expensive `collectionGroup` queries.

### 3. Firestore Collections
- `users`
- `groups/{groupId}`
    - `members/{userId}`
    - `joinRequests/{userId}`
- `events/{eventId}`
    - `participants/{userId}`
- `transactions/{transactionId}`
- `userGroupMemberships/{userId}/groups/{groupId}` (Index, not yet written by Functions)

### 4. Cloud Functions (TypeScript)
- **`createGroup` (Callable):** Validates input, generates `groupCode`, writes group and initial member docs atomically.
- **Missing/Planned:** `manageJoinRequest`, `processEventRegistration`, `processWaitlist`.

### 5. Security Rules Highlights
- **Default:** Deny all.
- **`users`:** Can only read/write their own documents.
- **`groups`:** Authenticated users can read/create. Admins can update/delete.
- **`members`:** `collectionGroup` queries are restricted to a user's own membership docs (`resource.data.uid == request.auth.uid`).
- **`joinRequests`:** Admins or the requesting user can read. User can create, admin can delete.
- **`events`/`participants`:** Read access requires group membership.
- **`transactions`:** Users can only read their own. No client writes.
- **Recent Issue:** Fixed a `permission-denied` on a `collectionGroup` query by making rules query-safe. The UI still uses an inefficient N+1 fetch pattern.

### 6. UI Flow: Home Screen (`_GroupList`)
- Streams `userGroupMemberships` to get the user's groups.
- For each group, fetches details, the next event, and the user's participation status.
- Displays a list with status indicators (icons, colors) and wallet balance.

### 7. Known Gaps & Next Steps
- **Priority Gaps:**
    - `createGroup` does not write to the `userGroupMemberships` index.
    - Event lifecycle functions (fee deduction, waitlist, penalties) are not implemented.
    - Wallet balance checks and transaction pipelines are missing.
- **Next Implementation Steps:**
    1.  Implement the join approval function (move from `joinRequests` to `members`).
    2.  Update `createGroup` to populate the `userGroupMemberships` index.
    3.  Refactor the HomeScreen to use the `userGroupMemberships` index instead of the N+1 fetch.
    4.  Add the `onCreate` trigger for `/participants` to handle registration logic.
    5.  Create a `transaction` Function for financial operations.

### 8. Performance & Scaling
- **Current Bottleneck:** Group loading is O(M) fetches (M=memberships). Must migrate to the denormalized index.
- **Future:** Add composite indexes for event queries (e.g., `groupId` + `eventTimestamp`).

### 9. Quick Reference: Key Fields
- **Group:** `name`, `description`, `admin`, `groupCode`, `negativeBalanceLimit`
- **Member:** `uid`, `displayName`, `walletBalance`, `joinedAt`
- **Event:** `name`, `groupId`, `eventTimestamp`, `fee`, `maxParticipants`
- **Participant:** `uid`, `status`, `paymentStatus`, `registeredAt`
- **UserGroupMembership:** `groupId`, `groupName`, `isAdmin`

### 10. Gemini Prompting Guide
- **Minimal Prompt Template:**
  `Context: GetSpot (Flutter/Firebase). Pain point: <describe>. Task: <describe>. Constraints: <constraints>. Output: <format>.`
- **Example - Refactor UI:**
  `Task: Refactor Dart home screen stream to use the userGroupMemberships index, then fetch group docs in a single Future.wait batch.`
- **Example - Harden Rules:**
  `Task: Propose a rule for userGroupMemberships allowing read only where request.auth.uid == uid and writes only via Functions.`