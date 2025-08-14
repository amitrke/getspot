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
The process is defined by a commitment deadline and a flexible, delayed fee deduction.

*   **Registration & Withdrawal:**
    *   **Balance Check:** A participant can only submit a registration request if their current group wallet balance, plus the group's negative balance limit, is greater than or equal to the event fee.
    *   Participants can register for an event without an immediate fee deduction.
    *   Participants can withdraw freely *before* the Commitment Deadline without penalty.
*   **Fee Finalization & Deduction:**
    *   Once the Commitment Deadline passes, all **"Confirmed"** participants are considered **"Committed."**
    *   The system will then attempt to deduct the event fee (as it is at that moment) from each committed participant's group wallet.
*   **Conditional Penalty Rule:**
    *   A **Confirmed** participant withdrawing *after* the deadline will only be penalized if their spot is **not** subsequently filled by a user from the waitlist.
    *   The penalty will be equal to the event fee at the time of withdrawal and is charged immediately. If the spot is later filled, this penalty can be reversed (optional feature for later).

### 3.3. Virtual Currency
*   **Purpose:** To handle event fees without integrating real-world payment gateways.
*   **Mechanism:**
    *   Organizers can "sell" virtual currency to participants offline.
    *   The organizer's app interface will have a feature to credit currency to a participant's account.
    *   Participants use this currency to pay for event registration fees.

### 3.4. Waitlist
*   If an event is full, interested participants can join a waitlist.
*   **Automatic Promotion:** If a spot becomes available (due to a withdrawal or an increase in spots), the first user on the waitlist is automatically promoted to **"Confirmed"** status. The user will be notified of their new status.
*   **Penalty-Free Withdrawal:** A **Waitlisted** user can withdraw their request at any time without any penalty.

## 4. Key Features

### 4.1. Group Management
*   [ ] Create a new group (name, description), which generates a unique, shareable group code.
*   [ ] View the group code to share it with potential members.
*   [ ] View and manage group members.
*   [ ] Approve/deny membership requests.
*   [ ] Set a per-participant negative balance limit for the group's virtual currency.

### 4.2. Event Management (for Organizers)
*   [ ] Create an event within a group.
*   [ ] Set event details: date, time, location, max participants, initial fee, and a **Commitment Deadline**.
*   [ ] **Update the event fee** at any time before the event begins.
*   [ ] Add or remove participant spots after event creation (before the event starts).
*   [ ] Monitor the list of registered participants and their payment status.
*   [ ] Use a communication tool to send updates to all registered participants.

### 4.3. Participant Experience
*   [ ] Find a group by entering a unique Group Code.
*   [ ] Request to join a group after finding it.
*   [ ] View event details (including the Commitment Deadline).
*   [ ] Submit a registration request for an event. The initial status will show as **"Requested"**.
*   [ ] The system will process requests on a **first-come, first-served basis** and provide a status update (e.g., **"Confirmed"**, **"Waitlisted"**, or **"Denied"**) reasonably quickly.
*   [ ] Withdraw from an event (understanding the penalty if after the deadline).
*   [ ] Join a waitlist if all spots are filled when the request is processed.
*   [ ] Receive push notifications for status updates, event changes, and commitment deadlines.
*   [ ] View their registration history.

### 4.4. Wallet & Currency
*   [ ] **Organizer:** Interface to add/credit virtual currency to a participant's wallet.
*   [ ] **Participant:** View current wallet balance and transaction history.

## 5. Technical Stack

*   **Frontend:** Mobile (iOS & Android) and Web Application.
    *   **Framework:** Flutter.
*   **Backend:** Google Firebase.
    *   **Database:** Cloud Firestore.
    *   **Authentication:** Firebase Authentication.
    *   **Notifications:** Firebase Cloud Messaging (for push notifications).
