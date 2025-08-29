## GetSpot: Gemini Context Pack

This document is a high-signal context bundle optimized for Gemini's prompt window. It summarizes architecture, schemas, flows, security model, gaps, and prioritized next steps. All guidance below is phrased so it can be directly pasted into a Gemini system / context preamble.

### 1. Purpose
GetSpot helps small recurring sports groups (initially badminton) manage groups, membership, events, registration flows, and a virtual wallet/penalty system.

### 2. High-Level Architecture
Frontend: Flutter (mobile + web)
Backend: Firebase (Auth, Firestore, Functions, Hosting)
Patterns:
1. Callable Function (createGroup) for atomic multi-write + code generation.
2. Write-to-Trigger pattern (participant registration -> Function validates & updates status) – partially implemented conceptually; trigger function for participants not yet present in repo.
3. (Planned / partially implemented) Denormalized membership index `/userGroupMemberships/{userId}/groups/{groupId}` for fast group list (current UI still using collectionGroup on `members`).

### 3. Firestore Collections (Implemented / Planned)
- users
- groups/{groupId}
	- members/{userId}
	- joinRequests/{userId}
- events/{eventId}
	- participants/{userId}
- transactions/{transactionId}
- userGroupMemberships/{userId}/groups/{groupId} (designed, not yet written by Functions in current code base)

### 4. Core Cloud Function (present)
`createGroup` (callable): validates auth & input, generates groupCode, writes group + first member atomically. Adds member doc with fields: uid, displayName, walletBalance (0), joinedAt.

Missing functions (described in docs but not yet implemented):
- manageJoinRequest (approve/deny) / processJoinRequest
- processEventRegistration (trigger for participants) – filenames exist but implementation not reviewed here (add later if needed).

### 5. Security Rules (Key Points)
- Default deny fallback.
- users: self read/update/create.
- groups: any auth user can read/create; only admin can update/delete.
- groups/{groupId}/members: custom logic separated into get vs list; collectionGroup queries allowed only for own member docs (`resource.data.uid == request.auth.uid`).
- joinRequests: admin or self readable; self create; admin delete.
- events & participants: read restricted to group membership; write constraints on participants (Requested status on create, etc.).
- transactions: read own only; no client writes.

Recent issue: CollectionGroup query originally failed (permission-denied) because rule conditions were not query-safe. Adjusted by splitting get/list and adding top-level recursive match. UI now functioning but still performing per-member parent fetches (N+1 pattern) and not using the denormalized userGroupMemberships index.

### 6. Current UI Flow Highlights
HomeScreen `_GroupList`:
- Sets up real-time stream on `userGroupMemberships` to get the user's groups.
- For each group, it fetches the group details, the next event, and the user's participation status for that event.
- It then displays this information in a list, with icons and colors to indicate the user's status and wallet balance.

### 7. Data Model Gaps vs Implementation
Documented but not yet enforced/implemented:
- groupCodeSearch (normalize groupCode) – not written in `createGroup` function.
- userGroupMemberships writes (missing in `createGroup`).
- event lifecycle (fee deduction, waitlist promotion, penalties) – no Functions present yet.
- wallet / transactions pipeline and balance checks not implemented.
- notifications (FCM) absent.

### 8. CI / Automation
- GitHub Actions: deploy Functions on changes to `functions/**`.
- Added Firestore rules deploy workflow on `firestore.rules` changes.
Suggested additions:
- Lint + test workflow (flutter analyze / dart test / functions lint & test).
- Type-safe generation check (e.g., `flutter pub run build_runner build --delete-conflicting-outputs` if code gen added later).

### 9. Performance & Scaling Observations
- Current membership group-loading: O(M) document fetches (M = number memberships). Acceptable for small groups but should migrate to denormalized index for scale.
- CollectionGroup query is simple & filtered; cost okay but still scans index for matching uid across all groups.
- Add composite indexes later for events queries (e.g., by groupId + eventTimestamp) once implemented.

### 10. Security / Rule Considerations
- Ensure every member doc always stores `uid` field (Functions do; manual writes must conform) or list rule could leak denials.
- Consider rate limiting group creation (could add Firestore counter or Cloud Function guard).
- Add validation to prevent arbitrary walletBalance edits (enforce via Functions only; clients read-only).

