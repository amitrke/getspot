# Contributing to GetSpot

We welcome contributions to the GetSpot project! Please follow these guidelines to ensure a smooth development process.

## Development Guidelines
- Prefer Cloud Function triggers for invariants (membership index, participant capacity)
- Use batched writes / transactions for multi-doc consistency
- Add composite indexes proactively when introducing new multi-field queries
- Include short rationale comments at top of new functions for maintainability

## Prompt Template (For AI Tools)

When using AI-powered tools for development, you can use the following template to provide context about the GetSpot project.

"Context: GetSpot (Flutter + Firebase Auth/Firestore/Functions). Collections: users, groups(+members,joinRequests), events(+participants), transactions (planned), userGroupMemberships (planned index). Invariants: single membership per (groupId,uid); query-safe rules. Task: <YOUR TASK>. Output: <FORMAT>. List assumptions first if needed."