# GetSpot Application Requirements

## 1. High-Level Vision

An application to streamline the organization of local badminton meetups. The app connects organizers with participants, simplifying event creation, registration, and communication, with a focus on recurring games for established groups.

## 2. User Roles & Permissions

For the initial version, there will be one primary user type that can perform two key roles:

*   **Participant:** The default role for any user. Participants can:
    *   Request to join groups.
    *   Discover and view events.
    *   Register for events and manage their attendance.
*   **Organizer (Group Admin):** A user who creates a group automatically becomes its admin. Organizers can do everything a participant can, plus:
    *   Create and manage their group(s).
    *   Approve or deny requests from new users to join their group.
    *   Create, manage, and communicate updates for events within their group.

## 3. Core Concepts

### 3.1. Groups
*   **Creation:** Any user can create a group, becoming its default Organizer/Admin. When a group is created, a unique, shareable **Group Code** is generated.
*   **Discovery:** Users find and join groups by entering this unique Group Code.
*   **Membership:** Membership to all groups is by approval only; the group admin must approve new members. This helps manage recurring private games.

### 3.2. Event Commitment & Fee Model
This model ensures that event spots are paid for, giving organizers the confidence to manage and expand events.

*   **Upfront Fee Deduction:**
    *   To register for an event, a participant must have a sufficient wallet balance (`walletBalance + negativeBalanceLimit >= fee`).
    *   The event fee is deducted from the participant's wallet **immediately upon registration**.
    *   If a spot is available, the participant becomes **"Confirmed"**.
    *   If the event is full, the participant is added to the **"Waitlist"** but has already paid the fee, guaranteeing their spot if one opens up.

*   **Withdrawal & Refunds:**
    *   **Confirmed Participants** can withdraw before the **Commitment Deadline** for a full refund.
    *   Withdrawing after the deadline results in a forfeiture of the fee, unless the spot is filled by a waitlisted user.
    *   **Waitlisted Participants** can withdraw at any time for a full refund.
    *   If a waitlisted participant never gets a spot, their fee will be automatically refunded by a scheduled process after the event has ended.

### 3.3. Virtual Currency
*   **Purpose:** To handle event fees without integrating real-world payment gateways.
*   **Mechanism:**
    *   Organizers can "sell" virtual currency to participants offline.
    *   The organizer's app interface will have a feature to credit currency to a participant's account.
    *   Participants use this currency to pay for event registration fees.

### 3.4. Waitlist
*   If an event is full, interested participants who have paid the event fee can join a waitlist.
*   **Automatic Promotion:** If a spot becomes available, the first user on the waitlist is automatically promoted to **"Confirmed"** status. No further payment is needed as the fee was collected upfront.
*   **Withdrawal & Refunds:** A waitlisted user can withdraw their request at any time for a full refund. If they remain on the waitlist and the event ends, they will be refunded automatically.

## 4. Key Features

### 4.1. Group Management
*   [x] Create a new group (name, description), which generates a unique, shareable group code.
*   [x] View the group code to share it with potential members.
*   [x] View and manage group members.
    *   [x] Show a confirmation dialog before removing a member (dialog includes member name and warning about irreversible action if balance is zero).
    *   [x] Reject removal when member wallet balance is non-zero (surface inline error message explaining required balance = 0).
*   [x] Approve/deny membership requests.
*   [x] Set a per-participant negative balance limit for the group's virtual currency.

### 4.2. Event Management (for Organizers)
*   [x] Create an event within a group.
*   [x] Set event details: date, time, location, max participants, initial fee, and a **Commitment Deadline**.
*   [x] **Cancel an event**, which should notify all registered participants.
*   [ ] Add or remove participant spots after event creation (before the event starts).
*   [x] Monitor the list of registered participants and their payment status.
*   [ ] Clear a participant's "denied" status to allow them to re-register.
*   [x] Use a communication tool to send updates to all registered participants.
*   [ ] Create recurring events (e.g., weekly, bi-weekly) to automate event creation.

### 4.3. Participant Experience
*   [x] Find a group by entering a unique Group Code.
*   [x] Request to join a group after finding it.
*   [x] View event details (including the Commitment Deadline).
*   [x] Submit a registration request for an event. The initial status will show as **"Requested"**.
*   [x] The system will process requests on a **first-come, first-served basis** and provide a status update (e.g., **"Confirmed"**, **"Waitlisted"**, or **"Denied"**) reasonably quickly.
*   [x] Withdraw from an event (understanding the penalty if after the commitment deadline).
    *   [x] If withdrawal is attempted after the commitment deadline, the user must confirm their understanding of the penalty.
    *   [x] There should be a popup confirmation dialog to confirm the withdrawal.
*   [x] Join a waitlist if all spots are filled when the request is processed.
*   [x] Receive push notifications for status updates, event changes, and commitment deadlines.
*   [ ] View their registration history.

### 4.4. Wallet & Currency
*   [x] **Organizer:** Interface to add/credit virtual currency to a participant's wallet.
*   [x] **Participant:** View current wallet balance and transaction history.
*   [x] Show a confirmation dialog before applying a wallet credit (display target member, amount, and optional description).
*   [x] Enforce numeric precision: currency amounts must be valid numbers with at most two decimal places; reject invalid input with clear validation message.
*   [x] Display all wallet balances formatted to two decimal places (e.g., 12.50) across UI.

### 4.5. Group Communication
*   [x] **Organizer:** Post announcements that are visible to all group members.

### 4.6. User Profiles
*   [x] Display the user's Google Account profile picture (if available) next to their name.
*   [ ] Allow users to upload a custom profile picture from their device's gallery to override their Google photo.
*   [x] Logout functionality.

## 5. Technical Stack

*   **Frontend:** Mobile (iOS & Android) and Web Application.
    *   **Framework:** Flutter.
*   **Backend:** Google Firebase.
    *   **Database:** Cloud Firestore.
    *   **Authentication:** Firebase Authentication.
    *   **Notifications:** Firebase Cloud Messaging (for push notifications).

## 6. Non-Functional Requirements

*   [ ] Implement separate `dev` and `prod` environments for Firebase and Flutter builds, as detailed in `docs/ENVIRONMENTS.md`.

## 7. Legal and Compliance

To protect both the users and the service provider, the application must include clear legal documentation.

*   [ ] **Terms of Service (ToS):** An agreement that users must accept during sign-up. It will define:
    *   Acceptable user conduct.
    *   Rules and clarifications for the virtual wallet (e.g., no cash value).
    *   A disclaimer limiting liability for injuries sustained during physical activities organized through the app.
    *   A "Disclaimer of Warranties" stating the app is provided "as is".
    *   The service's right to terminate user accounts for violations.

*   [ ] **Privacy Policy:** A document explaining what user data is collected, how it is used, and how it is protected. This is a legal requirement in many jurisdictions.

*   [ ] **In-App Implementation:**
    *   During the sign-up process, users must explicitly agree to the Terms of Service and Privacy Policy via a checkbox before they can create an account.
    *   Links to both documents must be easily accessible from within the app's settings or "About" section.