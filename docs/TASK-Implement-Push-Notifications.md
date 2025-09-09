# Task: Implement Push Notifications

**Objective:** Integrate Firebase Cloud Messaging (FCM) to send timely, relevant push notifications to users, enhancing engagement and improving the user experience.

## 1. Key Notification Scenarios

The following user-facing events should trigger a push notification:

1.  **Join Request Approved:** When a group admin approves a user's request to join a group.
2.  **Promoted from Waitlist:** When a user is automatically promoted from the waitlist to "confirmed" for an event.
3.  **Event Reminder:** A scheduled notification sent to confirmed participants 24 hours before an event begins.
4.  **New Event Created:** When an admin creates a new event in a group, notify all members of that group.

## 2. Backend Implementation (Firebase & Cloud Functions)

### 2.1. Data Model Changes

The `users` collection needs to be updated to store user device tokens.

**Collection:** `/users/{userId}`

**New Field:**
```json
{
  // ... existing fields
  "fcmTokens": ["string"] // An array to support multiple devices per user
}
```

### 2.2. Cloud Function Modifications

#### A. `manageJoinRequest`
-   **File:** `functions/src/manageJoinRequest.ts`
-   **Logic:** After the transaction successfully commits and the user is added as a member, retrieve the new member's FCM tokens from their user document.
-   **Action:** Trigger a notification sending function.
-   **Message:**
    -   **Title:** "Request Approved"
    -   **Body:** "Your request to join '{groupName}' has been approved!"

#### B. `processWaitlist`
-   **File:** `functions/src/processWaitlist.ts`
-   **Logic:** When a user is successfully promoted from the waitlist (their status is updated to "Confirmed"), retrieve that user's FCM tokens.
-   **Action:** Trigger a notification sending function.
-   **Message:**
    -   **Title:** "You're In!"
    -   **Body:** "A spot has opened up for '{eventName}'. You are now confirmed."

#### C. New Function: `notifyOnNewEvent` (Firestore Trigger)
-   **Trigger:** `onDocumentCreated('/events/{eventId}')`
-   **Logic:**
    1.  When a new event document is created, get the `groupId`.
    2.  Fetch all members of that group from the `/groups/{groupId}/members` subcollection.
    3.  For each member, fetch their FCM tokens from their respective `/users/{userId}` document.
    4.  Send a notification to all members.
-   **Message:**
    -   **Title:** "New Event: {groupName}"
    -   **Body:** "{eventName} has been scheduled. Tap to see details."

#### D. New Function: `sendEventReminders` (Scheduled Function)
-   **Trigger:** `onSchedule('every 1 hours')` (or a similar cron schedule).
-   **Logic:**
    1.  Query for all events where `eventTimestamp` is between 24 and 25 hours from now.
    2.  For each upcoming event, fetch all "Confirmed" participants from the `/events/{eventId}/participants` subcollection.
    3.  For each participant, fetch their FCM tokens.
    4.  Send a notification to all confirmed participants.
-   **Message:**
    -   **Title:** "Reminder: {eventName}"
    -   **Body:** "Your event is tomorrow. Don't forget!"

## 3. Frontend Implementation (Flutter)

### 3.1. Add Dependencies
-   Add the `firebase_messaging` package to `pubspec.yaml`.

### 3.2. Initialization & Permissions
-   In `main.dart`, initialize the `FirebaseMessaging` instance.
-   Create a method to request notification permissions from the user (iOS requires explicit permission). This should be called after a user logs in.

### 3.3. Token Management
-   Create a service or method to handle FCM token logic.
-   On user login, get the FCM token using `FirebaseMessaging.instance.getToken()`.
-   Save this token to the `fcmTokens` array in the user's document (`/users/{userId}`). Use a `FieldValue.arrayUnion()` operation to avoid duplicates.
-   Listen to the `onTokenRefresh` stream to automatically update the token in Firestore if it changes.

### 3.4. Handling Messages
-   **Foreground:** Implement `FirebaseMessaging.onMessage` to handle incoming notifications while the app is open. This could show a local notification using a package like `flutter_local_notifications`.
-   **Background:** Implement `FirebaseMessaging.onMessageOpenedApp` to handle the user tapping on a notification when the app is in the background. This should navigate the user to the relevant screen (e.g., the event details screen).
-   **Terminated:** Use `FirebaseMessaging.instance.getInitialMessage()` to handle the case where the user opens the app from a terminated state by tapping a notification.

## 4. Security Rules
-   Update `firestore.rules` to allow users to write to their own `fcmTokens` field but not read or write to anyone else's.

```
match /users/{userId} {
  // ... existing rules
  allow update: if request.auth.uid == userId &&
                  request.resource.data.keys().hasOnly(['fcmTokens']);
}
```

## 5. Acceptance Criteria
-   [ ] A user receives a push notification when their request to join a group is approved.
-   [ ] A user receives a push notification when they are promoted from an event waitlist.
-   [ ] All members of a group receive a notification when a new event is created.
-   [ ] Users receive a reminder notification 24 hours before an event they are confirmed for.
-   [ ] Tapping on a notification opens the app and navigates to the relevant group or event page.
-   [ ] The user is prompted to grant notification permissions on iOS.
