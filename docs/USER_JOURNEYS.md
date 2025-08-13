# User Journeys

This document outlines the key user flows in the GetSpot application, based on the defined requirements and data model.

## 1. User Authentication (Google Sign-In)

This is the primary entry point for all users. The system uses Firebase Authentication with Google Sign-In.

**Associated Roles:** All Users
**Associated Screens:** `LoginScreen`, `HomeScreen`

### Flow Diagram

```mermaid
graph TD
    A[User opens app] --> B{Is user already signed in?};
    B -- Yes --> D[Proceed to HomeScreen];
    B -- No --> C[Show LoginScreen];
    C -- Clicks 'Sign in with Google' --> E[Initiates Google Sign-In];
    E -- Success --> F[Firebase session created, user profile stored in Firestore];
    F --> D;
```

---

## 2. New User Creates a Group

This flow describes how a user creates a new community, becoming its default administrator.

**Associated Roles:** Organizer
**Prerequisite:** User is authenticated.

### Flow Diagram

```mermaid
graph TD
    A[User navigates to 'Create Group'] --> B[Fills out Group Details form];
    B --> C["Selects Membership Type ('Open' or 'By Approval')"];
    C -- Clicks 'Create' --> D[New doc created in `/groups` collection];
    D -->|User is automatically added| E["New doc created in `/groups/{groupId}/members/{userId}`"];
    E --> F[User is redirected to the new Group's dashboard];
```

---

## 3. Player Joins a Group

This flow describes how a player joins a group, covering both "Open" and "By Approval" scenarios.

**Associated Roles:** Player
**Prerequisite:** User is authenticated.

### Flow Diagram (Open Group)

```mermaid
graph TD
    A[Player finds an 'Open' group] --> B[Clicks 'Join Group'];
    B --> C["New doc created in `/groups/{groupId}/members/{userId}`"];
    C --> D[Player sees group events and content immediately];
```

### Flow Diagram (By Approval Group)

```mermaid
graph TD
    A[Player finds a 'By Approval' group] --> B[Clicks 'Request to Join'];
    B --> C["New doc created in `/groups/{groupId}/joinRequests/{userId}`"];
    C --> D[Player sees 'Request Pending' status];
    D -->|Organizer approves request| E[Firebase Function moves user from 'joinRequests' to 'members' subcollection];
    E --> F[Player receives notification and can now access the group];
```

---

## 4. Organizer Creates an Event

This flow describes how an organizer creates an event within a group they manage.

**Associated Roles:** Organizer
**Prerequisite:** User is an admin of the group.

### Flow Diagram

```mermaid
graph TD
    A[Organizer selects a group] --> B[Navigates to 'Create Event'];
    B --> C[Fills out Event Details and sets Commitment Deadline];
    C -- Clicks 'Publish' --> D[New doc created in `/events` collection];
    D --> E[Event becomes visible to all members of the group];
```

---

## 5. Player Registers for an Event

This flow describes how a player registers for an event, highlighting the "write-to-trigger" pattern.

**Associated Roles:** Player
**Prerequisite:** User is a member of the group where the event is hosted.

### Flow Diagram

```mermaid
graph TD
    subgraph "Player's Device (Flutter App)"
        A[Player views an event] --> B{Wallet balance sufficient?};
        B -- Yes --> C[Clicks 'Register'];
        C --> D["Writes 'participant' doc with {status: 'requested'}"];
        D -- Listens for real-time update --> G[UI updates to 'Confirmed' or 'Waitlisted'];
    end

    subgraph "Firebase Backend"
        D -- triggers --> E[Firebase Function validates request];
        E --> F[Updates participant doc with final status];
    end
```
