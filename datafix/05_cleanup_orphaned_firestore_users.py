#!/usr/bin/env python3
"""
Clean up orphaned Firestore user documents.

This script:
1. Finds user documents in Firestore that don't exist in Firebase Auth
2. Optionally removes them (with confirmation)

This happens when:
- User is deleted from Firebase Auth but not from Firestore
- Manual Auth deletion without cleanup
- Data lifecycle management issue

Usage:
    python datafix/05_cleanup_orphaned_firestore_users.py

    # Dry run (don't actually delete)
    python datafix/05_cleanup_orphaned_firestore_users.py --dry-run

    # List only (same as dry-run)
    python datafix/05_cleanup_orphaned_firestore_users.py --list-only

Environment Variables:
    FIREBASE_SERVICE_ACCOUNT_PATH: Path to service account JSON file

WARNING: This script will delete user data. Make sure you have backups!
"""

import sys
from pathlib import Path
import argparse
from firebase_admin import auth

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from datafix.firebase_utils import init_firebase, confirm_action


def find_orphaned_users(db):
    """
    Find all Firestore users without Firebase Auth accounts.

    Args:
        db: Firestore client

    Returns:
        list: List of orphaned users with user_id, email, etc.
    """
    orphaned = []
    auth_errors = []

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        email = user_data.get('email', 'Unknown')

        try:
            # Try to get the user from Firebase Auth
            auth.get_user(user_id)
            # User exists in Auth - no problem
        except auth.UserNotFoundError:
            # User doesn't exist in Firebase Auth - orphaned!
            orphaned.append({
                'user_id': user_id,
                'email': email,
                'display_name': user_data.get('displayName', 'Unknown'),
                'created_at': user_data.get('createdAt'),
                'doc_ref': user_doc.reference
            })
        except Exception as e:
            # API error
            auth_errors.append({
                'user_id': user_id,
                'email': email,
                'error': str(e)
            })

    return orphaned, auth_errors


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(description='Clean up orphaned Firestore users')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be deleted without actually deleting')
    parser.add_argument('--list-only', action='store_true',
                        help='Only list orphaned users without deleting')
    args = parser.parse_args()

    dry_run = args.dry_run or args.list_only

    print("=" * 80)
    print("Clean Up Orphaned Firestore Users")
    print("=" * 80)
    if dry_run:
        print("*** DRY RUN MODE - No changes will be made ***\n")

    # Initialize Firebase
    app, db = init_firebase()

    print("\nScanning for orphaned Firestore users...")
    print("(This may take a while as we check each user in Firebase Auth)")

    orphaned, auth_errors = find_orphaned_users(db)

    if auth_errors:
        print(f"\n⚠ Warning: {len(auth_errors)} errors checking Auth:")
        for error in auth_errors[:3]:
            print(f"  - {error['email']}: {error['error']}")
        if len(auth_errors) > 3:
            print(f"  ... and {len(auth_errors) - 3} more")

    if not orphaned:
        print("\n✓ No orphaned users found!")
        return

    print(f"\nFound {len(orphaned)} orphaned users:")
    for i, user in enumerate(orphaned, 1):
        created = user['created_at']
        created_str = created.strftime('%Y-%m-%d') if hasattr(created, 'strftime') else 'Unknown'
        print(f"\n{i}. User ID: {user['user_id']}")
        print(f"   Email: {user['email']}")
        print(f"   Name: {user['display_name']}")
        print(f"   Created: {created_str}")
        print(f"   Issue: Exists in Firestore but not in Firebase Auth")

    if dry_run or args.list_only:
        print("\n(Use without --dry-run to delete these users)")
        return

    # WARNING
    print("\n" + "=" * 80)
    print("⚠️  WARNING: DESTRUCTIVE OPERATION ⚠️")
    print("=" * 80)
    print("This will permanently delete user documents from Firestore.")
    print("This does NOT delete their Auth accounts (already gone).")
    print("Make sure you have backups before proceeding!")

    # Get confirmation
    if not confirm_action(
        f"\nPermanently delete {len(orphaned)} orphaned user documents from Firestore?"
    ):
        print("Aborted.")
        return

    # Delete orphaned users
    print("\nDeleting orphaned user documents...")
    deleted_count = 0
    error_count = 0

    for user in orphaned:
        try:
            user['doc_ref'].delete()
            print(f"  ✓ Deleted: {user['email']} ({user['user_id']})")
            deleted_count += 1
        except Exception as e:
            error_count += 1
            print(f"  ✗ Error deleting {user['email']}: {e}")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Orphaned users found: {len(orphaned)}")
    print(f"Deleted:              {deleted_count}")
    print(f"Errors:               {error_count}")

    if deleted_count > 0:
        print("\n✓ Orphaned users cleaned up successfully!")
        print("\nNote: You may also want to:")
        print("  - Remove these users from group memberships")
        print("  - Archive their transaction history")
        print("  - Clean up userGroupMemberships index")


if __name__ == '__main__':
    main()
