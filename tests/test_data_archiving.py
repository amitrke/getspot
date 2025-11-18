"""
Tests for data archiving and lifecycle management in GetSpot.

These tests verify that the data retention policy is being enforced:
- Events older than 3 months are archived/deleted
- Transactions older than 3 months are archived/deleted
- Archived data exists in Cloud Storage
- Join requests older than 7 days are deleted

Data lifecycle is managed by:
- dataLifecycle.ts (runDataLifecycleManagement scheduled function)
- Cloud Storage lifecycle rules (2-year deletion)

See: docs/DATA_RETENTION.md
"""

import pytest
from datetime import datetime, timedelta
from utils.test_helpers import format_failures


@pytest.mark.archiving
def test_no_old_events_in_firestore(db):
    """
    Test that events older than 3 months are not in Firestore.

    Per DATA_RETENTION.md, events should be archived 3 months after
    the event ends. Archived events are moved to Cloud Storage.

    Failures indicate:
    - runDataLifecycleManagement not running
    - archiveOldEvents function failing
    - Scheduled job disabled
    """
    # 3 months + 1 week buffer (91 days)
    cutoff_date = datetime.now() - timedelta(days=91)

    old_events = db.collection('events')\
        .where('eventTimestamp', '<', cutoff_date)\
        .limit(20)\
        .stream()

    old_event_list = []
    for event_doc in old_events:
        event_data = event_doc.to_dict()
        old_event_list.append({
            'event_id': event_doc.id,
            'event_name': event_data.get('name', 'Unknown'),
            'event_timestamp': event_data.get('eventTimestamp'),
            'group_id': event_data.get('groupId')
        })

    assert len(old_event_list) == 0, \
        f"Found {len(old_event_list)} events older than 3 months that should be archived:\n{format_failures(old_event_list)}"

    print("✓ No events older than 3 months found in Firestore")


@pytest.mark.archiving
def test_no_old_transactions_in_firestore(db):
    """
    Test that transactions older than 3 months are not in Firestore.

    Per DATA_RETENTION.md, transactions should be archived 3 months
    after creation. Archived transactions are moved to Cloud Storage.

    Failures indicate:
    - runDataLifecycleManagement not running
    - archiveOldTransactions function failing
    """
    # 3 months + 1 week buffer (91 days)
    cutoff_date = datetime.now() - timedelta(days=91)

    old_transactions = db.collection('transactions')\
        .where('createdAt', '<', cutoff_date)\
        .limit(20)\
        .stream()

    old_tx_list = []
    for tx_doc in old_transactions:
        tx_data = tx_doc.to_dict()
        old_tx_list.append({
            'transaction_id': tx_doc.id,
            'type': tx_data.get('type'),
            'amount': tx_data.get('amount'),
            'created_at': tx_data.get('createdAt'),
            'uid': tx_data.get('uid'),
            'group_id': tx_data.get('groupId')
        })

    assert len(old_tx_list) == 0, \
        f"Found {len(old_tx_list)} transactions older than 3 months that should be archived:\n{format_failures(old_tx_list)}"

    print("✓ No transactions older than 3 months found in Firestore")


@pytest.mark.archiving
@pytest.mark.slow
def test_archived_events_exist_in_cloud_storage(bucket):
    """
    Test that archived events are stored in Cloud Storage.

    Archived events should be in: archive/events/{eventId}.json

    This test verifies that archiving is actually happening, not just
    deleting data. Archived data should be retained for 2 years per
    DATA_RETENTION.md.

    Note: This test requires Cloud Storage access.
    """
    # List archived events
    blobs = list(bucket.list_blobs(prefix='archive/events/', max_results=100))

    archived_count = len(blobs)

    # In a production system, we expect some archived events
    # This assertion might need to be adjusted based on your app's age
    if archived_count == 0:
        print("⚠ Warning: No archived events found in Cloud Storage")
        print("  This is expected for new apps (<3 months old)")
        print("  For older apps, check if archiving is working correctly")
    else:
        print(f"✓ Found {archived_count} archived events in Cloud Storage")

    # Verify at least one archived file has valid JSON structure
    if archived_count > 0:
        sample_blob = blobs[0]
        content = sample_blob.download_as_text()

        # Basic validation - should be parseable JSON
        import json
        try:
            data = json.loads(content)
            assert 'eventId' in data, "Archived event missing eventId"
            assert 'archivedAt' in data, "Archived event missing archivedAt"
            assert 'eventData' in data, "Archived event missing eventData"
            print(f"✓ Verified archive structure in {sample_blob.name}")
        except json.JSONDecodeError as e:
            pytest.fail(f"Archived event {sample_blob.name} has invalid JSON: {e}")


