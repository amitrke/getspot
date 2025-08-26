# GetSpot - Event Organization App

Welcome to the GetSpot project! This application is designed to streamline the organization of local meetups, starting with badminton games. It helps organizers create events, manage participants, and handle registrations, while providing a simple and clear experience for players.

## Project Documentation

This project is well-documented to ensure a clear understanding of its goals, architecture, and data structure. Please review the following documents for a complete overview:

*   **[REQUIREMENTS.md](./docs/REQUIREMENTS.md):** Detailed functional and non-functional requirements, including user stories, core concepts, and feature lists.
*   **[ARCHITECTURE.md](./docs/ARCHITECTURE.md):** A high-level overview of the system architecture, explaining the roles of the Flutter frontend, Firebase services, and security model.
*   **[DATA_MODEL.md](./docs/DATA_MODEL.md):** The proposed data model for the Firestore database, outlining all collections, subcollections, and document schemas.
*   **[USER_JOURNEYS.md](./docs/USER_JOURNEYS.md):** Describes the paths users take to complete core tasks, illustrating the app's workflow from different user perspectives.

## Getting Started

For instructions on how to set up and run the project locally, please see the **[Local Development Guide](./docs/LOCAL_DEVELOPMENT.md)**.

## Quick Architecture Snapshot
Frontend: Flutter (mobile & web)
Backend: Firebase (Auth, Firestore, Cloud Functions, Hosting)
Auth: Google Sign-In (popup on web, `GoogleSignIn` on mobile)
Infrastructure Automation: GitHub Actions (Functions + Firestore rules deploy)

## Core Collections (Current / Planned)
users
groups/{groupId}
	members/{uid}
	joinRequests/{requestId}
events/{eventId}  (may later nest under groups)
	participants/{uid}
transactions/{txId} (planned)
userGroupMemberships/{uid}/groups/{groupId} (planned index to replace collectionGroup query)

## Key Invariants
- Single membership per (groupId, uid)
- Roles: owner | admin | member (owner is creator)
- List membership query currently uses collectionGroup filtered by uid (will migrate to per‑user index)
- Security rules must remain query-safe (list conditions cannot rely on additional document lookups)

## Immediate Roadmap (High Leverage)
1. Membership index Cloud Function (mirror member create/delete -> userGroupMemberships)
2. Refactor home screen to use index (remove N+1 parent fetches)
3. Join request approval callable (atomic: approve -> add member -> index -> update request)
4. Event participant trigger (capacity + waitlist logic)
5. Transactions + wallet balance pipeline (replace inline walletBalance field)
6. Test harness (Functions emulator + basic widget tests) integrated into CI
7. Security rules simplification after index adoption

## Technical Debt / Gaps
- No denormalized membership index yet (performance & rule simplicity)
- Wallet / transactions not implemented (risk of inconsistent balances)
- Event waitlist + promotion logic absent
- Limited automated tests
- Rules contain dual member match blocks (can simplify post-index)

## Contributing Notes
- Prefer Cloud Function triggers for invariants (membership index, participant capacity)
- Use batched writes / transactions for multi-doc consistency
- Add composite indexes proactively when introducing new multi-field queries
- Include short rationale comments at top of new functions for maintainability

## Open Questions
- Private vs public groups? (Impacts visibility rules)
- Fee model & penalty reversal flows
- Group deletion: soft vs hard cascade strategy

## Prompt Template (For AI Tools)
"Context: GetSpot (Flutter + Firebase Auth/Firestore/Functions). Collections: users, groups(+members,joinRequests), events(+participants), transactions (planned), userGroupMemberships (planned index). Invariants: single membership per (groupId,uid); query-safe rules. Task: <YOUR TASK>. Output: <FORMAT>. List assumptions first if needed."

---
This README now incorporates the essential high-signal context; the former `COPILOT_CONTEXT.md` file has been removed to reduce duplication.
