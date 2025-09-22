# Firestore Data Model for GetSpot

This document outlines the proposed Firestore collection and document structure based on the application requirements.

## Root Collections

*   `/users`
*   `/groups`
*   `/events`
*   `/transactions`
*   `/userGroupMemberships`

---

### 1. Users Collection

Stores information about individual users.

`/users/{userId}`

```json
{
  "uid": "string",          // Firebase Auth User ID
  "displayName": "string",  // User's public display name
  "email": "string",        // User's email address
  "createdAt": "timestamp", // Account creation timestamp
  "fcmTokens": ["string"]   // Array of FCM device tokens for push notifications
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
  "groupCode": "string", // A unique, shareable code to find the group
  "groupCodeSearch": "string", // Uppercase, hyphen-less version for searching
  "negativeBalanceLimit": "number", // Max negative balance allowed for members
  "createdAt": "timestamp",
  
  // Subcollections:
  // /members
  // /joinRequests
  // /announcements
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
  "requestedAt": "timestamp",
  "status": "string" // "pending", "denied"
}
```

#### 2.3. Announcements Subcollection

Stores announcements posted by the group admin.

`/groups/{groupId}/announcements/{announcementId}`

```json
{
  "content": "string",      // The body of the announcement
  "authorId": "string",     // The UID of the admin who posted it
  "authorName": "string",   // The display name of the admin
  "createdAt": "timestamp"  // The time the announcement was posted
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

Stores a log of all financial activities for auditing and user history. The document ID is the unique ID for the transaction.

`/transactions/{transactionId}`

```json
{
  "uid": "string",          // The user involved
  "groupId": "string",      // The group in which the transaction occurred
  "eventId": "string",      // Optional: The event that triggered the transaction
  "type": "string",         // 'credit' or 'debit'
  "amount": "number",       // The absolute, positive value of the transaction
  "description": "string",  // e.g., "Fee for 'Friday Night Badminton'" or "Admin credit"
  "createdAt": "timestamp"  // The server timestamp of the transaction
}
```

---

### 5. User Group Memberships Collection

This collection is a top-level collection designed for highly efficient lookups of a user's group memberships. Instead of performing expensive collection group queries across all groups, the application can simply query a user's document in this collection to get a list of all their groups.

This model significantly improves performance and scalability.

`/userGroupMemberships/{userId}/groups/{groupId}`

```json
{
  "groupId": "string",      // The ID of the group
  "groupName": "string",    // Denormalized group name for display
  "isAdmin": "boolean"      // Whether the user is an admin of this group
}
```