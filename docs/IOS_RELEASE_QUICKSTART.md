# iOS Release to App Store - Quick Start

**TL;DR:** You're already set up! Just use GitHub Actions to promote TestFlight builds to the App Store.

## ✅ What's Already Configured

The `release.yml` workflow (which builds and uploads to TestFlight) uses these secrets:
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`
- `APP_APPLE_ID`

The new `promote-to-appstore.yml` workflow **uses the same secrets** - no additional setup needed!

---

## 🚀 How to Promote a Build

### Step 1: Build with GitHub Actions
The "Release to testers" workflow (`release.yml`) builds and uploads to TestFlight on pushes to `develop`, version tags, or a manual run. See `docs/RELEASING.md`.

### Step 2: Test in TestFlight
Download and test the build with your team.

### Step 3: Promote to App Store
1. Go to **GitHub Actions** tab in your repo
2. Select **"Promote to App Store"** workflow
3. Click **"Run workflow"**
4. (Optional) Enter build number, or leave empty for latest
5. Click **"Run workflow"** button

### Step 4: Wait for Apple Review
Apple typically reviews within 2-3 days.

### Step 5: Release
After approval, release manually in App Store Connect or run:
```bash
bundle exec fastlane release
```

---

## 📋 Current Workflow Files

### `release.yml`
- **Purpose:** Build and upload to TestFlight (and Play internal testing)
- **Trigger:** Push to `develop`, version tag, or manual (workflow_dispatch)
- **Output:** TestFlight build

### `promote-to-appstore.yml`
- **Purpose:** Promote TestFlight build to App Store Review
- **Trigger:** Manual (workflow_dispatch)
- **Input:** Optional build number
- **Output:** App Store submission

---

## 🎯 Complete Release Flow

```
┌─────────────────────────────────┐
│  GitHub Actions: release.yml    │
│  (Automatic on push)            │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  TestFlight                     │
│  (Auto-uploaded)                │
└────────────┬────────────────────┘
             │
             │ Test with team (1-2 days)
             ▼
┌─────────────────────────────────┐
│  GitHub Actions                 │
│  "Promote to App Store"         │
│  (Click "Run workflow")         │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  App Store Review               │
│  (2-3 days)                     │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  Approved ✅                     │
│  (Release manually or via CLI)  │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  Live on App Store 🎉           │
└─────────────────────────────────┘
```

---

## 🔧 Local Development (Optional)

If you want to run Fastlane locally:

```bash
# Install dependencies
bundle install

# Create local environment file
cp fastlane/.env.default fastlane/.env
# Then edit .env with your credentials

# Promote latest build
bundle exec fastlane promote_to_review

# Promote specific build
bundle exec fastlane promote_build build_number:123
```

---

## 🆘 Troubleshooting

### "Build not found"
- Wait 10-30 minutes after TestFlight upload completes
- Verify build shows up in TestFlight in App Store Connect

### "Authentication failed"
- Check your GitHub Secrets are still valid
- Regenerate App Store Connect API key if needed

### "Metadata validation failed"
- Fix the issue in App Store Connect manually
- Re-run the workflow

---

## 📚 Full Documentation

For detailed information, see: `docs/IOS_RELEASE_AUTOMATION.md`

---

## 🎉 You're Done!

Your iOS release automation is ready to use. Just:
1. Build with GitHub Actions (`release.yml`)
2. Test in TestFlight
3. Click "Run workflow" in GitHub Actions
4. Wait for Apple approval
5. Release! 🚀
