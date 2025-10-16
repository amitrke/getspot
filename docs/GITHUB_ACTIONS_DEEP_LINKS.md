# GitHub Actions Integration for Deep Links

The GitHub Actions workflow has been updated to automatically set up Universal Links / App Links during deployment.

## What Changed

### Updated Workflow: `.github/workflows/firebase-hosting-merge.yml`

**Added Step:**
```yaml
- name: Setup deep links for Universal Links / App Links
  run: |
    echo "Setting up Universal Links / App Links..."
    mkdir -p build/web/.well-known
    cp docs/hosting/apple-app-site-association build/web/.well-known/
    cp docs/hosting/assetlinks.json build/web/.well-known/
    echo "✅ Deep link files copied"
```

**Added Trigger Paths:**
```yaml
paths:
  - 'docs/hosting/**'      # Triggers on deep link config changes
  - 'firebase.json'         # Triggers on Firebase config changes
```

## How It Works

### Automatic Deployment Flow

1. **You push to main:**
   ```bash
   git add .
   git commit -m "Update deep link configuration"
   git push origin main
   ```

2. **GitHub Actions runs:**
   - Checks out code
   - Sets up Flutter
   - Builds web app: `flutter build web`
   - **Copies `.well-known` files** (NEW!)
   - Deploys to Firebase Hosting

3. **Files are deployed:**
   - `https://getspot.app/.well-known/apple-app-site-association`
   - `https://getspot.app/.well-known/assetlinks.json`
   - Flutter web app at root

## When Workflow Triggers

The workflow runs when you push changes to main that affect:
- ✅ `lib/**` - Any Flutter code changes
- ✅ `web/**` - Web-specific files
- ✅ `pubspec.yaml` - Dependency changes
- ✅ `docs/hosting/**` - Deep link config changes (NEW!)
- ✅ `firebase.json` - Firebase config changes (NEW!)

## Configuration Files

The workflow copies these files from your repo:

### Source Files (in repo):
- `docs/hosting/apple-app-site-association` (iOS config)
- `docs/hosting/assetlinks.json` (Android config)

### Destination (in build):
- `build/web/.well-known/apple-app-site-association`
- `build/web/.well-known/assetlinks.json`

### Deployed URLs:
- `https://getspot.app/.well-known/apple-app-site-association`
- `https://getspot.app/.well-known/assetlinks.json`

## Updating Deep Link Configuration

If you need to update the deep link configuration:

1. **Edit the source files:**
   ```bash
   # Edit Apple config
   vim docs/hosting/apple-app-site-association

   # Edit Android config
   vim docs/hosting/assetlinks.json
   ```

2. **Commit and push:**
   ```bash
   git add docs/hosting/
   git commit -m "Update deep link configuration"
   git push origin main
   ```

3. **Workflow runs automatically**
   - Changes are deployed within ~2-3 minutes

4. **Verify:**
   ```bash
   curl https://getspot.app/.well-known/apple-app-site-association
   curl https://getspot.app/.well-known/assetlinks.json
   ```

## Testing Before Production

### Option 1: Local Build + Deploy
```bash
# Run the setup script locally
./scripts/setup-deep-links.sh

# Deploy manually
firebase deploy --only hosting
```

### Option 2: Feature Branch
```bash
# Create feature branch
git checkout -b test-deep-links

# Make changes and push
git add .
git commit -m "Test deep link changes"
git push origin test-deep-links

# Workflow won't run (only runs on main)
# Test locally, then merge to main when ready
```

## Troubleshooting

### Files Not Deployed

**Check workflow logs:**
1. Go to GitHub → Actions tab
2. Find the latest "Deploy to Firebase Hosting" run
3. Check the "Setup deep links" step

**Common issues:**
- Files don't exist at `docs/hosting/`
- Typo in file paths
- Permission issues

**Fix:**
```bash
# Verify files exist
ls -la docs/hosting/

# Should show:
# apple-app-site-association
# assetlinks.json
```

### Workflow Doesn't Trigger

**Make sure you're pushing to main:**
```bash
git branch  # Check current branch
git push origin main  # Must be main, not master or other
```

**Check file paths:**
```bash
# Workflow only triggers for specific paths
git status  # Check what files changed
```

### Files Have Wrong Content

**The workflow copies files as-is from `docs/hosting/`**

1. Verify source files are correct:
   ```bash
   cat docs/hosting/apple-app-site-association
   cat docs/hosting/assetlinks.json
   ```

2. If wrong, edit and push again:
   ```bash
   vim docs/hosting/apple-app-site-association
   git add docs/hosting/
   git commit -m "Fix deep link configuration"
   git push origin main
   ```

3. Wait for deployment (~2-3 minutes)

4. Verify deployed files:
   ```bash
   curl https://getspot.app/.well-known/apple-app-site-association
   ```

## Manual Override

If you need to deploy without triggering the workflow:

```bash
# Build locally
flutter build web

# Copy files manually
mkdir -p build/web/.well-known
cp docs/hosting/apple-app-site-association build/web/.well-known/
cp docs/hosting/assetlinks.json build/web/.well-known/

# Deploy with Firebase CLI
firebase deploy --only hosting
```

## Security Note

The workflow uses `FIREBASE_SERVICE_ACCOUNT_GETSPOT01` secret:
- ✅ Stored in GitHub Secrets (secure)
- ✅ Has write access to Firebase Hosting
- ✅ Never exposed in logs

**Your configuration files (Team ID, SHA-256) are safe to commit** - they're public identifiers.

## Monitoring

### Check Deployment Status

**GitHub Actions:**
- Visit: https://github.com/YOUR_USERNAME/getspot/actions
- Look for green checkmark ✓ on latest commit

**Firebase Console:**
- Visit: https://console.firebase.google.com/project/getspot01/hosting
- Check "Release history" for latest deployment

**Test URLs:**
```bash
# Should return JSON (not 404)
curl https://getspot.app/.well-known/apple-app-site-association
curl https://getspot.app/.well-known/assetlinks.json

# Should return HTML (Flutter web app)
curl https://getspot.app/join/TEST-CODE
```

## Next Steps

After the workflow deploys your changes:

1. **Test on iOS device:**
   - Uninstall and reinstall app
   - Share a group
   - Tap the link
   - Should open app directly

2. **Test on Android device:**
   - Uninstall and reinstall app
   - Verify App Links: `adb shell pm get-app-links org.getspot`
   - Share a group
   - Tap the link
   - Should open app directly

3. **Test web fallback:**
   - Open link in desktop browser
   - Should show Flutter web app with join screen

## Related Documentation

- Quick Setup: `docs/SETUP_DEEP_LINKS.md`
- Full Documentation: `docs/UNIVERSAL_LINKS.md`
- Hosting Files Info: `docs/hosting/README.md`
