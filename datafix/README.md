# Data Fix Scripts

This folder contains one-time Python scripts for fixing data integrity issues in the GetSpot Firebase database.

## Prerequisites

1. **Python 3.8+** with Firebase Admin SDK:
   ```bash
   pip install firebase-admin
   ```

2. **Service Account Key**: Place `serviceAccountKey.json` in the project root, or set the `FIREBASE_SERVICE_ACCOUNT_PATH` environment variable.

## Available Scripts

### 01_initialize_max_event_capacity.py

Adds `maxEventCapacity` field to all groups (default: 60).

**What it does:**
- Sets `maxEventCapacity: 60` for groups that don't have it
- For groups with existing events > 60, automatically adjusts to the highest value
- Prevents breaking existing events with large capacities

**Usage:**
```bash
python datafix/01_initialize_max_event_capacity.py
```

**Example output:**
```
Found 5 groups to process
  ✓ Updated group 'Sunridge Saturday' with maxEventCapacity: 60
  ⚠ Group 'Test Group' has events with capacity > 60. Setting maxEventCapacity to 12345
  ⊘ Group 'Another Group' already has maxEventCapacity: 60

SUMMARY:
Total groups:     5
Updated:          4
Skipped:          1 (already had maxEventCapacity)
```

---

### 02_fix_wallet_balances.py

Recalculates wallet balances from transaction history and fixes mismatches.

**What it does:**
- Scans all group members with wallet balances
- Recalculates balance from transaction history (credits - debits)
- Updates balances that don't match

**Usage:**
```bash
# Dry run (see what would change without updating)
python datafix/02_fix_wallet_balances.py --dry-run

# Actually fix the balances
python datafix/02_fix_wallet_balances.py
```

**Example output:**
```
  ⚠ Mismatch found:
     Group: Sunridge Saturday
     User: Amit K (OCfj8A8U5XOTQdMMVeHkUo6VNfG2)
     Stored balance: 50
     Calculated balance: 20.0
     Difference: 30.0
     Transactions: 25
     ✓ Updated balance to 20.0

SUMMARY:
Total wallets checked:  15
Mismatches found:       2
Fixed:                  2
```

---

### 03_fix_missing_transaction_fields.py

Interactively fixes transactions with missing required fields (uid, description).

**What it does:**
- Finds transactions missing `uid` or `description` fields
- Provides interactive prompts to fill in missing data
- Shows available group members to help select correct uid

**Usage:**
```bash
# Just list the issues
python datafix/03_fix_missing_transaction_fields.py --list-only

# Fix interactively
python datafix/03_fix_missing_transaction_fields.py
```

**Example output:**
```
Found 3 transaction(s) with missing fields:

1. Transaction HfRcaQe8AGIyUYuvyyEV
   Type: credit_manual
   Created: 2025-08-26 23:58:47
   Missing: uid, description

Interactive Fixing:
==============================================================
Transaction ID: HfRcaQe8AGIyUYuvyyEV
Type: credit_manual
Amount: 50
Created: 2025-08-26 23:58:47
Group ID: CEF0nH3ajo6DjXJs5GY6
Missing fields: uid, description
==============================================================

Fetching members from group CEF0nH3ajo6DjXJs5GY6...

Available members:
  1. Amit K (OCfj8A8U5XOTQdMMVeHkUo6VNfG2)
  2. Amit Kumar (x4MuuyzImKV0ohzJWJ8CXtmKhak1)

Select member number (or enter UID directly, or 's' to skip): 1

Enter description (or 's' to skip): Manual credit for August event

Will update with: {'uid': 'OCfj8A8U5XOTQdMMVeHkUo6VNfG2', 'description': 'Manual credit for August event'}
Type 'yes' to confirm: yes
✓ Updated successfully!
```

---

### 04_cleanup_orphaned_user_memberships.py

Removes orphaned entries from the denormalized userGroupMemberships index.

**What it does:**
- Finds userGroupMemberships entries where the user is no longer in the group
- Removes stale index entries
- Happens when users leave groups and the index wasn't cleaned up

**Usage:**
```bash
# Dry run (see what would be deleted)
python datafix/04_cleanup_orphaned_user_memberships.py --dry-run

# Actually delete the orphaned entries
python datafix/04_cleanup_orphaned_user_memberships.py
```

**Example output:**
```
Found 1 orphaned entries:

1. User ID: 8ulkM3MJ0KeV063HnR303eyVqgo2
   Group: Sunridge Saturday (CEF0nH3ajo6DjXJs5GY6)
   Issue: User not in group/members but has userGroupMemberships entry

Type 'yes' to confirm: yes
  ✓ Deleted: 8ulkM3MJ0KeV063HnR303eyVqgo2 from Sunridge Saturday

SUMMARY:
Orphaned entries found: 1
Deleted:                1
Errors:                 0
```

---

### 05_cleanup_orphaned_firestore_users.py

Removes user documents from Firestore that don't exist in Firebase Auth.

**What it does:**
- Checks each Firestore user against Firebase Auth
- Identifies users deleted from Auth but still in Firestore
- Optionally removes orphaned user documents

**Usage:**
```bash
# List orphaned users (no changes)
python datafix/05_cleanup_orphaned_firestore_users.py --list-only

# Dry run
python datafix/05_cleanup_orphaned_firestore_users.py --dry-run

# Actually delete orphaned users (with confirmation)
python datafix/05_cleanup_orphaned_firestore_users.py
```

**Example output:**
```
Scanning for orphaned Firestore users...
(This may take a while as we check each user in Firebase Auth)

Found 1 orphaned users:

1. User ID: abc123xyz
   Email: deleted.user@example.com
   Name: Deleted User
   Created: 2025-01-15
   Issue: Exists in Firestore but not in Firebase Auth

⚠️  WARNING: DESTRUCTIVE OPERATION ⚠️
This will permanently delete user documents from Firestore.

Type 'yes' to confirm: yes
  ✓ Deleted: deleted.user@example.com (abc123xyz)

SUMMARY:
Orphaned users found: 1
Deleted:              1
Errors:               0
```

---

## Safety Features

All scripts include:
- **Confirmation prompts** before making changes
- **Dry-run mode** (where applicable) to preview changes
- **Detailed logging** of all operations
- **Error handling** with clear error messages
- **Summary reports** after completion

## Environment Variables

- `FIREBASE_SERVICE_ACCOUNT_PATH`: Path to service account JSON file (default: `serviceAccountKey.json` in project root)

## Workflow

1. **Always run in dry-run mode first** (where available)
2. **Review the output** carefully
3. **Run the actual fix** after confirming changes look correct
4. **Re-run tests** to verify the fix worked:
   ```bash
   cd tests
   pytest
   ```

## After Running Scripts

Once a data fix is complete and verified:
1. The script can remain in this folder for documentation
2. Add a note in this README about when it was run
3. No need to delete the script (might be useful for reference)

## Execution History

Track when each script was executed:

| Script | Date | By | Notes |
|--------|------|-----|-------|
| 01_initialize_max_event_capacity.py | YYYY-MM-DD | Your Name | Initial run |
| 02_fix_wallet_balances.py | YYYY-MM-DD | Your Name | Fixed mismatches |
| 03_fix_missing_transaction_fields.py | YYYY-MM-DD | Your Name | Fixed transactions |
| 04_cleanup_orphaned_user_memberships.py | YYYY-MM-DD | Your Name | Cleaned index |
| 05_cleanup_orphaned_firestore_users.py | YYYY-MM-DD | Your Name | Removed orphaned users |
