# GetSpot: Gemini Context Pack

High-signal context for the GetSpot project. Summarizes architecture, schemas, flows, security, and next steps.

### 1. Core Purpose
- **Product:** App for small sports groups (e.g., badminton) to manage membership, events, registration, and a virtual wallet/penalty system.

### 2. Architecture
- **Frontend:** Flutter (Mobile + Web)
- **Backend:** Firebase (Auth, Firestore, Functions, Hosting)
- **Key Patterns:**
    1.  **Callable Function (`createGroup`, `manageJoinRequest`):** Client-invoked functions for atomic, secure backend operations.
    2.  **Write-to-Trigger (`processEventRegistration`):** Firestore document changes trigger server-side logic for event sign-ups.
    3.  **Transactional Event & Wallet Management:** Cloud Functions (`withdrawFromEvent`, `processWaitlist`) ensure that event withdrawals, refunds, penalties, and waitlist promotions occur as a single, all-or-nothing operation.
    4.  **Denormalized Index:** `/userGroupMemberships/{userId}/groups/{groupId}` provides fast, efficient group lookups for the home screen.

### 3. Firestore Collections
- `users`
- `groups/{groupId}`
    - `members/{userId}`
    - `joinRequests/{userId}`
- `events/{eventId}`
    - `participants/{userId}`
- `transactions/{transactionId}`
- `userGroupMemberships/{userId}/groups/{groupId}` (Index written by Cloud Functions)

### 4. Cloud Functions (TypeScript) - Core Features Implemented
- **`createGroup` (Callable):** Validates input, generates `groupCode`, and atomically writes group, member, and `userGroupMemberships` docs.
- **`processEventRegistration` (Firestore Trigger):** On participant creation, validates funds, debits the user's wallet, creates a transaction record, and sets participant status to 'confirmed' or 'waitlisted'.
- **`manageJoinRequest` (Callable):** Allows a group admin to approve or deny a user's request to join a group. Approval adds the user to the `members` subcollection.
- **`withdrawFromEvent` (Callable):** Allows a user to withdraw from an event. It processes refunds or penalties based on the event's `commitmentDeadline` and whether a waitlisted user can take the spot.
- **`processWaitlist` (Internal):** Triggered by `withdrawFromEvent`, this function automatically promotes the first eligible user from the waitlist to "confirmed" status when a spot opens up.

### 5. Security Rules Highlights
- **Default:** Deny all.
- **`users`:** Can only read/write their own documents.
- **`groups`:** Authenticated users can read/create. Admins can update/delete.
- **`members`:** `collectionGroup` queries are restricted to a user's own membership docs (`resource.data.uid == request.auth.uid`).
- **`joinRequests`:** Admins or the requesting user can read. User can create, admin can delete.
- **`events`/`participants`:** Read access requires group membership.
- **`transactions`:** Users can only read their own. No client writes.
- **Recent Issue:** The inefficient N+1 fetch pattern on the UI has been refactored, resolving the primary source of client-side errors.

### 6. UI Flow: Home Screen (`_GroupList`)
- Streams the `userGroupMemberships` index for the current user.
- Fetches all group, event, and participation data in a single, efficient batch operation.
- Displays a list with status indicators (icons, colors) and wallet balance.

### 7. Project Status & Next Steps
- **Core Features:** The primary features for group creation, event management, registration, waitlists, and withdrawals (including refunds/penalties) are **fully implemented and functional**.
- **Potential Future Enhancements:**
    1.  **Push Notifications:** Notify users of event reminders, join request approvals, or promotion from a waitlist.
    2.  **Advanced Penalty Rules:** Implement more complex penalty logic for withdrawals (e.g., scaling penalties closer to the event date).
    3.  **Admin Dashboard:** A dedicated UI for admins to view group statistics and manage settings.
    4.  **User-to-User Transfers:** Allow members to transfer funds between their wallets.

### 8. Performance & Scaling
- **Current Bottleneck:** Resolved. The home screen now uses an efficient, denormalized query.
- **Future:** Add composite indexes for more complex event queries (e.g., `groupId` + `eventTimestamp`).

### 9. Quick Reference: Key Fields
- **Group:** `name`, `description`, `admin`, `groupCode`, `negativeBalanceLimit`
- **Member:** `uid`, `displayName`, `walletBalance`, `joinedAt`
- **Event:** `name`, `groupId`, `eventTimestamp`, `fee`, `maxParticipants`, `commitmentDeadline`
- **Participant:** `uid`, `status`, `paymentStatus`, `registeredAt`
- **UserGroupMembership:** `groupId`, `groupName`, `isAdmin`

### 10. Gemini Prompting Guide
- **Minimal Prompt Template:**
  `Context: GetSpot (Flutter/Firebase). Pain point: <describe>. Task: <describe>. Constraints: <constraints>. Output: <format>.`
- **Example - Refactor UI:**
  `Task: Refactor Dart home screen stream to use the userGroupMemberships index, then fetch group docs in a single Future.wait batch.`
- **Example - Harden Rules:**
  `Task: Propose a rule for userGroupMemberships allowing read only where request.auth.uid == uid and writes only via Functions.`