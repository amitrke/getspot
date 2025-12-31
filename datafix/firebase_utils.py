"""
Firebase utilities for data fix scripts.

This module provides common Firebase initialization and utilities
for one-time data fix scripts.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import os


def init_firebase():
    """
    Initialize Firebase Admin SDK.

    Uses service account key from environment variable or default file.

    Environment Variables:
        FIREBASE_SERVICE_ACCOUNT_PATH: Path to service account JSON file

    Returns:
        tuple: (app, db) - Firebase app and Firestore client
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
            raise FileNotFoundError(
                f"Service account key not found at: {service_account_path}\n"
                "Please set FIREBASE_SERVICE_ACCOUNT_PATH environment variable "
                "or create serviceAccountKey.json in project root."
            )

        try:
            cred = credentials.Certificate(service_account_path)
            app = firebase_admin.initialize_app(cred, {
                'storageBucket': 'getspot01.firebasestorage.app'
            })

            print(f"✓ Connected to Firebase project: {cred.project_id}")

        except Exception as e:
            raise RuntimeError(f"Failed to initialize Firebase: {e}")

    db = firestore.client()
    return app, db


def confirm_action(message):
    """
    Ask user for confirmation before proceeding.

    Args:
        message: Confirmation message to display

    Returns:
        bool: True if user confirms, False otherwise
    """
    response = input(f"\n{message}\nType 'yes' to confirm: ").strip().lower()
    return response == 'yes'
