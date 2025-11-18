# GetSpot: Gemini Context Pack

High-signal context for the GetSpot project. For comprehensive documentation, see `CLAUDE.md` and `docs/` directory.

### 1. Core Purpose
- **Product:** App for small sports groups (e.g., badminton) to manage membership, events, registration, and a virtual wallet/penalty system.

### 2. Architecture
- **Frontend:** Flutter (Mobile + Web)
- **Backend:** Firebase (Auth, Firestore, Functions, Hosting)
- **Key Patterns:** Write-to-Trigger (event registration), Callable Functions (group creation), Denormalized Data (user memberships)
- **Details:** See `docs/ARCHITECTURE.md`

### 3. Firestore Collections
- Root: `users`, `groups`, `events`, `transactions`, `userGroupMemberships`
- Subcollections: `groups/{groupId}/members`, `/joinRequests`, `/announcements`; `events/{eventId}/participants`
- **Details:** See `docs/DATA_MODEL.md`

### 4. Cloud Functions (TypeScript)
**Main exported functions:**
- `createGroup`, `processEventRegistration`, `manageJoinRequest`, `manageGroupMember`
- `withdrawFromEvent`, `cancelEvent`, `updateEventCapacity`
- `cleanupEndedEvents`, `sendEventReminders`
- `notifyOnNewEvent`, `notifyOnAnnouncement`
- `updateFcmToken`, `updateUserDisplayName`
- Data lifecycle: `runDataLifecycleManagement`, `onUserDeleted`, `requestAccountDeletion`
- `maintainJoinRequestCount` (3 triggers for `pendingJoinRequestsCount`)

**Utility functions (internal):** `processWaitlist`, `cleanupInvalidTokens`

### 5. Security & Implementation Notes
- **Security:** Default deny all. Users can only access their own data. Group admins have additional permissions.
- **Details:** See `firestore.rules`
- **Performance:** Denormalized queries, caching services (15-30min TTL), composite indexes
- **Push Notifications:** FCM with token management, foreground/background handling
- **Data Lifecycle:** Account deletion requests, data retention policies

### 6. Project Status
- **Production Ready:** Group management, event scheduling, registrations, waitlists, virtual wallet, push notifications
- **In Progress:** Separate dev/prod environments
- **Roadmap:** See `docs/PRODUCT.md`

### 7. Gemini Prompting Guide
**Minimal Prompt Template:**
```
Context: GetSpot (Flutter/Firebase). Pain point: <describe>. Task: <describe>. Constraints: <constraints>. Output: <format>.
```

**Examples:**
- Refactor: `Task: Refactor Dart home screen to use userGroupMemberships index with batch fetching`
- Security: `Task: Propose Firestore rule for userGroupMemberships allowing read only where request.auth.uid == uid`
- Feature: `Task: Add event capacity update with waitlist promotion logic`

---

**For comprehensive documentation, refer to:**
- `CLAUDE.md` - Complete AI assistant context
- `docs/ARCHITECTURE.md` - System design patterns
- `docs/DATA_MODEL.md` - Complete database schema
- `docs/PRODUCT.md` - Requirements and roadmap
- `CONTRIBUTING.md` - Development guidelines