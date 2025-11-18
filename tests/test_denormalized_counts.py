"""
Tests for denormalized count consistency in GetSpot.

These tests verify that denormalized count fields match the actual
number of documents in subcollections. This is critical for app
performance and data integrity.

Denormalized counts tested:
- confirmedCount vs actual confirmed participants
- waitlistCount vs actual waitlisted participants
- pendingJoinRequestsCount vs actual pending join requests
"""

import pytest
from utils.test_helpers import format_failures


def test_event_confirmed_count_matches_actual(db, test_config):
    """
    Test that event.confirmedCount matches actual confirmed participants.

    This count is maintained by Cloud Functions:
    - processEventRegistration.ts
    - withdrawFromEvent.ts
    - updateEventCapacity.ts

    Failures indicate:
    - Function not updating count atomically
    - Race condition in event registration
    - Manual database modification
    """
    events = db.collection('events').stream()

    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    for event_doc in events:
        event_id = event_doc.id
        event_data = event_doc.to_dict()

        # Get denormalized count
        stored_count = event_data.get('confirmedCount', 0)

        # Count actual confirmed participants
        participants = db.collection('events').document(event_id)\
            .collection('participants')\
            .where('status', '==', 'confirmed')\
            .stream()

        actual_count = sum(1 for _ in participants)
        checked_count += 1

        if stored_count != actual_count:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'group_id': event_data.get('groupId', 'Unknown'),
                'stored_count': stored_count,
                'actual_count': actual_count,
                'difference': stored_count - actual_count
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} events, found {len(failures)} mismatches"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_event_waitlist_count_matches_actual(db, test_config):
    """
    Test that event.waitlistCount matches actual waitlisted participants.

    This count is maintained by Cloud Functions:
    - processEventRegistration.ts
    - withdrawFromEvent.ts
    - processWaitlist.ts (utility)

    Failures indicate:
    - Waitlist promotion not updating count
    - Event registration logic issue
    """
    events = db.collection('events').stream()

    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    for event_doc in events:
        event_id = event_doc.id
        event_data = event_doc.to_dict()

        stored_count = event_data.get('waitlistCount', 0)

        participants = db.collection('events').document(event_id)\
            .collection('participants')\
            .where('status', '==', 'waitlisted')\
            .stream()

        actual_count = sum(1 for _ in participants)
        checked_count += 1

        if stored_count != actual_count:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'stored_count': stored_count,
                'actual_count': actual_count,
                'difference': stored_count - actual_count
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} events, found {len(failures)} mismatches"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_pending_join_requests_count(db, test_config):
    """
    Test that group.pendingJoinRequestsCount matches actual pending requests.

    This count is maintained by Cloud Functions:
    - maintainJoinRequestCount.ts (3 Firestore triggers)
    - onJoinRequestCreated
    - onJoinRequestUpdated
    - onJoinRequestDeleted

    Failures indicate:
    - Trigger not firing correctly
    - Status update not captured
    - Race condition in join request flow
    """
    groups = db.collection('groups').stream()

    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    for group_doc in groups:
        group_id = group_doc.id
        group_data = group_doc.to_dict()

        stored_count = group_data.get('pendingJoinRequestsCount', 0)

        join_requests = db.collection('groups').document(group_id)\
            .collection('joinRequests')\
            .where('status', '==', 'pending')\
            .stream()

        actual_count = sum(1 for _ in join_requests)
        checked_count += 1

        if stored_count != actual_count:
            failures.append({
                'group_id': group_id,
                'group_name': group_data.get('name', 'Unknown'),
                'stored_count': stored_count,
                'actual_count': actual_count,
                'difference': stored_count - actual_count
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} groups, found {len(failures)} mismatches"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


@pytest.mark.slow
def test_all_events_have_count_fields(db):
    """
    Test that all events have confirmedCount and waitlistCount fields.

    These fields should be initialized when the event is created.
    Missing fields indicate:
    - Event created before denormalization was implemented
    - Manual database modification
    - Migration not completed
    """
    events = db.collection('events').stream()

    missing_confirmed = []
    missing_waitlist = []
    checked_count = 0

    for event_doc in events:
        event_id = event_doc.id
        event_data = event_doc.to_dict()
        checked_count += 1

        if 'confirmedCount' not in event_data:
            missing_confirmed.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown')
            })

        if 'waitlistCount' not in event_data:
            missing_waitlist.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown')
            })

    assert len(missing_confirmed) == 0, \
        f"Found {len(missing_confirmed)} events missing confirmedCount:\n{format_failures(missing_confirmed)}"

    assert len(missing_waitlist) == 0, \
        f"Found {len(missing_waitlist)} events missing waitlistCount:\n{format_failures(missing_waitlist)}"

    print(f"✓ All {checked_count} events have required count fields")


@pytest.mark.slow
def test_all_groups_have_pending_count_field(db):
    """
    Test that all groups have pendingJoinRequestsCount field.

    This field was added via migration (initializePendingJoinRequestsCount).
    Missing fields indicate:
    - Group created before migration
    - Migration not completed
    - Manual database modification
    """
    groups = db.collection('groups').stream()

    missing_count = []
    checked_count = 0

    for group_doc in groups:
        group_id = group_doc.id
        group_data = group_doc.to_dict()
        checked_count += 1

        if 'pendingJoinRequestsCount' not in group_data:
            missing_count.append({
                'group_id': group_id,
                'group_name': group_data.get('name', 'Unknown')
            })

    assert len(missing_count) == 0, \
        f"Found {len(missing_count)} groups missing pendingJoinRequestsCount:\n{format_failures(missing_count)}"

    print(f"✓ All {checked_count} groups have pendingJoinRequestsCount field")