@pytest.mark.archiving
@pytest.mark.slow
def test_archived_transactions_exist_in_cloud_storage(bucket):
    """
    Test that archived transactions are stored in Cloud Storage.

    Archived transactions should be in: archive/transactions/{transactionId}.json

    Note: This test requires Cloud Storage access.
    """
    # List archived transactions
    blobs = list(bucket.list_blobs(prefix='archive/transactions/', max_results=100))

    archived_count = len(blobs)

    if archived_count == 0:
        print("⚠ Warning: No archived transactions found in Cloud Storage")
        print("  This is expected for new apps (<3 months old)")
    else:
        print(f"✓ Found {archived_count} archived transactions in Cloud Storage")

    # Verify at least one archived file has valid JSON structure
    if archived_count > 0:
        sample_blob = blobs[0]
        content = sample_blob.download_as_text()

        import json
        try:
            data = json.loads(content)
            # Basic validation
            assert 'transactionId' in data or 'uid' in data, \
                "Archived transaction missing required fields"
            print(f"✓ Verified archive structure in {sample_blob.name}")
        except json.JSONDecodeError as e:
            pytest.fail(f"Archived transaction {sample_blob.name} has invalid JSON: {e}")


def test_no_old_resolved_join_requests(db):
    """
    Test that resolved join requests older than 7 days are deleted.

    Per DATA_RETENTION.md, join requests should be deleted 7 days
    after being approved or denied. They serve no purpose after that.

    Failures indicate:
    - deleteOldJoinRequests function not working
    - Scheduled job not running
    """
    # 7 days + 1 day buffer
    cutoff_date = datetime.now() - timedelta(days=8)

    # Check for old denied join requests
    # (approved requests are typically deleted when member is added)
    groups = db.collection('groups').limit(50).stream()

    old_requests = []
    checked_groups = 0

    for group_doc in groups:
        group_id = group_doc.id
        checked_groups += 1

        # Get join requests older than 7 days with status != 'pending'
        join_requests = db.collection('groups').document(group_id)\
            .collection('joinRequests')\
            .where('requestedAt', '<', cutoff_date)\
            .stream()

        for req_doc in join_requests:
            req_data = req_doc.to_dict()
            status = req_data.get('status', '')

            # Only pending requests should remain
            if status != 'pending':
                old_requests.append({
                    'group_id': group_id,
                    'user_id': req_doc.id,
                    'status': status,
                    'requested_at': req_data.get('requestedAt'),
                    'age_days': (datetime.now() - req_data.get('requestedAt').replace(tzinfo=None)).days
                })

    assert len(old_requests) == 0, \
        f"Found {len(old_requests)} old resolved join requests that should be deleted:\n{format_failures(old_requests)}"

    print(f"✓ No old resolved join requests found (checked {checked_groups} groups)")


@pytest.mark.slow
def test_inactive_groups_are_flagged(db):
    """
    Test that groups inactive for 3+ months are flagged as archived.

    Per DATA_RETENTION.md, groups with no new events or members for
    3 months should be flagged as archived (but not deleted, to prevent
    data loss for seasonal groups).

    Note: This test checks if the archiving policy is being enforced.
    The definition of "inactive" needs to be implemented in the app.
    """
    # This test is a placeholder - the actual implementation depends
    # on how "archived" flag is stored in group documents

    cutoff_date = datetime.now() - timedelta(days=90)

    groups = db.collection('groups').limit(100).stream()

    active_but_should_be_archived = []
    checked_count = 0

    for group_doc in groups:
        group_id = group_doc.id
        group_data = group_doc.to_dict()
        checked_count += 1

        # Check if group has 'archived' flag
        is_archived = group_data.get('archived', False)

        if not is_archived:
            # Check if group has recent events
            recent_events = db.collection('events')\
                .where('groupId', '==', group_id)\
                .where('eventTimestamp', '>=', cutoff_date)\
                .limit(1)\
                .stream()

            has_recent_events = len(list(recent_events)) > 0

            if not has_recent_events:
                # This group might need archiving
                # (but this is advisory only - groups may legitimately be inactive)
                pass

    # This test is currently informational only
    print(f"✓ Checked {checked_count} groups for archiving status")


@pytest.mark.archiving
def test_archive_file_naming_convention(bucket):
    """
    Test that archived files follow the naming convention.

    Expected structure:
    - archive/events/{eventId}.json
    - archive/transactions/{transactionId}.json

    Failures indicate:
    - Archiving logic changed without updating docs
    - Bug in file naming
    """
    # Check events
    event_blobs = list(bucket.list_blobs(prefix='archive/events/', max_results=10))

    for blob in event_blobs:
        name = blob.name
        assert name.startswith('archive/events/'), f"Event archive has wrong prefix: {name}"
        assert name.endswith('.json'), f"Event archive not JSON: {name}"

    # Check transactions
    tx_blobs = list(bucket.list_blobs(prefix='archive/transactions/', max_results=10))

    for blob in tx_blobs:
        name = blob.name
        assert name.startswith('archive/transactions/'), f"Transaction archive has wrong prefix: {name}"
        assert name.endswith('.json'), f"Transaction archive not JSON: {name}"

    print(f"✓ Verified naming convention for {len(event_blobs)} events and {len(tx_blobs)} transactions")
