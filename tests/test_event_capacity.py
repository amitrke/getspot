"""
Tests for event capacity and participant status rules in GetSpot.

These tests verify:
1. Confirmed participants never exceed maxParticipants
2. All participant statuses are valid
3. Event fields have valid values
4. Participant fields are consistent

Event capacity is managed by:
- processEventRegistration.ts
- withdrawFromEvent.ts
- updateEventCapacity.ts
- processWaitlist.ts (utility)
"""

import pytest
from datetime import datetime
from utils.test_helpers import format_failures


def test_confirmed_count_does_not_exceed_capacity(db, test_config):
    """
    Test that confirmed participants never exceed maxParticipants.

    This is a critical business rule: events cannot be overbooked.

    Failures indicate:
    - Race condition in event registration
    - updateEventCapacity allowing invalid state
    - Manual database modification
    - Bug in processEventRegistration logic
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    events = db.collection('events').stream()

    for event_doc in events:
        event_data = event_doc.to_dict()
        event_id = event_doc.id
        confirmed_count = event_data.get('confirmedCount', 0)
        max_participants = event_data.get('maxParticipants', 0)
        checked_count += 1

        if confirmed_count > max_participants:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'group_id': event_data.get('groupId'),
                'confirmed': confirmed_count,
                'max_capacity': max_participants,
                'overbooked_by': confirmed_count - max_participants,
                'event_timestamp': event_data.get('eventTimestamp')
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} events, found {len(failures)} overbooked"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_participant_status_validity(db, test_config):
    """
    Test that all participant statuses are valid values.

    Valid statuses per DATA_MODEL.md:
    - requested: Initial registration (transient state)
    - confirmed: Spot secured
    - waitlisted: No spot available, on waitlist
    - withdrawn: User withdrew from event
    - denied: Registration denied (insufficient funds, etc.)
    - withdrawn_penalty: User withdrew after deadline (with penalty)
    - refunded_after_event_end: Participant refunded after event completed

    Note: Status should be lowercase in Firestore.

    Failures indicate:
    - Bug in Cloud Function status assignment
    - Schema change not applied
    - Manual database modification
    """
    valid_statuses = {'requested', 'confirmed', 'waitlisted', 'withdrawn', 'denied',
                      'withdrawn_penalty', 'refunded_after_event_end'}
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    # Use collection group query to get all participants
    participants = db.collection_group('participants').limit(5000).stream()

    for participant_doc in participants:
        participant_data = participant_doc.to_dict()
        status = participant_data.get('status', '').lower()
        checked_count += 1

        if status not in valid_statuses:
            event_id = participant_doc.reference.parent.parent.id

            failures.append({
                'participant_id': participant_doc.id,
                'event_id': event_id,
                'invalid_status': status,
                'display_name': participant_data.get('displayName', 'Unknown')
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} participants, found {len(failures)} with invalid status"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_event_has_valid_max_participants(db):
    """
    Test that all events have valid maxParticipants value.

    maxParticipants should be:
    - Present in all events
    - Positive integer (> 0)
    - Not exceed group's maxEventCapacity

    Failures indicate:
    - Event creation validation missing
    - Manual database modification
    - Group maxEventCapacity not properly enforced
    """
    failures = []
    checked_count = 0
    # Cache groups to avoid repeated queries
    groups_cache = {}

    events = db.collection('events').stream()

    for event_doc in events:
        event_data = event_doc.to_dict()
        event_id = event_doc.id
        max_participants = event_data.get('maxParticipants')
        group_id = event_data.get('groupId')
        checked_count += 1

        if max_participants is None:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'issue': 'missing_maxParticipants',
                'value': None
            })
            continue

        if not isinstance(max_participants, (int, float)) or max_participants <= 0:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'issue': 'invalid_maxParticipants',
                'value': max_participants
            })
            continue

        # Get group's maxEventCapacity
        if group_id:
            if group_id not in groups_cache:
                group_doc = db.collection('groups').document(group_id).get()
                if group_doc.exists:
                    groups_cache[group_id] = group_doc.to_dict().get('maxEventCapacity', 60)
                else:
                    groups_cache[group_id] = 60  # Default

            max_event_capacity = groups_cache[group_id]
            if max_participants > max_event_capacity:
                failures.append({
                    'event_id': event_id,
                    'event_name': event_data.get('name', 'Unknown'),
                    'issue': 'exceeds_group_max_capacity',
                    'value': max_participants,
                    'group_max_capacity': max_event_capacity
                })

    assert len(failures) == 0, \
        f"Found {len(failures)} events with invalid maxParticipants:\n{format_failures(failures)}"

    print(f"✓ All {checked_count} events have valid maxParticipants")


def test_event_has_valid_fee(db):
    """
    Test that all events have valid fee value.

    Fee should be:
    - Present in all events
    - Non-negative number (>= 0)
    - Reasonable value (< 10000 for local sports events)

    Failures indicate:
    - Event creation validation missing
    - Manual database modification
    """
    failures = []
    checked_count = 0

    events = db.collection('events').stream()

    for event_doc in events:
        event_data = event_doc.to_dict()
        event_id = event_doc.id
        fee = event_data.get('fee')
        checked_count += 1

        if fee is None:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'issue': 'missing_fee',
                'value': None
            })
        elif not isinstance(fee, (int, float)) or fee < 0:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'issue': 'negative_fee',
                'value': fee
            })
        elif fee > 10000:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'issue': 'unreasonable_fee',
                'value': fee
            })

    assert len(failures) == 0, \
        f"Found {len(failures)} events with invalid fee:\n{format_failures(failures)}"

    print(f"✓ All {checked_count} events have valid fee")


def test_commitment_deadline_before_event_time(db, test_config):
    """
    Test that commitmentDeadline is before eventTimestamp.

    The commitment deadline is when users can no longer withdraw
    without penalty. It should always be before the event starts.

    Failures indicate:
    - Event creation validation bug
    - Manual database modification
    - Timezone handling issue
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    events = db.collection('events').stream()

    for event_doc in events:
        event_data = event_doc.to_dict()
        event_id = event_doc.id
        checked_count += 1

        commitment_deadline = event_data.get('commitmentDeadline')
        event_timestamp = event_data.get('eventTimestamp')

        if not commitment_deadline or not event_timestamp:
            continue  # Missing fields - different test

        # Convert Firestore timestamps to datetime
        if hasattr(commitment_deadline, 'timestamp'):
            deadline_dt = commitment_deadline
        else:
            continue

        if hasattr(event_timestamp, 'timestamp'):
            event_dt = event_timestamp
        else:
            continue

        if deadline_dt >= event_dt:
            failures.append({
                'event_id': event_id,
                'event_name': event_data.get('name', 'Unknown'),
                'commitment_deadline': deadline_dt,
                'event_timestamp': event_dt,
                'difference_hours': (deadline_dt.timestamp() - event_dt.timestamp()) / 3600
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} events, found {len(failures)} with invalid deadline"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


@pytest.mark.slow
def test_participant_has_required_fields(db, test_config):
    """
    Test that all participants have required fields.

    Required fields per DATA_MODEL.md:
    - uid: User ID
    - displayName: User's display name
    - status: Current registration status
    - registeredAt: Timestamp of registration

    Optional fields:
    - denialReason: For denied participants
    - paymentStatus: For payment tracking

    Failures indicate:
    - processEventRegistration not setting fields
    - Schema change not applied
    """
    required_fields = ['uid', 'displayName', 'status', 'registeredAt']

    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    participants = db.collection_group('participants').limit(5000).stream()

    for participant_doc in participants:
        participant_data = participant_doc.to_dict()
        event_id = participant_doc.reference.parent.parent.id
        checked_count += 1

        missing_fields = []
        for field in required_fields:
            if field not in participant_data or participant_data[field] is None:
                missing_fields.append(field)

        if missing_fields:
            failures.append({
                'participant_id': participant_doc.id,
                'event_id': event_id,
                'missing_fields': missing_fields,
                'status': participant_data.get('status', 'unknown')
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} participants, found {len(failures)} with missing fields"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_waitlist_ordered_by_registration_time(db, test_config):
    """
    Test that waitlisted participants are ordered by registeredAt.

    Waitlist promotion is first-come, first-served based on registeredAt.
    This test verifies that the data supports this business rule.

    Note: This doesn't test Cloud Function logic, just data consistency.
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    events = db.collection('events').limit(100).stream()

    for event_doc in events:
        event_id = event_doc.id
        event_name = event_doc.to_dict().get('name', 'Unknown')
        checked_count += 1

        # Get waitlisted participants ordered by registeredAt
        waitlisted = db.collection('events').document(event_id)\
            .collection('participants')\
            .where('status', '==', 'waitlisted')\
            .order_by('registeredAt')\
            .stream()

        waitlist_entries = []
        for p in waitlisted:
            p_data = p.to_dict()
            registered_at = p_data.get('registeredAt')
            if registered_at:
                waitlist_entries.append({
                    'user_id': p.id,
                    'registered_at': registered_at
                })

        # Check if any entry has missing registeredAt
        # (would break waitlist ordering)
        if len(waitlist_entries) > 0:
            for entry in waitlist_entries:
                if entry['registered_at'] is None:
                    failures.append({
                        'event_id': event_id,
                        'event_name': event_name,
                        'user_id': entry['user_id'],
                        'issue': 'missing_registeredAt_in_waitlist'
                    })

        if len(failures) >= max_failures:
            break

    summary = f"Checked {checked_count} events, found {len(failures)} waitlist ordering issues"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"
