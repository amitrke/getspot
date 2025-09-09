# Task: Implement Event Cancellation

**Objective:** Allow a group admin to cancel an upcoming event. This action will refund all registered participants and update the event's status to prevent further interactions.

---

## 1. Backend (Cloud Function)

A new HTTPS Callable Function named `cancelEvent` will be created.

### Inputs:
- `eventId` (string): The ID of the event to be cancelled.

### Core Logic:
1.  **Authentication:** Verify that a user is logged in.
2.  **Authorization:**
    - Fetch the event document using the `eventId`.
    - From the event data, get the `groupId`.
    - Fetch the corresponding group document.
    - Verify that the `request.auth.uid` matches the `admin` UID in the group document. If not, throw a `permission-denied` error.
3.  **Execution (in a single Firestore Transaction):**
    - Fetch all documents from the `events/{eventId}/participants` subcollection.
    - For each participant document:
        - Get the `userId` and the original `fee` paid from the event document.
        - Find the corresponding member document at `groups/{groupId}/members/{userId}`.
        - **Refund:** Increment the member's `walletBalance` by the event `fee`.
        - **Log Transaction:** Create a new document in the `transactions` collection with `type: 'credit'`, the refunded `amount`, and a clear `description` (e.g., "Refund for cancelled event: [Event Name]").
    - **Update Event Status:**
        - Update the event document itself. Instead of deleting it, set a new field `status: 'cancelled'`. This preserves the event history and prevents it from appearing in "upcoming event" queries.
4.  **Return Value:**
    - On success, return `{ status: 'success', message: 'Event cancelled and all participants refunded.' }`.
    - On failure, throw an appropriate `HttpsError`.

---

## 2. Frontend (Flutter)

The UI changes will be focused on the `EventDetailsScreen`.

### Implementation Steps:
1.  **Admin-Only Button:**
    - In `EventDetailsScreen`, add a "Cancel Event" button.
    - This button's visibility should be controlled by the same `_isAdmin` flag used for other admin controls.
2.  **Confirmation Dialog:**
    - When the admin taps the "Cancel Event" button, show an `AlertDialog`.
    - The dialog should clearly state the consequences: "Are you sure you want to cancel this event? This action is irreversible and will refund all registered participants."
    - It should have two buttons: "Nevermind" and "Confirm Cancellation".
3.  **Function Invocation:**
    - If the admin confirms, the app should call the `cancelEvent` Cloud Function, passing the current `eventId`.
    - While the function is executing, display a loading indicator (e.g., a `CircularProgressIndicator` in the dialog or a modal overlay).
4.  **UI Feedback & State Update:**
    - On a successful response from the function, close the dialog and show a `SnackBar` confirming the cancellation.
    - The `EventDetailsScreen` should update its UI to reflect the cancelled state. For example:
        - Disable the "Register" or "Withdraw" buttons.
        - Display a prominent chip or banner at the top that says "Event Cancelled".
    - The event should no longer appear in the main `GroupDetailsScreen`'s list of upcoming events (this will happen automatically if the Firestore query filters out events with `status: 'cancelled'`).

---

## 3. Data Model Changes

### `events` collection:
- Add an optional `status` field (string).
- Possible values: `active` (default), `cancelled`.

### Firestore Queries:
- All queries that fetch upcoming events (e.g., in `GroupDetailsScreen` and `GroupService`) must be updated to filter for `where('status', '!=', 'cancelled')`.