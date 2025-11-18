# GetSpot Data Integrity Test Suite

Python-based test suite for verifying data consistency and integrity in the GetSpot Firebase database.

## Overview

This test suite checks critical invariants in the GetSpot production database:

- ✅ **Denormalized counts** match actual document counts
- ✅ **Membership consistency** between primary and index collections
- ✅ **Wallet balances** match transaction history
- ✅ **Event capacity** rules are enforced
- ✅ **Data archiving** policy is working

## Quick Start

### 1. Install Dependencies

```bash
# Create virtual environment (recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install requirements
pip install -r requirements.txt
```

### 2. Configure Firebase Access

Download your service account key from Firebase Console:

1. Go to **Project Settings** > **Service Accounts**
2. Click **Generate New Private Key**
3. Save as `serviceAccountKey.json` in the `tests/` directory

**IMPORTANT:** Never commit this file! It's already in `.gitignore`.

### 3. Set Environment Variables

```bash
# Copy example file
cp .env.example .env

# Edit .env with your values
FIREBASE_SERVICE_ACCOUNT_PATH=serviceAccountKey.json
FIREBASE_PROJECT_ID=getspot01
```

### 4. Run Tests

```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest test_denormalized_counts.py -v

# Run tests matching pattern
pytest -k "wallet" -v

# Skip slow tests
pytest -m "not slow"

# Run in parallel (faster)
pytest -n auto

# Generate HTML report
pytest --html=report.html --self-contained-html
```

## Test Categories

### Denormalized Counts (`test_denormalized_counts.py`)
Tests that denormalized count fields match actual document counts:
- `confirmedCount` vs confirmed participants
- `waitlistCount` vs waitlisted participants
- `pendingJoinRequestsCount` vs pending join requests

**Functions tested:** `processEventRegistration.ts`, `withdrawFromEvent.ts`, `maintainJoinRequestCount.ts`

### Membership Consistency (`test_membership_consistency.py`)
Tests bidirectional sync between `groups/{id}/members` and `userGroupMemberships`:
- Forward consistency (members → index)
- Backward consistency (index → members)
- No duplicate memberships
- Admin is always a member

**Functions tested:** `createGroup`, `manageJoinRequest`, `manageGroupMember`

### Wallet Consistency (`test_wallet_consistency.py`)
Tests financial integrity:
- Wallet balance = sum of transactions
- Negative balances within limits
- Transaction fields are valid
- Transaction amounts are positive

**Functions tested:** `manageGroupMember.ts`, `processEventRegistration.ts`, `withdrawFromEvent.ts`

### Event Capacity (`test_event_capacity.py`)
Tests event business rules:
- Confirmed count ≤ maxParticipants
- Valid participant statuses
- Valid event fields (fee, capacity, deadlines)
- Waitlist ordering by registeredAt

**Functions tested:** `processEventRegistration.ts`, `updateEventCapacity.ts`, `processWaitlist.ts`

### Data Archiving (`test_data_archiving.py`)
Tests data retention policy:
- Events older than 3 months are archived
- Transactions older than 3 months are archived
- Archived data exists in Cloud Storage
- Join requests are cleaned up

**Functions tested:** `dataLifecycle.ts`

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `serviceAccountKey.json` | Path to service account key |
| `FIREBASE_PROJECT_ID` | `getspot01` | Firebase project ID |
| `FIREBASE_STORAGE_BUCKET` | `getspot01.firebasestorage.app` | Cloud Storage bucket |
| `RUN_SLOW_TESTS` | `false` | Run slow tests (set to `true`) |
| `MAX_FAILURES_PER_TEST` | `10` | Max failures to display per test |

### Test Markers

Tests are marked with categories:

```bash
# Run only archiving tests
pytest -m archiving

# Run only integration tests
pytest -m integration

# Skip slow tests (default)
pytest -m "not slow"

# Run slow tests
RUN_SLOW_TESTS=true pytest
```

## CI/CD Integration

### GitHub Actions

Example workflow (`.github/workflows/data-integrity-tests.yml`):

```yaml
name: Data Integrity Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:     # Manual trigger

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          cd tests
          pip install -r requirements.txt

      - name: Run tests
        env:
          FIREBASE_SERVICE_ACCOUNT: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
        run: |
          cd tests
          echo "$FIREBASE_SERVICE_ACCOUNT" > serviceAccountKey.json
          pytest -v --html=report.html --self-contained-html

      - name: Upload test report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-report
          path: tests/report.html
```

### Set GitHub Secret

1. Go to **Settings** > **Secrets and variables** > **Actions**
2. Add secret named `FIREBASE_SERVICE_ACCOUNT`
3. Paste contents of `serviceAccountKey.json`

## Interpreting Results

### Success
```
test_denormalized_counts.py::test_event_confirmed_count_matches_actual PASSED
✓ Checked 245 events, found 0 mismatches
```

### Failure
```
test_denormalized_counts.py::test_event_confirmed_count_matches_actual FAILED

Checked 245 events, found 3 mismatches
================================================================================
[1] Failure:
  event_id: abc123
  event_name: Friday Night Badminton
  stored_count: 10
  actual_count: 9
  difference: 1
...
```

## Troubleshooting

### "Service account key not found"
- Check that `serviceAccountKey.json` exists in `tests/` directory
- Verify `FIREBASE_SERVICE_ACCOUNT_PATH` environment variable

### "Permission denied" errors
- Service account needs Firestore read access
- Service account needs Cloud Storage read access (for archiving tests)
- Check IAM roles in Firebase Console

### Tests are slow
- Use `-n auto` for parallel execution: `pytest -n auto`
- Skip slow tests: `pytest -m "not slow"`
- Reduce `MAX_FAILURES_PER_TEST` to stop early

### Import errors
- Activate virtual environment
- Run `pip install -r requirements.txt`
- Check Python version (3.9+)

## Adding New Tests

1. Create test file in `tests/` directory
2. Follow naming convention: `test_*.py`
3. Use fixtures from `conftest.py`:
   - `db` - Firestore client
   - `bucket` - Cloud Storage bucket
   - `test_config` - Test configuration
4. Add docstrings explaining what's tested and why
5. Use `format_failures()` from `utils/test_helpers.py`

Example:

```python
def test_my_new_check(db, test_config):
    """
    Test that [invariant] holds.

    Failures indicate:
    - [What could cause this]
    """
    failures = []

    # ... test logic ...

    assert len(failures) == 0, f"Found issues:\n{format_failures(failures)}"
```

## Security

- **Never commit service account keys**
- Use environment variables for sensitive data
- Limit service account permissions (read-only recommended)
- Rotate keys regularly
- Use different keys for dev/staging/prod

## Support

- **Documentation:** See main repo `docs/` folder
- **Issues:** File in main GetSpot repo
- **Architecture:** See `docs/ARCHITECTURE.md` and `docs/DATA_MODEL.md`

---

**Last Updated:** 2025-10-24
