"""
Tests for wallet and transaction consistency in GetSpot.

These tests verify that:
1. Wallet balances match the sum of all transactions
2. No balances exceed the negative balance limit
3. All transactions have required fields
4. Transaction amounts are valid

Wallet operations are performed by:
- manageGroupMember.ts (credit action)
- processEventRegistration.ts (debit for registration)
- withdrawFromEvent.ts (refund)
- cancelEvent.ts (refund all participants)
"""

import pytest
from utils.test_helpers import format_failures


def test_wallet_balance_matches_transaction_sum(db, test_config):
    """
    Test that wallet balance equals sum of all credit and debit transactions.

    This is the most critical financial integrity test.

    Transaction types:
    - credit: Adds to balance (admin credits wallet)
    - debit: Subtracts from balance (event registration fee)

    Failures indicate:
    - Transaction not recorded
    - Wallet balance updated without transaction
    - Transaction amount doesn't match wallet change
    - Floating point precision error
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    # Get all groups
    groups = db.collection('groups').stream()

    for group_doc in groups:
        group_id = group_doc.id
        group_name = group_doc.to_dict().get('name', 'Unknown')

        # Get all members
        members = db.collection('groups').document(group_id)\
            .collection('members').stream()

        for member_doc in members:
            user_id = member_doc.id
            member_data = member_doc.to_dict()
            stored_balance = member_data.get('walletBalance', 0)
            checked_count += 1

            # Calculate balance from transactions
            transactions = db.collection('transactions')\
                .where('groupId', '==', group_id)\
                .where('uid', '==', user_id)\
                .stream()

            calculated_balance = 0.0
            tx_count = 0

            for tx in transactions:
                tx_data = tx.to_dict()
                amount = float(tx_data.get('amount', 0))
                tx_type = tx_data.get('type')
                tx_count += 1

                if tx_type == 'credit':
                    calculated_balance += amount
                elif tx_type == 'debit':
                    calculated_balance -= amount
                else:
                    # Unknown transaction type
                    failures.append({
                        'type': 'unknown_transaction_type',
                        'group_id': group_id,
                        'user_id': user_id,
                        'transaction_id': tx.id,
                        'transaction_type': tx_type
                    })

            # Allow small floating point differences (0.01)
            difference = abs(float(stored_balance) - calculated_balance)
            if difference > 0.01:
                failures.append({
                    'type': 'balance_mismatch',
                    'group_id': group_id,
                    'group_name': group_name,
                    'user_id': user_id,
                    'display_name': member_data.get('displayName', 'Unknown'),
                    'stored_balance': stored_balance,
                    'calculated_balance': round(calculated_balance, 2),
                    'difference': round(difference, 2),
                    'transaction_count': tx_count
                })

                if len(failures) >= max_failures:
                    break

        if len(failures) >= max_failures:
            break

    summary = f"Checked {checked_count} wallets, found {len(failures)} inconsistencies"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_negative_balance_within_limits(db, test_config):
    """
    Test that negative balances don't exceed group's negativeBalanceLimit.

    Each group has a configurable limit for how negative a member's
    balance can go. This prevents members from accumulating unlimited debt.

    Failures indicate:
    - Validation not enforced during event registration
    - Manual wallet modification
    - Limit changed after balances already exceeded it
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    groups = db.collection('groups').stream()

    for group_doc in groups:
        group_id = group_doc.id
        group_data = group_doc.to_dict()
        group_name = group_data.get('name', 'Unknown')
        neg_limit = float(group_data.get('negativeBalanceLimit', 0))

        members = db.collection('groups').document(group_id)\
            .collection('members').stream()

        for member_doc in members:
            member_data = member_doc.to_dict()
            balance = float(member_data.get('walletBalance', 0))
            checked_count += 1

            # Check if balance is below the limit (more negative than allowed)
            if balance < -neg_limit:
                violation_amount = abs(balance + neg_limit)
                failures.append({
                    'group_id': group_id,
                    'group_name': group_name,
                    'user_id': member_doc.id,
                    'display_name': member_data.get('displayName', 'Unknown'),
                    'balance': balance,
                    'limit': -neg_limit,
                    'violation_amount': round(violation_amount, 2)
                })

                if len(failures) >= max_failures:
                    break

        if len(failures) >= max_failures:
            break

    summary = f"Checked {checked_count} wallets, found {len(failures)} violations"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_transaction_has_required_fields(db, test_config):
    """
    Test that all transactions have required fields.

    Required fields per DATA_MODEL.md:
    - uid: The user involved
    - groupId: The group in which the transaction occurred
    - type: 'credit' or 'debit'
    - amount: Positive value of the transaction
    - description: Human-readable description
    - createdAt: Server timestamp

    Failures indicate:
    - Cloud Function not setting all fields
    - Schema change not applied consistently
    """
    required_fields = ['uid', 'groupId', 'type', 'amount', 'description', 'createdAt']

    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    # Sample transactions (limit to avoid long-running test)
    transactions = db.collection('transactions').limit(1000).stream()

    for tx_doc in transactions:
        tx_id = tx_doc.id
        tx_data = tx_doc.to_dict()
        checked_count += 1

        missing_fields = []
        for field in required_fields:
            if field not in tx_data or tx_data[field] is None:
                missing_fields.append(field)

        if missing_fields:
            failures.append({
                'transaction_id': tx_id,
                'missing_fields': missing_fields,
                'type': tx_data.get('type', 'unknown'),
                'created_at': tx_data.get('createdAt')
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} transactions, found {len(failures)} with missing fields"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_transaction_amounts_are_positive(db, test_config):
    """
    Test that all transaction amounts are positive numbers.

    Per DATA_MODEL.md, the 'amount' field should always be a positive
    absolute value. The 'type' field (credit/debit) determines the direction.

    Failures indicate:
    - Bug in transaction creation logic
    - Manual database modification
    - Type confusion (storing negative amounts for debits)
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    transactions = db.collection('transactions').limit(1000).stream()

    for tx_doc in transactions:
        tx_id = tx_doc.id
        tx_data = tx_doc.to_dict()
        amount = tx_data.get('amount')
        checked_count += 1

        if amount is None:
            continue  # Caught by test_transaction_has_required_fields

        amount = float(amount)

        if amount <= 0:
            failures.append({
                'transaction_id': tx_id,
                'amount': amount,
                'type': tx_data.get('type'),
                'description': tx_data.get('description'),
                'uid': tx_data.get('uid'),
                'group_id': tx_data.get('groupId')
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} transactions, found {len(failures)} with non-positive amounts"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


@pytest.mark.slow
def test_all_members_have_wallet_balance_field(db):
    """
    Test that all group members have a walletBalance field.

    This field should be initialized when a member joins the group.

    Failures indicate:
    - Member added before wallet system implemented
    - Migration not completed
    - Manual database modification
    """
    failures = []
    checked_count = 0

    groups = db.collection('groups').stream()

    for group_doc in groups:
        group_id = group_doc.id
        group_name = group_doc.to_dict().get('name', 'Unknown')

        members = db.collection('groups').document(group_id)\
            .collection('members').stream()

        for member_doc in members:
            member_data = member_doc.to_dict()
            checked_count += 1

            if 'walletBalance' not in member_data:
                failures.append({
                    'group_id': group_id,
                    'group_name': group_name,
                    'user_id': member_doc.id,
                    'display_name': member_data.get('displayName', 'Unknown')
                })

    assert len(failures) == 0, \
        f"Found {len(failures)} members missing walletBalance field:\n{format_failures(failures)}"

    print(f"✓ All {checked_count} members have walletBalance field")


@pytest.mark.slow
def test_transaction_references_valid_group_and_user(db, test_config):
    """
    Test that all transactions reference existing groups and users.

    Orphaned transactions indicate:
    - Group or user deleted but transactions not archived
    - Data lifecycle management not working
    - Referential integrity issue
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    # Cache groups and users for efficiency
    groups_cache = {g.id: True for g in db.collection('groups').stream()}
    users_cache = {u.id: True for u in db.collection('users').stream()}

    transactions = db.collection('transactions').limit(1000).stream()

    for tx_doc in transactions:
        tx_data = tx_doc.to_dict()
        tx_id = tx_doc.id
        group_id = tx_data.get('groupId')
        user_id = tx_data.get('uid')
        checked_count += 1

        if group_id and group_id not in groups_cache:
            failures.append({
                'transaction_id': tx_id,
                'issue': 'orphaned_group',
                'group_id': group_id,
                'user_id': user_id
            })

        if user_id and user_id not in users_cache:
            failures.append({
                'transaction_id': tx_id,
                'issue': 'orphaned_user',
                'group_id': group_id,
                'user_id': user_id
            })

        if len(failures) >= max_failures:
            break

    summary = f"Checked {checked_count} transactions, found {len(failures)} with invalid references"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"
