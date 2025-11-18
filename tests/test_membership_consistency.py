"""
Tests for membership consistency in GetSpot.

These tests verify that the denormalized userGroupMemberships collection
stays in sync with the groups/{id}/members subcollections.

Architecture Pattern:
- Primary data: groups/{groupId}/members/{userId}
- Denormalized index: userGroupMemberships/{userId}/groups/{groupId}
- Maintained by: createGroup, manageJoinRequest, manageGroupMember functions
"""

import pytest
from utils.test_helpers import format_failures


def test_user_group_memberships_forward_consistency(db, test_config):
    """
    Test that every member in groups/members has entry in userGroupMemberships.

    Direction: groups/{id}/members → userGroupMemberships

    Failures indicate:
    - Cloud Function not creating userGroupMemberships entry
    - Transaction partial failure
    - Manual database modification
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    groups = db.collection('groups').stream()

    for group_doc in groups:
        group_id = group_doc.id
        group_name = group_doc.to_dict().get('name', 'Unknown')

        members = db.collection('groups').document(group_id)\
            .collection('members').stream()

        for member_doc in members:
            user_id = member_doc.id
            checked_count += 1

            # Check if userGroupMemberships entry exists
            user_membership = db.collection('userGroupMemberships')\
                .document(user_id)\
                .collection('groups')\
                .document(group_id)\
                .get()

            if not user_membership.exists:
                failures.append({
                    'type': 'missing_user_membership',
                    'group_id': group_id,
                    'group_name': group_name,
                    'user_id': user_id,
                    'message': f"User is member of group but missing from userGroupMemberships"
                })

                if len(failures) >= max_failures:
                    break

        if len(failures) >= max_failures:
            break

    summary = f"Checked {checked_count} memberships, found {len(failures)} missing entries"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_user_group_memberships_backward_consistency(db, test_config):
    """
    Test that every userGroupMemberships entry has corresponding group member.

    Direction: userGroupMemberships → groups/{id}/members

    Failures indicate:
    - Member removed but userGroupMemberships not cleaned up
    - Orphaned index entry
    - Transaction partial failure
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

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
        checked_count += 1

        # Check if member exists in group
        member = db.collection('groups').document(group_id)\
            .collection('members').document(user_id).get()

        if not member.exists:
            failures.append({
                'type': 'orphaned_user_membership',
                'group_id': group_id,
                'group_name': membership_data.get('groupName', 'Unknown'),
                'user_id': user_id,
                'message': f"userGroupMemberships has entry but user not in group/members"
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} index entries, found {len(failures)} orphaned entries"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_no_duplicate_memberships(db):
    """
    Test that each user appears at most once per group.

    Duplicates indicate:
    - Race condition in join request handling
    - Duplicate function invocation
    - Manual database modification
    """
    groups = db.collection('groups').stream()

    all_failures = []

    for group_doc in groups:
        group_id = group_doc.id
        group_name = group_doc.to_dict().get('name', 'Unknown')

        members = db.collection('groups').document(group_id)\
            .collection('members').stream()

        user_ids = [m.id for m in members]

        # Find duplicates
        seen = set()
        duplicates = []
        for uid in user_ids:
            if uid in seen:
                duplicates.append(uid)
            seen.add(uid)

        if duplicates:
            all_failures.append({
                'group_id': group_id,
                'group_name': group_name,
                'duplicate_user_ids': list(set(duplicates)),
                'total_members': len(user_ids),
                'unique_members': len(seen)
            })

    assert len(all_failures) == 0, \
        f"Found {len(all_failures)} groups with duplicate members:\n{format_failures(all_failures)}"


def test_admin_is_group_member(db):
    """
    Test that group admin is always a member of the group.

    The admin is added as the first member when creating a group.

    Failures indicate:
    - Admin removed themselves (should be prevented)
    - Database inconsistency
    - Bug in member removal logic
    """
    groups = db.collection('groups').stream()

    failures = []

    for group_doc in groups:
        group_id = group_doc.id
        group_data = group_doc.to_dict()
        admin_uid = group_data.get('admin')
        group_name = group_data.get('name', 'Unknown')

        if not admin_uid:
            failures.append({
                'group_id': group_id,
                'group_name': group_name,
                'issue': 'missing_admin_field',
                'message': 'Group has no admin field'
            })
            continue

        # Check if admin is a member
        admin_member = db.collection('groups').document(group_id)\
            .collection('members').document(admin_uid).get()

        if not admin_member.exists:
            failures.append({
                'group_id': group_id,
                'group_name': group_name,
                'admin_uid': admin_uid,
                'issue': 'admin_not_member',
                'message': 'Group admin is not a member of the group'
            })

    assert len(failures) == 0, \
        f"Found {len(failures)} groups with admin issues:\n{format_failures(failures)}"


@pytest.mark.slow
def test_membership_data_consistency(db, test_config):
    """
    Test that userGroupMemberships data matches groups/members data.

    Fields to verify:
    - groupName matches group.name
    - isAdmin matches (uid == group.admin)
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    groups = db.collection('groups').stream()

    for group_doc in groups:
        group_id = group_doc.id
        group_data = group_doc.to_dict()
        group_name = group_data.get('name', 'Unknown')
        admin_uid = group_data.get('admin')

        members = db.collection('groups').document(group_id)\
            .collection('members').stream()

        for member_doc in members:
            user_id = member_doc.id
            checked_count += 1

            # Get userGroupMemberships entry
            user_membership = db.collection('userGroupMemberships')\
                .document(user_id)\
                .collection('groups')\
                .document(group_id)\
                .get()

            if user_membership.exists:
                membership_data = user_membership.to_dict()

                # Check groupName
                stored_group_name = membership_data.get('groupName')
                if stored_group_name != group_name:
                    failures.append({
                        'type': 'name_mismatch',
                        'group_id': group_id,
                        'user_id': user_id,
                        'expected_name': group_name,
                        'stored_name': stored_group_name
                    })

                # Check isAdmin
                stored_is_admin = membership_data.get('isAdmin', False)
                expected_is_admin = (user_id == admin_uid)
                if stored_is_admin != expected_is_admin:
                    failures.append({
                        'type': 'admin_flag_mismatch',
                        'group_id': group_id,
                        'group_name': group_name,
                        'user_id': user_id,
                        'expected_is_admin': expected_is_admin,
                        'stored_is_admin': stored_is_admin
                    })

            if len(failures) >= max_failures:
                break

        if len(failures) >= max_failures:
            break

    summary = f"Checked {checked_count} memberships, found {len(failures)} data inconsistencies"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"
