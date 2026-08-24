#!/usr/bin/env python3
"""
Initialize maxEventCapacity for all groups.

This script:
1. Fetches all groups in the database
2. Sets maxEventCapacity to 60 (default) for groups that don't have it
3. For groups with existing events over 60, sets maxEventCapacity to the
   highest maxParticipants value to avoid breaking existing events

Usage:
    python datafix/01_initialize_max_event_capacity.py

Environment Variables:
    FIREBASE_SERVICE_ACCOUNT_PATH: Path to service account JSON file
"""

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from datafix.firebase_utils import init_firebase, confirm_action


DEFAULT_MAX_CAPACITY = 60


def main():
    """Main execution function."""
    print("=" * 80)
    print("Initialize maxEventCapacity for Groups")
    print("=" * 80)

    # Initialize Firebase
    app, db = init_firebase()

    # Get confirmation
    if not confirm_action(
        f"This will set maxEventCapacity (default: {DEFAULT_MAX_CAPACITY}) "
        "for all groups that don't have it.\nGroups with existing events "
        "exceeding the default will be adjusted automatically."
    ):
        print("Aborted.")
        return

    print("\nProcessing groups...")

    # Fetch all groups
    groups = db.collection('groups').stream()
    groups_list = list(groups)  # Convert to list to get count
    print(f"Found {len(groups_list)} groups to process")

    success_count = 0
    skip_count = 0
    error_count = 0
    capacity_adjustments = []

    for group_doc in groups_list:
        try:
            group_id = group_doc.id
            group_data = group_doc.to_dict()
            group_name = group_data.get('name', 'Unknown')

            # Skip if already has the field
            if 'maxEventCapacity' in group_data and group_data['maxEventCapacity'] is not None:
                print(f"  ⊘ Group '{group_name}' already has maxEventCapacity: {group_data['maxEventCapacity']}")
                skip_count += 1
                continue

            # Find the highest maxParticipants from existing events
            events = db.collection('events').where('groupId', '==', group_id).stream()
            max_existing_capacity = 0

            for event_doc in events:
                event_data = event_doc.to_dict()
                max_participants = event_data.get('maxParticipants', 0)
                if max_participants > max_existing_capacity:
                    max_existing_capacity = max_participants

            # Set maxEventCapacity
            # If existing events exceed default, use the highest value
            # Otherwise use default (60)
            max_event_capacity = DEFAULT_MAX_CAPACITY
            if max_existing_capacity > DEFAULT_MAX_CAPACITY:
                max_event_capacity = max_existing_capacity
                capacity_adjustments.append({
                    'group_id': group_id,
                    'group_name': group_name,
                    'adjusted_capacity': max_event_capacity,
                    'reason': f'Existing event with {max_existing_capacity} participants'
                })
                print(f"  ⚠ Group '{group_name}' has events with capacity > {DEFAULT_MAX_CAPACITY}. "
                      f"Setting maxEventCapacity to {max_event_capacity}")

            # Update the group document
            db.collection('groups').document(group_id).update({
                'maxEventCapacity': max_event_capacity
            })

            print(f"  ✓ Updated group '{group_name}' with maxEventCapacity: {max_event_capacity}")
            success_count += 1

        except Exception as e:
            error_count += 1
            print(f"  ✗ Error processing group {group_doc.id}: {e}")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total groups:     {len(groups_list)}")
    print(f"Updated:          {success_count}")
    print(f"Skipped:          {skip_count} (already had maxEventCapacity)")
    print(f"Errors:           {error_count}")
    print(f"Default capacity: {DEFAULT_MAX_CAPACITY}")

    if capacity_adjustments:
        print(f"\nGroups with adjusted capacity ({len(capacity_adjustments)}):")
        for adjustment in capacity_adjustments:
            print(f"  - {adjustment['group_name']}: {adjustment['adjusted_capacity']} "
                  f"({adjustment['reason']})")

    print("\n✓ Migration completed successfully!")


if __name__ == '__main__':
    main()
