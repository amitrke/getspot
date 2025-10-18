# Maestro Test Suite Documentation

This directory contains automated UI tests for the GetSpot app using [Maestro](https://maestro.mobile.dev/).

## Test Users

The test suite uses two test users with different roles:

- **User 1 (Admin)**: Group owner/admin - can create events, manage members, cancel events
  - Environment variables: `MAESTRO_USER1_EMAIL`, `MAESTRO_USER1_PASSWORD`

- **User 2 (Member)**: Regular group member - can register/withdraw from events, view content
  - Environment variables: `MAESTRO_USER2_EMAIL`, `MAESTRO_USER2_PASSWORD`

Both users should be members of the test group specified in `MAESTRO_TEST_GROUP_ID`.

## Test Organization

Tests are organized by impact level, user role, and use case:

### Authentication Tests
- **`login_test.yaml`** - Login flow for User 1 (Admin) with clearState
  - Fresh app state testing
  - Verifies authentication works correctly
  - Sets up for admin flow tests

- **`login_user2_test.yaml`** - Login flow for User 2 (Member) with clearState
  - Switch between test users
  - Sets up for member flow tests

### Role-Based Tests
- **`admin_flow_test.yaml`** - Admin-specific features (requires User 1)
  - Create Event button visibility
  - Admin tab access
  - Members management access
  - Cancel Event button visibility

- **`member_flow_test.yaml`** - Member-specific features (requires User 2)
  - Verifies admin features are hidden
  - Register/Withdraw functionality
  - Read-only group access

### Read-Only Tests (Safe to run frequently)
- **`read_only_test.yaml`** - Views and navigates through existing data without making changes
  - User profile viewing
  - Group list navigation
  - Event details viewing
  - Wallet balance viewing
  - Announcements tab navigation
  - Works with any logged-in user

### Legacy Smoke Tests (kept for backwards compatibility)
- **`smoke_test.yaml`** - Complete end-to-end test including login
  - Uses legacy `MAESTRO_TEST_EMAIL`/`MAESTRO_TEST_PASSWORD` variables
  - Full authentication flow
  - Navigation through all major screens

- **`debug_test.yaml`** - Same as smoke test but skips login
  - Uses legacy variables
  - Faster iteration during development

### Data-Modifying Tests (Use with caution)
- **`event_registration_test.yaml`** - Tests event registration and withdrawal
  - ⚠️ Modifies wallet balance
  - ⚠️ Registers and withdraws from events
  - ⚠️ Requires sufficient wallet balance
  - Use sparingly to avoid polluting transaction history

- **`event_creation_test.yaml`** - Tests event creation flow
  - ⚠️ Creates new events (will show up in production data)
  - ⚠️ Requires admin access to test group
  - ⚠️ Includes cleanup (event cancellation)
  - Only run when specifically testing event creation

## Running Tests

### Quick Start
```powershell
# PowerShell - Login as User 1 (admin) and test admin features
.\run-maestro-test.ps1 default login_test.yaml
.\run-maestro-test.ps1 default admin_flow_test.yaml

# Login as User 2 (member) and test member features
.\run-maestro-test.ps1 default login_user2_test.yaml
.\run-maestro-test.ps1 default member_flow_test.yaml

# Run read-only test (works with any logged-in user)
.\run-maestro-test.ps1 default read_only_test.yaml
```

```bash
# Bash - Same workflows
./run-maestro-test.sh default login_test.yaml
./run-maestro-test.sh default admin_flow_test.yaml

./run-maestro-test.sh default login_user2_test.yaml
./run-maestro-test.sh default member_flow_test.yaml

./run-maestro-test.sh default read_only_test.yaml
```

### Device-Specific Testing
```powershell
# PowerShell examples
.\run-maestro-test.ps1 android-phone read_only_test.yaml
.\run-maestro-test.ps1 android-tablet-10 smoke_test.yaml
.\run-maestro-test.ps1 iphone-65 debug_test.yaml
.\run-maestro-test.ps1 ipad-13 read_only_test.yaml

# Bash examples
./run-maestro-test.sh android-phone read_only_test.yaml
./run-maestro-test.sh android-tablet-10 smoke_test.yaml
./run-maestro-test.sh iphone-65 debug_test.yaml
./run-maestro-test.sh ipad-13 read_only_test.yaml
```

### Available Device IDs
- `android-phone` - Android phone (393x851)
- `android-tablet-7` - 7" Android tablet (600x960)
- `android-tablet-10` - 10" Android tablet (800x1280)
- `iphone-65` - iPhone 6.5" (428x926)
- `ipad-13` - iPad 13" (1024x1366)
- `default` - Use current connected device dimensions

## Screenshot Organization

Screenshots are automatically organized by device:
```
screenshots/
├── android-phone/
│   ├── login_screen.png
│   ├── home_screen_with_groups.png
│   └── ...
├── android-tablet-10/
│   ├── login_screen.png
│   └── ...
├── ipad-13/
│   └── ...
└── default/
    └── ...
```

## Environment Variables

Required environment variables (set in `.env` file):

### New Multi-User Variables
- `MAESTRO_USER1_EMAIL` - User 1 (admin) email
- `MAESTRO_USER1_PASSWORD` - User 1 (admin) password
- `MAESTRO_USER2_EMAIL` - User 2 (member) email
- `MAESTRO_USER2_PASSWORD` - User 2 (member) password
- `MAESTRO_TEST_GROUP_ID` - Test group ID (both users should be members)

### Legacy Variables (backwards compatibility)
- `MAESTRO_TEST_EMAIL` - Legacy test account email
- `MAESTRO_TEST_PASSWORD` - Legacy test account password

The scripts automatically:
- Load variables from `.env` file
- Set `MAESTRO_SCREENSHOT_DIR` based on device ID
- Create screenshot directories if they don't exist

### Setting Up Test Users

1. Create two test accounts in your GetSpot app
2. Create or identify a test group
3. Make User 1 the admin/owner of the test group
4. Add User 2 as a regular member (not admin) to the test group
5. Update `.env` file with the credentials and group ID

## Best Practices

### Daily Development
Run read-only tests frequently during development:
```powershell
.\run-maestro-test.ps1 ipad-13 read_only_test.yaml
```

### Testing Role-Based Features
When developing admin features:
```powershell
# Login as admin and test admin features
.\run-maestro-test.ps1 default login_test.yaml
.\run-maestro-test.ps1 default admin_flow_test.yaml

# Switch to member to verify features are properly hidden
.\run-maestro-test.ps1 default login_user2_test.yaml
.\run-maestro-test.ps1 default member_flow_test.yaml
```

### Pre-Release Testing
Run comprehensive test suite across roles and devices:
```bash
# Test admin flow on all devices
for device in android-phone android-tablet-10 iphone-65 ipad-13; do
  ./run-maestro-test.sh $device login_test.yaml
  ./run-maestro-test.sh $device admin_flow_test.yaml
done

# Test member flow on all devices
for device in android-phone android-tablet-10 iphone-65 ipad-13; do
  ./run-maestro-test.sh $device login_user2_test.yaml
  ./run-maestro-test.sh $device member_flow_test.yaml
done
```

### Feature Development
- Use `debug_test.yaml` for quick iterations (assumes app is already running)
- Use `read_only_test.yaml` to verify no regressions in viewing functionality
- Only run data-modifying tests when specifically testing those features

### Data-Modifying Tests
⚠️ **Important**: These tests modify real data:
- Run in a test environment, not production
- Review transaction history after running registration tests
- Verify test events are cleaned up after creation tests
- Use sparingly to avoid data pollution

## Test Maintenance

### Adding New Tests
1. Determine impact level (read-only vs. data-modifying)
2. Create new `.yaml` file with descriptive name
3. Add `env: SCREENSHOT_DIR: ${MAESTRO_SCREENSHOT_DIR}` header
4. Use `${SCREENSHOT_DIR}/` prefix for all screenshots
5. Document in this README

### Updating Existing Tests
- Keep read-only tests truly read-only (no button presses that modify data)
- Add comments explaining complex interactions
- Use descriptive screenshot names
- Test on multiple devices after changes

### Troubleshooting
- If tests fail on specific devices, check screen dimensions in scripts
- If screenshots aren't saving, verify `MAESTRO_SCREENSHOT_DIR` is set
- If app state is wrong, try `smoke_test.yaml` with `clearState: true`
- Check `.env` file exists and contains all required variables

## CI/CD Integration

For continuous integration, consider:
```yaml
# Example GitHub Actions workflow
- name: Run Maestro Tests
  run: |
    ./run-maestro-test.sh android-phone read_only_test.yaml
    ./run-maestro-test.sh ipad-13 read_only_test.yaml
```

Only run data-modifying tests in dedicated test environments with isolated test data.

## Additional Resources
- [Maestro Documentation](https://maestro.mobile.dev/)
- [Maestro CLI Reference](https://maestro.mobile.dev/cli/test-suites-and-reports)
- [GetSpot CLAUDE.md](../CLAUDE.md) - Project architecture and patterns
