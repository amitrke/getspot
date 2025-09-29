# Data Retention Policy

This document outlines the lifecycle of data within the GetSpot application, from creation to archival and eventual deletion. The policy aims to balance application performance, data privacy, and operational costs.

## 1. Guiding Principles

*   **Performance:** Keep the primary database (Firestore) lean by archiving data that is no longer needed for day-to-day app functionality.
*   **Cost-Effectiveness:** Utilize cheaper, long-term storage (Google Cloud Storage) for archived data.
*   **User Trust:** Provide users with access to their relevant history (e.g., transactions) for a reasonable period while ensuring their data is not kept indefinitely without cause.
*   **Compliance:** Adhere to data privacy principles by establishing clear timelines for data deletion.

## 2. Data States

Data in GetSpot exists in one of three states:

1.  **Active:** The data is stored in Firestore and is actively used and displayed within the application. This is the highest-cost, highest-performance tier.
2.  **Archived:** The data is moved from Firestore to a designated Google Cloud Storage bucket. It is stored as a JSON file, is not visible in the app, and is kept for long-term record-keeping or potential manual retrieval.
3.  **Deleted:** The data is permanently removed from all systems, including the Google Cloud Storage archive. This action is irreversible.

## 3. Retention Schedule by Data Type

| Data Type | Collection(s) | Active Period | Archived Period | Deletion Trigger |
| :--- | :--- | :--- | :--- | :--- |
| **Events** | `events`, `events/{id}/participants` | Event is upcoming + **3 months** after it ends. | From end of Active Period until **2 years** after event end date. | 2 years after event end date. |
| **Transactions** | `transactions` | **3 months** from creation date. | From end of Active Period until **2 years** after creation date. | 2 years after creation date. |
| **Groups** | `groups`, `groups/{id}/members`, `userGroupMemberships` | While active. A group is considered inactive if it has no new events or members for **3 months**. | An "archived" flag is set. The group is hidden in the UI but data is retained in Firestore. | Permanent deletion is a **manual admin action only** to prevent accidental data loss for seasonal groups. |
| **User Accounts** | `users` | While active. A user is considered inactive after **3 months**. | User data is moved from Firestore to Cloud Storage. | Upon user's explicit request for account deletion, or after 2 years of being archived. |
| **Join Requests** | `groups/{id}/joinRequests` | Until the request is approved or denied. | N/A | **7 days** after the request is resolved (approved/denied). |

---

### Rationale for Key Decisions:

*   **Events & Transactions (3-month active period):** This keeps the primary database lean for performance and cost, while still providing users with a reasonable window to review recent activity.
*   **Groups (Archival, not deletion):** Automatically archiving a group after 3 months of inactivity hides it from the main UI, reducing clutter. This is preferable to deletion, as it prevents accidental data loss for groups that may have seasonal breaks.
*   **User Accounts (Archival):** Archiving inactive user accounts helps maintain a clean and relevant primary user database. A clear process for account restoration will be necessary if an archived user attempts to log in again.

## 4. Implementation Strategy

This policy will be implemented via a combination of scheduled Cloud Functions and Google Cloud Storage (GCS) Object Lifecycle Management, creating a fully automated, two-stage process.

### Stage 1: Archival (Firestore -> Cloud Storage)

A scheduled Cloud Function (`runDataLifecycleManagement`) will be configured to run automatically on a recurring schedule (e.g., daily at midnight). This function will be responsible for moving data from the "Active" to the "Archived" state.

*   **Tasks for the Cloud Function:**
    *   **Archive Events:** Query for events where the `eventTimestamp` is older than 3 months. For each result, read the event and its participant subcollection, write them to a JSON file in Google Cloud Storage (`gs://getspot-archive/events/{eventId}.json`), and then delete the original Firestore documents.
    *   **Archive Transactions:** Query for transactions where the `createdAt` timestamp is older than 3 months. Move them to GCS (`gs://getspot-archive/transactions/{transactionId}.json`) and delete the Firestore document.
    *   **Archive Groups & Users:** Flag inactive groups and users as "archived" based on the 3-month inactivity rule.
    *   **Delete Old Join Requests:** Query for join requests that were resolved more than 7 days ago and delete them from Firestore.

### Stage 2: Deletion (Cloud Storage -> Permanent Deletion)

The final deletion of archived data will be handled automatically by **Google Cloud Storage Object Lifecycle Management**. This is the most efficient and cost-effective method for managing the final stage of the data's lifecycle.

*   **Configuration:**
    *   A lifecycle rule will be configured on the `getspot-archive/` path within our GCS bucket.
    *   **Action:** `Delete`
    *   **Condition:** The rule will be triggered when an object's **age** is greater than **730 days** (2 years).

This two-stage approach separates the logic of *what* to archive (the Cloud Function) from the policy of *when* to permanently delete (GCS Lifecycle Management), creating a clean and robust system.
