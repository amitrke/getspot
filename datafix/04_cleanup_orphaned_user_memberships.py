#!/usr/bin/env python3
"""
Clean up orphaned userGroupMemberships entries.

This script:
1. Finds userGroupMemberships entries where the user is no longer in the group
2. Removes the orphaned index entries

This happens when:
- User leaves a group
- User is removed from a group
- The denormalized index wasn't cleaned up properly

Usage:
    python datafix/04_cleanup_orphaned_user_memberships.py

    # Dry run (don't actually delete)
    python datafix/04_cleanup_orphaned_user_memberships.py --dry-run

Environment Variables:
    FIREBASE_SERVICE_ACCOUNT_PATH: Path to service account JSON file
"""

import sys
from pathlib import Path
import argparse

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from datafix.firebase_utils import init_firebase, confirm_action


def find_orphaned_memberships(db):
    """
    Find all orphaned userGroupMemberships entries.

    Args:
        db: Firestore client

    Returns:
        list: List of orphaned entries with user_id, group_id, group_name
    """
    orphaned = []

    # Use collection group query to get all userGroupMemberships entries
    user_memberships = db.collection_group('groups').stream()

    for membership_doc in user_memberships:
        # Extract user_id from document path
        # Path: userGroupMemberships/{userId}/groups/{groupId}
        parent = membership_doc.reference.parent.parent
        if parent is None:
            # Skip documents not at expected path
            continue

        user_id = parent.id
        group_id = membership_doc.id
        membership_data = membership_doc.to_dict()
        group_name = membership_data.get('groupName', 'Unknown')

        # Check if member exists in group
        member = db.collection('groups').document(group_id) \
            .collection('members').document(user_id).get()

        if not member.exists:
            orphaned.append({
                'user_id': user_id,
                'group_id': group_id,
                'group_name': group_name,
                'doc_ref': membership_doc.reference
            })

    return orphaned


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(description='Clean up orphaned userGroupMemberships')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be deleted without actually deleting')
    args = parser.parse_args()

    print("=" * 80)
    print("Clean Up Orphaned userGroupMemberships Entries")
    print("=" * 80)
    if args.dry_run:
        print("*** DRY RUN MODE - No changes will be made ***\n")

    # Initialize Firebase
    app, db = init_firebase()

    print("\nScanning for orphaned userGroupMemberships entries...")

    orphaned = find_orphaned_memberships(db)

    if not orphaned:
        print("\n✓ No orphaned entries found!")
        return

    print(f"\nFound {len(orphaned)} orphaned entries:")
    for i, entry in enumerate(orphaned, 1):
        print(f"\n{i}. User ID: {entry['user_id']}")
        print(f"   Group: {entry['group_name']} ({entry['group_id']})")
        print(f"   Issue: User not in group/members but has userGroupMemberships entry")

    if args.dry_run:
        print("\n(Use without --dry-run to delete these entries)")
        return

    # Get confirmation
    if not confirm_action(
        f"\nDelete {len(orphaned)} orphaned userGroupMemberships entries?"
    ):
        print("Aborted.")
        return

    # Delete orphaned entries
    print("\nDeleting orphaned entries...")
    deleted_count = 0
    error_count = 0

    for entry in orphaned:
        try:
            entry['doc_ref'].delete()
            print(f"  ✓ Deleted: {entry['user_id']} from {entry['group_name']}")
            deleted_count += 1
        except Exception as e:
            error_count += 1
            print(f"  ✗ Error deleting {entry['user_id']} from {entry['group_name']}: {e}")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Orphaned entries found: {len(orphaned)}")
    print(f"Deleted:                {deleted_count}")
    print(f"Errors:                 {error_count}")

    if deleted_count > 0:
        print("\n✓ Orphaned entries cleaned up successfully!")


if __name__ == '__main__':
    main()
