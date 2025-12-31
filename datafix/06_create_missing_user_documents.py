#!/usr/bin/env python3
"""
Create missing Firestore user documents for users who exist in groups but not in /users.

This script:
1. Finds users who are group members but missing from /users collection
2. Fetches their data from Firebase Auth
3. Creates the missing Firestore user documents

This happens when:
- User authenticated but Firestore document creation failed
- User document was manually deleted
- Race condition during signup

Usage:
    python datafix/06_create_missing_user_documents.py

    # Dry run (don't actually create)
    python datafix/06_create_missing_user_documents.py --dry-run

Environment Variables:
    FIREBASE_SERVICE_ACCOUNT_PATH: Path to service account JSON file
"""

import sys
from pathlib import Path
import argparse
from firebase_admin import auth
from google.cloud.firestore import SERVER_TIMESTAMP

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from datafix.firebase_utils import init_firebase, confirm_action


def find_missing_user_documents(db):
    """
    Find users who are group members but missing from /users collection.

    Args:
        db: Firestore client

    Returns:
        list: List of missing users with user_id, groups, etc.
    """
    # Build users cache
    users_cache = {u.id: True for u in db.collection('users').stream()}

    missing_users = {}  # user_id -> {groups, auth_data}

    # Check all group members
    groups = db.collection('groups').stream()

    for group_doc in groups:
        group_id = group_doc.id
        group_name = group_doc.to_dict().get('name', 'Unknown')

        members = db.collection('groups').document(group_id).collection('members').stream()

        for member_doc in members:
            user_id = member_doc.id
            member_data = member_doc.to_dict()

            if user_id not in users_cache:
                # Missing user - get their Auth data
                if user_id not in missing_users:
                    try:
                        auth_user = auth.get_user(user_id)
                        missing_users[user_id] = {
                            'user_id': user_id,
                            'auth_email': auth_user.email,
                            'auth_display_name': auth_user.display_name or auth_user.email,
                            'auth_photo_url': auth_user.photo_url,
                            'auth_disabled': auth_user.disabled,
                            'groups': [],
                            'member_display_name': member_data.get('displayName', 'Unknown')
                        }
                    except auth.UserNotFoundError:
                        # User doesn't exist in Auth either
                        missing_users[user_id] = {
                            'user_id': user_id,
                            'auth_email': None,
                            'auth_display_name': None,
                            'auth_photo_url': None,
                            'auth_disabled': None,
                            'groups': [],
                            'member_display_name': member_data.get('displayName', 'Unknown')
                        }
                    except Exception as e:
                        print(f"  ✗ Error fetching Auth for {user_id}: {e}")
                        continue

                # Add group to the list
                missing_users[user_id]['groups'].append({
                    'group_id': group_id,
                    'group_name': group_name
                })

    return list(missing_users.values())


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(description='Create missing user documents')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be created without actually creating')
    args = parser.parse_args()

    print("=" * 80)
    print("Create Missing User Documents")
    print("=" * 80)
    if args.dry_run:
        print("*** DRY RUN MODE - No changes will be made ***\n")

    # Initialize Firebase
    app, db = init_firebase()

    print("\nScanning for users in groups but missing from /users collection...")

    missing_users = find_missing_user_documents(db)

    if not missing_users:
        print("\n✓ No missing user documents found!")
        return

    print(f"\nFound {len(missing_users)} users missing from /users collection:")

    for i, user in enumerate(missing_users, 1):
        print(f"\n{i}. User ID: {user['user_id']}")
        print(f"   Display Name (from group): {user['member_display_name']}")

        if user['auth_email']:
            print(f"   Auth Email: {user['auth_email']}")
            print(f"   Auth Display Name: {user['auth_display_name']}")
            print(f"   Auth Disabled: {user['auth_disabled']}")
        else:
            print(f"   ⚠ WARNING: User does not exist in Firebase Auth!")

        print(f"   Member of {len(user['groups'])} group(s):")
        for group in user['groups']:
            print(f"     - {group['group_name']} ({group['group_id']})")

    if args.dry_run:
        print("\n(Use without --dry-run to create these user documents)")
        return

    # Get confirmation
    if not confirm_action(
        f"\nCreate {len(missing_users)} missing user documents in Firestore?"
    ):
        print("Aborted.")
        return

    # Create missing user documents
    print("\nCreating user documents...")
    created_count = 0
    skipped_count = 0
    error_count = 0

    for user in missing_users:
        user_id = user['user_id']

        # Skip if user doesn't exist in Auth
        if not user['auth_email']:
            print(f"  ⊘ Skipped: {user['member_display_name']} (no Auth account)")
            skipped_count += 1
            continue

        try:
            # Create user document
            user_doc_data = {
                'uid': user_id,
                'displayName': user['auth_display_name'],
                'email': user['auth_email'],
                'createdAt': SERVER_TIMESTAMP,
            }

            # Add optional fields if present
            if user['auth_photo_url']:
                user_doc_data['photoURL'] = user['auth_photo_url']

            db.collection('users').document(user_id).set(user_doc_data)

            print(f"  ✓ Created: {user['auth_email']} ({user_id})")
            created_count += 1

        except Exception as e:
            error_count += 1
            print(f"  ✗ Error creating {user['auth_email']}: {e}")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Missing user documents found: {len(missing_users)}")
    print(f"Created:                      {created_count}")
    print(f"Skipped (no Auth):            {skipped_count}")
    print(f"Errors:                       {error_count}")

    if created_count > 0:
        print("\n✓ User documents created successfully!")

    if skipped_count > 0:
        print(f"\n⚠ Warning: {skipped_count} users were skipped because they don't exist in Auth.")
        print("  Consider removing them from groups or investigating further.")


if __name__ == '__main__':
    main()
