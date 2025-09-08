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

## Project Status & Next Steps

The core features for group creation, event management, registration, waitlists, and withdrawals (including refunds/penalties) are **fully implemented and functional**. The home screen uses an efficient, denormalized query for fast performance.

### Potential Future Enhancements
- **Push Notifications:** Notify users of event reminders, join request approvals, or promotion from a waitlist.
- **Advanced Penalty Rules:** Implement more complex penalty logic for withdrawals (e.g., scaling penalties closer to the event date).
- **Admin Dashboard:** A dedicated UI for admins to view group statistics and manage settings.
- **User-to-User Transfers:** Allow members to transfer funds between their wallets.
- **Improved Testing:** Expand the test harness with more comprehensive widget and integration tests.

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
