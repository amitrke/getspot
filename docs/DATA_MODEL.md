# Firestore Data Model for GetSpot

This document outlines the proposed Firestore collection and document structure based on the application requirements.

## Root Collections

*   `/users`
*   `/groups`
*   `/events`
*   `/transactions`

---

### 1. Users Collection

Stores information about individual users.

`/users/{userId}`

```json
{
  "uid": "string",          // Firebase Auth User ID
  "displayName": "string",  // User's public display name
  "email": "string",        // User's email address
  "createdAt": "timestamp"  // Account creation timestamp
}
```

---

### 2. Groups Collection

Stores information about the groups created by organizers.

`/groups/{groupId}`

```json
{
  "name": "string",
  "description": "string",
  "admin": "string", // {userId} of the group organizer
  "negativeBalanceLimit": "number", // Max negative balance allowed for members
  "createdAt": "timestamp",
  
  // Subcollections:
  // /members
  // /joinRequests
}
```

#### 2.1. Members Subcollection

Tracks the members of a group and their specific wallet balance for that group.

`/groups/{groupId}/members/{userId}`

```json
{
  "uid": "string",          // The user's ID
  "displayName": "string",
  "walletBalance": "number", // User's virtual currency balance for this group
  "joinedAt": "timestamp"
}
```

#### 2.2. Join Requests Subcollection

Stores pending requests to join the group.

`/groups/{groupId}/joinRequests/{userId}`

```json
{
  "uid": "string",
  "displayName": "string",
  "requestedAt": "timestamp"
}
```

---

### 3. Events Collection

Stores all event information.

`/events/{eventId}`

```json
{
  "name": "string",
  "groupId": "string", // ID of the group this event belongs to
  "admin": "string", // {userId} of the event organizer
  "location": "string",
  "eventTimestamp": "timestamp", // The date and time of the event
  "fee": "number", // Cost of the event in virtual currency
  "maxParticipants": "number",
  "commitmentDeadline": "timestamp", // Deadline for penalty-free withdrawal
  "createdAt": "timestamp",
  
  // Denormalized counts for quick access
  "confirmedCount": "number",
  "waitlistCount": "number",

  // Subcollections:
  // /participants
}
```

#### 3.1. Participants Subcollection

Tracks every user who has registered for an event, including their status. The document ID is the user's ID.

`/events/{eventId}/participants/{userId}`

```json
{
  "uid": "string",
  "displayName": "string",
  "status": "string", // "Requested", "Confirmed", "Waitlisted", "Withdrawn", "Denied"
  "denialReason": "string", // Optional: "Insufficient funds", "Event full", etc.
  "paymentStatus": "string", // "Pending", "Paid", "Failed" - Tracks fee payment after commitment deadline
  "registeredAt": "timestamp" // Used to determine waitlist order (first-come, first-served)
}
```

---

### 4. Transactions Collection

Stores a log of all financial activities (fees and penalties) for auditing and history.

`/transactions/{transactionId}`

```json
{
    "transactionId": "string",
    "uid": "string", // The user involved
    "groupId": "string",
    "eventId": "string", // Optional, if related to an event
    "type": "string", // "EventFee", "Penalty", "Credit"
    "amount": "number", // The value of the transaction (can be negative)
    "description": "string", // e.g., "Fee for 'Friday Night Badminton'"
    "createdAt": "timestamp"
}
```
