#!/usr/bin/env python3
"""
Fix wallet balance mismatches by recalculating from transaction history.

This script:
1. Finds all group members with wallet balances
2. Recalculates balance from transaction history
3. Updates balances that don't match

Usage:
    python datafix/02_fix_wallet_balances.py

    # Dry run (don't actually update)
    python datafix/02_fix_wallet_balances.py --dry-run

Environment Variables:
    FIREBASE_SERVICE_ACCOUNT_PATH: Path to service account JSON file
"""

import sys
from pathlib import Path
import argparse

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from datafix.firebase_utils import init_firebase, confirm_action


def calculate_balance_from_transactions(db, group_id, user_id):
    """
    Calculate wallet balance from transaction history.

    Args:
        db: Firestore client
        group_id: Group ID
        user_id: User ID

    Returns:
        tuple: (calculated_balance, transaction_count)
    """
    transactions = db.collection('transactions') \
        .where('groupId', '==', group_id) \
        .where('uid', '==', user_id) \
        .stream()

    balance = 0
    count = 0

    for transaction_doc in transactions:
        transaction_data = transaction_doc.to_dict()
        transaction_type = transaction_data.get('type', '')
        amount = transaction_data.get('amount', 0)

        # Credit types add to balance (credit, credit_manual, etc.)
        if transaction_type.startswith('credit'):
            balance += amount
        # Debit types subtract from balance (debit, debit_manual, etc.)
        elif transaction_type.startswith('debit'):
            balance -= amount
        # Ignore unknown transaction types (shouldn't happen in production)

        count += 1

    return balance, count


def main():
    """Main execution function."""
    parser = argparse.ArgumentParser(description='Fix wallet balance mismatches')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show what would be changed without actually updating')
    args = parser.parse_args()

    print("=" * 80)
    print("Fix Wallet Balance Mismatches")
    print("=" * 80)
    if args.dry_run:
        print("*** DRY RUN MODE - No changes will be made ***\n")

    # Initialize Firebase
    app, db = init_firebase()

    if not args.dry_run:
        if not confirm_action(
            "This will recalculate and update wallet balances from transaction history."
        ):
            print("Aborted.")
            return

    print("\nProcessing groups and members...")

    # Get all groups
    groups = db.collection('groups').stream()

    total_checked = 0
    total_mismatches = 0
    total_fixed = 0
    mismatches = []

    for group_doc in groups:
        group_id = group_doc.id
        group_data = group_doc.to_dict()
        group_name = group_data.get('name', 'Unknown')

        # Get all members with wallet balances
        members = db.collection('groups').document(group_id).collection('members').stream()

        for member_doc in members:
            user_id = member_doc.id
            member_data = member_doc.to_dict()

            # Skip if no wallet balance field
            if 'walletBalance' not in member_data:
                continue

            stored_balance = member_data.get('walletBalance', 0)
            total_checked += 1

            # Calculate balance from transactions
            calculated_balance, transaction_count = calculate_balance_from_transactions(
                db, group_id, user_id
            )

            # Check for mismatch
            if stored_balance != calculated_balance:
                difference = stored_balance - calculated_balance
                display_name = member_data.get('displayName', 'Unknown')

                mismatch_info = {
                    'group_id': group_id,
                    'group_name': group_name,
                    'user_id': user_id,
                    'display_name': display_name,
                    'stored_balance': stored_balance,
                    'calculated_balance': calculated_balance,
                    'difference': difference,
                    'transaction_count': transaction_count
                }
                mismatches.append(mismatch_info)
                total_mismatches += 1

                print(f"\n  ⚠ Mismatch found:")
                print(f"     Group: {group_name}")
                print(f"     User: {display_name} ({user_id})")
                print(f"     Stored balance: {stored_balance}")
                print(f"     Calculated balance: {calculated_balance}")
                print(f"     Difference: {difference}")
                print(f"     Transactions: {transaction_count}")

                # Update if not dry run
                if not args.dry_run:
                    try:
                        db.collection('groups').document(group_id) \
                            .collection('members').document(user_id) \
                            .update({'walletBalance': calculated_balance})
                        print(f"     ✓ Updated balance to {calculated_balance}")
                        total_fixed += 1
                    except Exception as e:
                        print(f"     ✗ Error updating: {e}")
                else:
                    print(f"     [DRY RUN] Would update to {calculated_balance}")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total wallets checked:  {total_checked}")
    print(f"Mismatches found:       {total_mismatches}")
    if not args.dry_run:
        print(f"Fixed:                  {total_fixed}")
    else:
        print(f"Would fix:              {total_mismatches}")

    if total_mismatches == 0:
        print("\n✓ All wallet balances are correct!")
    elif args.dry_run:
        print(f"\nRe-run without --dry-run to apply fixes.")
    else:
        print(f"\n✓ Wallet balances fixed successfully!")


if __name__ == '__main__':
    main()
