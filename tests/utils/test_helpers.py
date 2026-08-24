"""
Helper functions for GetSpot data integrity tests.

Provides utilities for:
- Formatting test failures
- Common data transformations
- Test data generation
"""

import json
from typing import List, Dict, Any


def format_failures(failures: List[Dict[str, Any]], max_display: int = 10) -> str:
    """
    Format a list of failure dictionaries for readable test output.

    Args:
        failures: List of failure dictionaries
        max_display: Maximum number of failures to display in detail

    Returns:
        Formatted string with failure details
    """
    if not failures:
        return "No failures"

    output = []
    output.append(f"\n{'='*80}")
    output.append(f"Found {len(failures)} failure(s):")
    output.append(f"{'='*80}")

    # Display first N failures in detail
    display_count = min(len(failures), max_display)

    for i, failure in enumerate(failures[:display_count], 1):
        output.append(f"\n[{i}] Failure:")
        for key, value in failure.items():
            # Handle special formatting for certain keys
            if key in ('timestamp', 'created_at', 'event_timestamp', 'registered_at'):
                # Format timestamps
                if hasattr(value, 'strftime'):
                    value = value.strftime('%Y-%m-%d %H:%M:%S')
            elif isinstance(value, float):
                # Round floats to 2 decimal places
                value = round(value, 2)

            output.append(f"  {key}: {value}")

    # If there are more failures, show summary
    if len(failures) > display_count:
        output.append(f"\n... and {len(failures) - display_count} more failure(s)")
        output.append(f"\nTo see all failures, increase max_failures_per_test in test_config")

    output.append(f"\n{'='*80}\n")

    return '\n'.join(output)


def summarize_failures_by_type(failures: List[Dict[str, Any]]) -> Dict[str, int]:
    """
    Group failures by type and count them.

    Args:
        failures: List of failure dictionaries with 'type' field

    Returns:
        Dictionary mapping failure type to count
    """
    summary = {}
    for failure in failures:
        failure_type = failure.get('type', 'unknown')
        summary[failure_type] = summary.get(failure_type, 0) + 1
    return summary


def save_failures_to_file(failures: List[Dict[str, Any]], filename: str):
    """
    Save failures to a JSON file for detailed analysis.

    Args:
        failures: List of failure dictionaries
        filename: Output filename
    """
    with open(filename, 'w') as f:
        json.dump(failures, f, indent=2, default=str)


def group_failures_by_field(failures: List[Dict[str, Any]], field: str) -> Dict[str, List[Dict]]:
    """
    Group failures by a specific field value.

    Args:
        failures: List of failure dictionaries
        field: Field name to group by (e.g., 'group_id', 'event_id')

    Returns:
        Dictionary mapping field value to list of failures
    """
    grouped = {}
    for failure in failures:
        key = failure.get(field, 'unknown')
        if key not in grouped:
            grouped[key] = []
        grouped[key].append(failure)
    return grouped


def calculate_error_rate(failures: int, total: int) -> float:
    """
    Calculate error rate as a percentage.

    Args:
        failures: Number of failures
        total: Total number of items checked

    Returns:
        Error rate as percentage (0-100)
    """
    if total == 0:
        return 0.0
    return (failures / total) * 100


def format_summary_stats(checked: int, failures: int, test_name: str = "") -> str:
    """
    Format summary statistics for test output.

    Args:
        checked: Number of items checked
        failures: Number of failures found
        test_name: Name of the test (optional)

    Returns:
        Formatted summary string
    """
    error_rate = calculate_error_rate(failures, checked)

    if test_name:
        output = f"\n{test_name}:\n"
    else:
        output = "\n"

    output += f"  Items checked: {checked:,}\n"
    output += f"  Failures: {failures:,}\n"
    output += f"  Success rate: {100 - error_rate:.2f}%\n"

    if error_rate > 0:
        output += f"  ⚠ Error rate: {error_rate:.2f}%\n"
    else:
        output += "  ✓ All checks passed\n"

    return output


def compare_counts(expected: int, actual: int, tolerance: int = 0) -> bool:
    """
    Compare two counts with optional tolerance.

    Args:
        expected: Expected count
        actual: Actual count
        tolerance: Acceptable difference

    Returns:
        True if counts match within tolerance
    """
    return abs(expected - actual) <= tolerance


def validate_timestamp(timestamp: Any) -> bool:
    """
    Validate that a value is a valid timestamp.

    Args:
        timestamp: Value to check

    Returns:
        True if valid timestamp
    """
    if timestamp is None:
        return False

    # Check if it's a Firestore timestamp
    if hasattr(timestamp, 'timestamp'):
        return True

    # Check if it's a Python datetime
    from datetime import datetime
    if isinstance(timestamp, datetime):
        return True

    return False


def get_age_in_days(timestamp: Any) -> int:
    """
    Calculate age of a timestamp in days.

    Args:
        timestamp: Firestore timestamp or datetime

    Returns:
        Age in days
    """
    from datetime import datetime

    if hasattr(timestamp, 'timestamp'):
        # Firestore timestamp - convert to datetime
        dt = timestamp.replace(tzinfo=None)
    elif isinstance(timestamp, datetime):
        dt = timestamp
    else:
        raise ValueError(f"Invalid timestamp type: {type(timestamp)}")

    age = datetime.now() - dt
    return age.days


def sanitize_for_display(value: Any, max_length: int = 50) -> str:
    """
    Sanitize a value for display in test output.

    Args:
        value: Value to sanitize
        max_length: Maximum string length

    Returns:
        Sanitized string
    """
    if value is None:
        return "None"

    str_value = str(value)

    if len(str_value) > max_length:
        return str_value[:max_length] + "..."

    return str_value
