# Documentation Archive

This folder contains historical documentation from completed tasks and projects. These files are preserved for reference but are no longer actively maintained.

## Contents

### Database Optimization Project (2025-10)
- `TASK-Database-Optimization.md` - Original task specification
- `SUMMARY-Database-Optimization.md` - Implementation summary
- `MIGRATION-PendingJoinRequestsCount.md` - Migration details (✅ Completed 2025-10-07)
- `DEPLOYMENT-Checklist-Database-Optimization.md` - Deployment checklist
- `DEPLOYMENT-GUIDE.md` - Quick deployment guide for optimization (archived 2025-10-24)

### Completed Feature Tasks
- `TASK-Implement-Event-Cancellation.md` - Event cancellation feature (✅ Completed)
- `TASK-Implement-Push-Notifications.md` - Push notification system (✅ Completed)
- `TASK-Implement-Email-Password-Auth.md` - Email/password authentication (✅ Completed — implemented in `lib/services/auth_service.dart` and `lib/screens/login_screen.dart`, despite the task doc's own checklist being the only place that noted this)

### Resolved Troubleshooting Docs
- `FIX_IOS_CRASHLYTICS.md` - iOS Crashlytics dSYM upload fix (✅ Applied — the "Upload Crashlytics Symbols" build phase it describes is already in `ios/Runner.xcodeproj/project.pbxproj`; see `CLAUDE.md`'s Crashlytics section for the current steady-state setup)
- `NOTIFICATION_DEBUGGING.md` - Point-in-time log of push-notification fixes (iOS Info.plist, Android permissions, debug logging) that are now permanently baked into the codebase. Its still-useful diagnostic content (Xcode capability setup, APNs config, verbose FCM logging) was merged into `../PUSH_NOTIFICATIONS_TESTING.md`.

## Why Archive?

These documents are archived rather than deleted to:
- Preserve implementation context and decisions
- Serve as templates for similar future tasks
- Maintain project history beyond git commits
- Allow easy reference without cluttering active documentation

## Active Documentation

For current documentation, see:
- **Product & Planning:** `../PRODUCT.md` - Requirements and roadmap
- **Technical:** `../ARCHITECTURE.md`, `../DATA_MODEL.md`
- **Firebase:** `../FIREBASE_FEATURES.md`
- **All Docs:** `../../README.md` - Complete documentation index

---

**Note:** If you're looking for current requirements or feature backlog, see `../PRODUCT.md` instead.
