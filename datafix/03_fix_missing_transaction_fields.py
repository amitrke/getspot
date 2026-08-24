#!/usr/bin/env python3
"""
Fix missing fields in manual credit transactions.

This script:
1. Finds transactions with missing required fields (uid, description)
2. Attempts to infer uid from the transaction path or related data
3. Provides interactive prompts to fill in missing data

Usage:
    python datafix/03_fix_missing_transaction_fields.py

    # Just list the issues without fixing
    python datafix/03_fix_missing_transaction_fields.py --list-only

Environment Variables:
    FIREBASE_SERVICE_ACCOUNT_PATH: Path to service account JSON file
"""

import sys
from pathlib import Path
import argparse
from datetime import datetime

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from datafix.firebase_utils import init_firebase, confirm_action


def find_transactions_with_missing_fields(db):
    """
    Find all transactions with missing required fields.

    Args:
        db: Firestore client

    Returns:
        list: List of transaction documents with missing fields
    """
    transactions = db.collection('transactions').stream()

    issues = []
    required_fields = ['uid', 'description']

    for transaction_doc in transactions:
        transaction_data = transaction_doc.to_dict()
        transaction_id = transaction_doc.id

        missing_fields = []
        for field in required_fields:
            if field not in transaction_data or transaction_data[field] is None:
                missing_fields.append(field)

        if missing_fields:
            issues.append({
                'id': transaction_id,
                'data': transaction_data,
                'missing_fields': missing_fields
            })

    return issues


def format_timestamp(timestamp):
    """Format Firestore timestamp for display."""
    if timestamp and hasattr(timestamp, 'timestamp'):
        dt = datetime.fromtimestamp(timestamp.timestamp())
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    return 'Unknown'


def fix_transaction_interactive(db, transaction):
    """
    Interactively fix a transaction's missing fields.

    Args:
        db: Firestore client
        transaction: Transaction dict with id, data, missing_fields

    Returns:
        bool: True if fixed, False if skipped
    """
    transaction_id = transaction['id']
    transaction_data = transaction['data']
    missing_fields = transaction['missing_fields']

    print("\n" + "=" * 60)
    print(f"Transaction ID: {transaction_id}")
    print(f"Type: {transaction_data.get('type', 'unknown')}")
    print(f"Amount: {transaction_data.get('amount', 0)}")
    print(f"Created: {format_timestamp(transaction_data.get('createdAt'))}")
    print(f"Group ID: {transaction_data.get('groupId', 'unknown')}")
    print(f"Missing fields: {', '.join(missing_fields)}")
    print("=" * 60)

    updates = {}

    # Handle missing uid
    if 'uid' in missing_fields:
        # Try to suggest uid based on group members
        group_id = transaction_data.get('groupId')
        if group_id:
            print(f"\nFetching members from group {group_id}...")
            members = db.collection('groups').document(group_id).collection('members').limit(10).stream()
            member_list = [(m.id, m.to_dict().get('displayName', 'Unknown')) for m in members]

            if member_list:
                print("\nAvailable members:")
                for i, (uid, name) in enumerate(member_list, 1):
                    print(f"  {i}. {name} ({uid})")

                choice = input("\nSelect member number (or enter UID directly, or 's' to skip): ").strip()

                if choice.lower() == 's':
                    return False
                elif choice.isdigit() and 1 <= int(choice) <= len(member_list):
                    updates['uid'] = member_list[int(choice) - 1][0]
                else:
                    updates['uid'] = choice
            else:
                uid = input("\nEnter UID (or 's' to skip): ").strip()
                if uid.lower() == 's':
                    return False
                updates['uid'] = uid

    # Handle missing description
    if 'description' in missing_fields:
        description = input("\nEnter description (or 's' to skip): ").strip()
        if description.lower() == 's':
            return False
        updates['description'] = description

    # Confirm update
    if updates:
        print(f"\nWill update with: {updates}")
        if confirm_action("Apply this update?"):
            try:
                db.collection('transactions').document(transaction_id).update(updates)
                print("✓ Updated successfully!")
                return True
            except Exception as e:
                print(f"✗ Error updating: {e}")
                return False

    return False


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(description='Fix missing transaction fields')
    parser.add_argument('--list-only', action='store_true',
                        help='Only list issues without attempting to fix')
    args = parser.parse_args()

    print("=" * 80)
    print("Fix Missing Transaction Fields")
    print("=" * 80)

    # Initialize Firebase
    app, db = init_firebase()

    print("\nScanning transactions for missing fields...")

    issues = find_transactions_with_missing_fields(db)

    if not issues:
        print("\n✓ No transactions with missing fields found!")
        return

    print(f"\nFound {len(issues)} transaction(s) with missing fields:")

    for i, transaction in enumerate(issues, 1):
        print(f"\n{i}. Transaction {transaction['id']}")
        print(f"   Type: {transaction['data'].get('type', 'unknown')}")
        print(f"   Created: {format_timestamp(transaction['data'].get('createdAt'))}")
        print(f"   Missing: {', '.join(transaction['missing_fields'])}")

    if args.list_only:
        print("\n(Use without --list-only to fix interactively)")
        return

    # Interactive fixing
    print("\n" + "=" * 80)
    print("Interactive Fixing")
    print("=" * 80)

    fixed_count = 0

    for transaction in issues:
        if fix_transaction_interactive(db, transaction):
            fixed_count += 1

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total issues found: {len(issues)}")
    print(f"Fixed: {fixed_count}")
    print(f"Remaining: {len(issues) - fixed_count}")

    if fixed_count > 0:
        print("\n✓ Transaction fields updated successfully!")


if __name__ == '__main__':
    main()
