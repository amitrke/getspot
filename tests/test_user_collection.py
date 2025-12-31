"""
Tests for user collection data integrity in GetSpot.

These tests verify:
1. All users have required fields
2. User data follows expected schema
3. FCM tokens are valid arrays
4. Users referenced in groups/transactions exist
5. No orphaned or malformed user documents
6. Firestore users have active Firebase Auth accounts

User documents are created by:
- auth_service.dart (initial creation)
- notification_service.dart (FCM token updates)
- updateUserDisplayName.ts (display name updates)
"""

import pytest
import re
from firebase_admin import auth
from utils.test_helpers import format_failures


def test_user_has_required_fields(db, test_config):
    """
    Test that all user documents have required fields.

    Required fields:
    - uid: User ID (should match document ID)
    - displayName: User's display name
    - email: User's email address
    - createdAt: Account creation timestamp

    Optional fields:
    - fcmTokens: Array of FCM device tokens
    - photoURL: User's profile photo URL
    - notificationsEnabled: Boolean for notification preference

    Failures indicate:
    - User document created incorrectly
    - Manual database modification
    - Migration issue
    """
    required_fields = ['uid', 'displayName', 'email', 'createdAt']
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        checked_count += 1

        missing_fields = []
        for field in required_fields:
            if field not in user_data or user_data[field] is None:
                missing_fields.append(field)

        if missing_fields:
            failures.append({
                'user_id': user_id,
                'email': user_data.get('email', 'Unknown'),
                'missing_fields': missing_fields
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} users, found {len(failures)} with missing fields"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_user_uid_matches_document_id(db):
    """
    Test that user.uid matches the document ID.

    This is critical for security and data consistency.

    Failures indicate:
    - User document created incorrectly
    - Data corruption
    - Manual database error
    """
    failures = []
    checked_count = 0

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        checked_count += 1

        stored_uid = user_data.get('uid')

        if stored_uid != user_id:
            failures.append({
                'document_id': user_id,
                'stored_uid': stored_uid,
                'email': user_data.get('email', 'Unknown'),
                'issue': 'uid_mismatch'
            })

    assert len(failures) == 0, \
        f"Found {len(failures)} users with mismatched UIDs:\n{format_failures(failures)}"

    print(f"✓ All {checked_count} users have matching UIDs")


def test_user_email_is_valid(db, test_config):
    """
    Test that all user emails are in valid format.

    Basic email validation: contains @ and domain.

    Failures indicate:
    - Invalid email during signup
    - Manual database modification
    - Bug in user creation
    """
    email_pattern = re.compile(r'^[^@]+@[^@]+\.[^@]+$')
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        email = user_data.get('email', '')
        checked_count += 1

        if not email or not email_pattern.match(email):
            failures.append({
                'user_id': user_id,
                'email': email,
                'display_name': user_data.get('displayName', 'Unknown'),
                'issue': 'invalid_email_format'
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} users, found {len(failures)} with invalid emails"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_fcm_tokens_is_array(db, test_config):
    """
    Test that fcmTokens field is always an array when present.

    fcmTokens is used for push notifications and must be an array
    to support multiple devices.

    Failures indicate:
    - Incorrect FCM token storage
    - Bug in notification service
    - Manual database modification
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()

        if 'fcmTokens' in user_data:
            checked_count += 1
            fcm_tokens = user_data['fcmTokens']

            if not isinstance(fcm_tokens, list):
                failures.append({
                    'user_id': user_id,
                    'email': user_data.get('email', 'Unknown'),
                    'fcmTokens_type': type(fcm_tokens).__name__,
                    'fcmTokens_value': str(fcm_tokens)[:100]  # Truncate for safety
                })

                if len(failures) >= max_failures:
                    break

    summary = f"Checked {checked_count} users with fcmTokens, found {len(failures)} with invalid type"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


@pytest.mark.slow
def test_users_referenced_in_groups_exist(db, test_config):
    """
    Test that all users referenced in group members exist in users collection.

    This verifies referential integrity between groups/members and users.

    Note: Users can be deleted, which would create orphaned references.
    This test helps identify if user deletion cleanup is working.

    Failures indicate:
    - User deleted but not removed from groups
    - Data lifecycle management issue
    - Referential integrity problem
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    # Build users cache
    users_cache = {u.id: True for u in db.collection('users').stream()}

    # Check all group members
    groups = db.collection('groups').limit(100).stream()

    for group_doc in groups:
        group_id = group_doc.id
        group_name = group_doc.to_dict().get('name', 'Unknown')

        members = db.collection('groups').document(group_id).collection('members').stream()

        for member_doc in members:
            user_id = member_doc.id
            member_data = member_doc.to_dict()
            checked_count += 1

            if user_id not in users_cache:
                failures.append({
                    'type': 'missing_user',
                    'user_id': user_id,
                    'group_id': group_id,
                    'group_name': group_name,
                    'display_name': member_data.get('displayName', 'Unknown'),
                    'message': 'User is group member but does not exist in users collection'
                })

                if len(failures) >= max_failures:
                    break

        if len(failures) >= max_failures:
            break

    summary = f"Checked {checked_count} group members, found {len(failures)} missing users"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_photo_url_is_valid_when_present(db, test_config):
    """
    Test that photoURL field contains valid URL format when present.

    Failures indicate:
    - Invalid URL stored
    - Bug in profile update
    - Manual database modification
    """
    url_pattern = re.compile(r'^https?://.+')
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()

        if 'photoURL' in user_data and user_data['photoURL']:
            checked_count += 1
            photo_url = user_data['photoURL']

            if not isinstance(photo_url, str) or not url_pattern.match(photo_url):
                failures.append({
                    'user_id': user_id,
                    'email': user_data.get('email', 'Unknown'),
                    'photo_url': str(photo_url)[:100],  # Truncate for safety
                    'issue': 'invalid_url_format'
                })

                if len(failures) >= max_failures:
                    break

    summary = f"Checked {checked_count} users with photoURL, found {len(failures)} invalid"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_notifications_enabled_is_boolean(db, test_config):
    """
    Test that notificationsEnabled field is boolean when present.

    Failures indicate:
    - Wrong data type stored
    - Bug in settings update
    - Manual database modification
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()

        if 'notificationsEnabled' in user_data:
            checked_count += 1
            notifications_enabled = user_data['notificationsEnabled']

            if not isinstance(notifications_enabled, bool):
                failures.append({
                    'user_id': user_id,
                    'email': user_data.get('email', 'Unknown'),
                    'value': notifications_enabled,
                    'type': type(notifications_enabled).__name__,
                    'issue': 'not_boolean'
                })

                if len(failures) >= max_failures:
                    break

    summary = f"Checked {checked_count} users with notificationsEnabled, found {len(failures)} invalid"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


def test_no_extra_unexpected_fields(db, test_config):
    """
    Test that users only have expected fields.

    Expected fields:
    - uid, displayName, email, createdAt (required)
    - fcmTokens, photoURL, notificationsEnabled (optional)

    This test helps identify data pollution or bugs that add unexpected fields.

    Note: This is a warning-level test - unexpected fields won't fail the test
    but will be reported.
    """
    expected_fields = {
        'uid', 'displayName', 'email', 'createdAt',
        'fcmTokens', 'photoURL', 'notificationsEnabled'
    }

    warnings = []
    checked_count = 0
    max_warnings = test_config['max_failures_per_test']

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        checked_count += 1

        actual_fields = set(user_data.keys())
        unexpected_fields = actual_fields - expected_fields

        if unexpected_fields:
            warnings.append({
                'user_id': user_id,
                'email': user_data.get('email', 'Unknown'),
                'unexpected_fields': list(unexpected_fields)
            })

            if len(warnings) >= max_warnings:
                break

    # This is informational - don't fail the test
    if warnings:
        print(f"\n⚠ Warning: Found {len(warnings)} users with unexpected fields:")
        for warning in warnings[:5]:  # Show first 5
            print(f"  - {warning['email']}: {warning['unexpected_fields']}")
        if len(warnings) > 5:
            print(f"  ... and {len(warnings) - 5} more")

    print(f"✓ Checked {checked_count} users for schema compliance")


@pytest.mark.slow
def test_firestore_users_exist_in_auth(db, auth_client, test_config):
    """
    Test that all Firestore users have corresponding Firebase Auth accounts.

    This verifies referential integrity between Firestore and Firebase Auth.

    Orphaned Firestore users indicate:
    - User deleted from Auth but not from Firestore
    - Data lifecycle management not working
    - Manual Auth deletion without cleanup

    Note: This test is slow as it makes an Auth API call for each user.
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        email = user_data.get('email', 'Unknown')
        checked_count += 1

        try:
            # Try to get the user from Firebase Auth
            auth_user = auth_client.get_user(user_id)

            # User exists - optionally verify email matches
            if auth_user.email != email:
                failures.append({
                    'user_id': user_id,
                    'issue': 'email_mismatch',
                    'firestore_email': email,
                    'auth_email': auth_user.email,
                    'message': 'Email in Firestore does not match Auth email'
                })

        except auth_client.UserNotFoundError:
            # User doesn't exist in Firebase Auth
            failures.append({
                'user_id': user_id,
                'email': email,
                'issue': 'missing_auth_account',
                'message': 'User exists in Firestore but not in Firebase Auth'
            })

            if len(failures) >= max_failures:
                break

        except Exception as e:
            # Other errors (e.g., API issues)
            failures.append({
                'user_id': user_id,
                'email': email,
                'issue': 'auth_api_error',
                'error': str(e),
                'message': f'Error checking Auth: {str(e)}'
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} Firestore users, found {len(failures)} issues with Auth"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"


@pytest.mark.slow
def test_firestore_users_have_active_auth_accounts(db, auth_client, test_config):
    """
    Test that all Firestore users have ACTIVE (not disabled) Firebase Auth accounts.

    Disabled auth accounts should trigger data cleanup in Firestore.

    Failures indicate:
    - User disabled in Auth but still active in Firestore
    - Data lifecycle management not handling disabled accounts
    - Manual Auth account disabling without cleanup

    Note: This test is slow as it makes an Auth API call for each user.
    """
    failures = []
    checked_count = 0
    max_failures = test_config['max_failures_per_test']

    users = db.collection('users').stream()

    for user_doc in users:
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        email = user_data.get('email', 'Unknown')
        checked_count += 1

        try:
            # Get the user from Firebase Auth
            auth_user = auth_client.get_user(user_id)

            # Check if account is disabled
            if auth_user.disabled:
                failures.append({
                    'user_id': user_id,
                    'email': email,
                    'issue': 'disabled_auth_account',
                    'message': 'User exists in Firestore but Auth account is disabled'
                })

                if len(failures) >= max_failures:
                    break

        except auth_client.UserNotFoundError:
            # User doesn't exist - already covered by previous test
            pass

        except Exception as e:
            # Other errors (e.g., API issues)
            failures.append({
                'user_id': user_id,
                'email': email,
                'issue': 'auth_api_error',
                'error': str(e),
                'message': f'Error checking Auth status: {str(e)}'
            })

            if len(failures) >= max_failures:
                break

    summary = f"Checked {checked_count} Firestore users, found {len(failures)} with disabled Auth accounts"
    assert len(failures) == 0, f"{summary}\n{format_failures(failures)}"
