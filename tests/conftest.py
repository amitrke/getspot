"""
Pytest configuration and fixtures for GetSpot data integrity tests.

This module provides shared fixtures for connecting to Firebase services
and common test utilities.
"""

import pytest
import firebase_admin
from firebase_admin import credentials, firestore, storage, auth
import os
import sys
from pathlib import Path

# Add utils to Python path
sys.path.insert(0, str(Path(__file__).parent))


@pytest.fixture(scope="session")
def firebase_app():
    """
    Initialize Firebase Admin SDK once per test session.

    Uses service account key from environment variable or file.

    Environment Variables:
        FIREBASE_SERVICE_ACCOUNT_PATH: Path to service account JSON file
        FIREBASE_PROJECT_ID: Firebase project ID (optional, for validation)

    Returns:
        firebase_admin.App: Initialized Firebase app
    """
    # Check if already initialized
    if len(firebase_admin._apps) > 0:
        app = firebase_admin.get_app()
    else:
        # Get service account path from environment
        service_account_path = os.getenv(
            'FIREBASE_SERVICE_ACCOUNT_PATH',
            'serviceAccountKey.json'  # Default fallback
        )

        if not os.path.exists(service_account_path):
            pytest.exit(
                f"Service account key not found at: {service_account_path}\n"
                "Please set FIREBASE_SERVICE_ACCOUNT_PATH environment variable "
                "or create serviceAccountKey.json in tests directory."
            )

        try:
            cred = credentials.Certificate(service_account_path)
            app = firebase_admin.initialize_app(cred, {
                'storageBucket': 'getspot01.firebasestorage.app'
            })

            # Validate project ID if provided
            expected_project_id = os.getenv('FIREBASE_PROJECT_ID', 'getspot01')
            if cred.project_id != expected_project_id:
                pytest.exit(
                    f"WARNING: Connected to project '{cred.project_id}' "
                    f"but expected '{expected_project_id}'"
                )

            print(f"\n✓ Connected to Firebase project: {cred.project_id}")

        except Exception as e:
            pytest.exit(f"Failed to initialize Firebase: {e}")

    yield app

    # Cleanup after all tests
    # Note: We don't delete the app here as it's shared across all tests


@pytest.fixture
def db(firebase_app):
    """
    Get Firestore client instance.

    Args:
        firebase_app: Firebase app fixture

    Returns:
        google.cloud.firestore.Client: Firestore client
    """
    return firestore.client()


@pytest.fixture
def bucket(firebase_app):
    """
    Get Cloud Storage bucket instance.

    Args:
        firebase_app: Firebase app fixture

    Returns:
        google.cloud.storage.Bucket: Storage bucket
    """
    return storage.bucket()


@pytest.fixture
def auth_client(firebase_app):
    """
    Get Firebase Auth client instance.

    Args:
        firebase_app: Firebase app fixture

    Returns:
        firebase_admin.auth: Firebase Auth client
    """
    return auth


@pytest.fixture
def test_config():
    """
    Get test configuration from environment variables.

    Returns:
        dict: Test configuration
    """
    return {
        'project_id': os.getenv('FIREBASE_PROJECT_ID', 'getspot01'),
        'storage_bucket': os.getenv('FIREBASE_STORAGE_BUCKET', 'getspot01.firebasestorage.app'),
        'run_slow_tests': os.getenv('RUN_SLOW_TESTS', 'false').lower() == 'true',
        'max_failures_per_test': int(os.getenv('MAX_FAILURES_PER_TEST', '10')),
    }


def pytest_configure(config):
    """Add custom markers for pytest."""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "integration: marks tests as integration tests"
    )
    config.addinivalue_line(
        "markers", "archiving: marks tests that check data archiving"
    )


def pytest_collection_modifyitems(config, items):
    """Skip slow tests unless explicitly requested."""
    if not os.getenv('RUN_SLOW_TESTS', 'false').lower() == 'true':
        skip_slow = pytest.mark.skip(reason="slow test (set RUN_SLOW_TESTS=true to run)")
        for item in items:
            if "slow" in item.keywords:
                item.add_marker(skip_slow)