### 11. Recommended Next Implementation Steps
1. Implement join approval function (move doc from joinRequests to members + write userGroupMemberships entry).
2. Add userGroupMemberships population inside `createGroup` (and future approval function).
3. Modify HomeScreen to use userGroupMemberships instead of collectionGroup + parent fetch.
4. Add participant registration trigger function (onCreate /participants) aligning with docs (status transitions & waitlist logic).
5. Introduce transaction Function to record fee deductions & penalties.
6. Add integration tests (Functions emulator + Flutter test) for membership and registration flows.
7. Add logging + structured error codes in Functions for client clarity.

### 12. Gemini Usage Patterns & Prompt Recipes
Goal: Minimize tokens while preserving invariants. Use concise role / task frames.

Core Prompt Skeleton:
"System Context: Flutter + Firebase (Auth/Firestore/Functions). Collections: users, groups(+members,joinRequests), events(+participants), transactions (planned), userGroupMemberships (planned index). Security: query-safe rules; membership list restricted to self. Task: <describe>. Constraints: Maintain invariants (single membership per (groupId,uid); roles owner/admin/member; future index). Output: <desired format>."

Recipes:
1. Generate Firestore Trigger
	Instruction: "Write a TypeScript Cloud Function trigger onCreate for groups/{groupId}/members/{uid} that upserts userGroupMemberships/{uid}/groups/{groupId}. Include onDelete counterpart. Avoid infinite loops."
2. Refactor UI Stream
	Instruction: "Refactor Dart home screen groups stream to first listen to userGroupMemberships then fetch group docs in a single Future.wait batch; keep fallback to collectionGroup under feature flag." 
3. Harden Security Rules
	Instruction: "Propose rule block for userGroupMemberships restricting read/list to request.auth.uid == uid; writes only via Functions (enforce sentinel field 'systemWrite' == true)."
4. Generate Jest Tests
	Instruction: "Create Jest tests using Firebase Emulator to ensure createGroup writes group + first member, and index trigger produces membership index doc." 
5. Transaction Pipeline Draft
	Instruction: "Draft Firestore transaction or batched write logic for joinRequest approval -> create member -> write membership index -> update joinRequest status (approved) atomically."

Token Optimization Tips:
- Refer to collections with abbreviations after first definition (e.g., U, G, GMembers, JReqs, Events, Parts, Tx, UGMIndex) if context window tight.
- Avoid repeating full schema—link to section numbers or anchor comments if multi-part prompt.
- Provide only changed fields when evolving a schema.

Reliability Reminders for Gemini:
- Flag any rule condition that can't be used in queries (non-query-safe) with a WARNING.
- When generating batched writes, explicitly list failure rollback behavior if an operation fails.
- Always mention need for composite index if proposing a new multi-field query.

### 13. Quick Reference (Fields)
Group: name, description, admin, groupCode, negativeBalanceLimit, createdAt
Member: uid, displayName, walletBalance, joinedAt
JoinRequest: uid, displayName, requestedAt
Event: name, groupId, admin, location, eventTimestamp, fee, maxParticipants, commitmentDeadline, createdAt, confirmedCount, waitlistCount
Participant: uid, displayName, status, denialReason, paymentStatus, registeredAt
Transaction: transactionId, uid, groupId, eventId?, type, amount, description, createdAt
UserGroupMembership: groupId, groupName, isAdmin

### 14. Known Open Questions / Assumptions
- How to handle group deletion cascade (clean memberships, events)? Not yet defined.
- Negative balance enforcement logic centralization not implemented.
- Fee/penalty reversal flow (when waitlist fills) postponed.
- Search/discovery: groupCode only; no public listing or indexing features yet.

### 15. Minimal Gemini Prompt Template
"Context: GetSpot (Flutter + Firebase Auth/Firestore/Functions). Collections: users; groups(+members,joinRequests); events(+participants); transactions (planned); userGroupMemberships (planned index for user->groups). Current pain: collectionGroup N+1 fetch for groups on home screen. Invariants: single membership per (groupId,uid); roles owner/admin/member; query-safe rules. Task: <INSERT>. Constraints: preserve security model & prepare for membership index migration. Output: <FORMAT>. If assumptions required, list them first."

Variant for Rules Hardening:
"Given existing rule allowing list of members only where resource.data.uid == request.auth.uid, propose refactor after adding userGroupMemberships to simplify queries and remove collectionGroup dependency. Provide final rule snippet."

---
Update date: 2025-08-26 (Gemini-focused revision)
