# GetSpot: Gemini Context Pack

High-signal context for the GetSpot project. Summarizes architecture, schemas, flows, security, and next steps.

### 1. Core Purpose
- **Product:** App for small sports groups (e.g., badminton) to manage membership, events, registration, and a virtual wallet/penalty system.

### 2. Architecture
- **Frontend:** Flutter (Mobile + Web)
- **Backend:** Firebase (Auth, Firestore, Functions, Hosting)
- **Key Patterns:**
    1.  **Callable Function (`createGroup`):** Atomically creates a group, its first member, and the user's membership index.
    2.  **Write-to-Trigger (`processEventRegistration`):** Event registration triggers a Function to validate, charge the user, and update their status (confirmed/waitlisted).
    3.  **Denormalized Index:** `/userGroupMemberships/{userId}/groups/{groupId}` provides fast, efficient group lookups for the home screen.

### 3. Firestore Collections
- `users`
- `groups/{groupId}`
    - `members/{userId}`
    - `joinRequests/{userId}`
- `events/{eventId}`
    - `participants/{userId}`
- `transactions/{transactionId}`
- `userGroupMemberships/{userId}/groups/{groupId}` (Index written by Cloud Functions)

### 4. Cloud Functions (TypeScript)
- **`createGroup` (Callable):** Validates input, generates `groupCode`, and atomically writes group, member, and `userGroupMemberships` docs.
- **`processEventRegistration` (Firestore Trigger):** On participant creation, validates funds, debits the user's wallet, creates a transaction record, and sets participant status to 'confirmed' or 'waitlisted'.
- **Planned:** `manageJoinRequest`, `processWaitlist`.

### 5. Security Rules Highlights
- **Default:** Deny all.
- **`users`:** Can only read/write their own documents.
- **`groups`:** Authenticated users can read/create. Admins can update/delete.
- **`members`:** `collectionGroup` queries are restricted to a user's own membership docs (`resource.data.uid == request.auth.uid`).
- **`joinRequests`:** Admins or the requesting user can read. User can create, admin can delete.
- **`events`/`participants`:** Read access requires group membership.
- **`transactions`:** Users can only read their own. No client writes.
- **Recent Issue:** Fixed a `permission-denied` on a `collectionGroup` query by making rules query-safe. The inefficient N+1 fetch pattern on the UI has been refactored.

### 6. UI Flow: Home Screen (`_GroupList`)
- Streams the `userGroupMemberships` index for the current user.
- Fetches all group, event, and participation data in a single, efficient batch operation.
- Displays a list with status indicators (icons, colors) and wallet balance.

### 7. Known Gaps & Next Steps
- **Priority Gaps:**
    - Waitlist promotion logic is not implemented. When a user withdraws, the first user on the waitlist should be promoted.
    - No function exists to handle join requests (approve/deny).
- **Next Implementation Steps:**
    1.  Implement the join approval function (`manageJoinRequest`) to move a user from `joinRequests` to `members`.
    2.  Create a `processWaitlist` function to handle promotions.
    3.  Implement penalty and fee logic for event withdrawals (`withdrawFromEvent`).

### 8. Performance & Scaling
- **Current Bottleneck:** Resolved. The home screen now uses an efficient, denormalized query.
- **Future:** Add composite indexes for more complex event queries (e.g., `groupId` + `eventTimestamp`).

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