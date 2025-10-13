# Firebase Features in GetSpot

This document tracks Firebase features currently used in GetSpot and recommends additional features to enhance the application.

**Last Updated:** 2025-10-13

---

## Currently Implemented ✅

### 1. Firebase Authentication
**Status:** Production | **Added:** Launch

**Purpose:** User authentication and identity management

**Implementation:**
- Google Sign-In (Android, iOS, Web)
- Apple Sign-In (iOS)
- User profiles stored in `/users` collection

**Files:**
- `lib/services/auth_service.dart`
- `lib/screens/login_screen.dart`

---

### 2. Cloud Firestore
**Status:** Production | **Added:** Launch

**Purpose:** NoSQL database for app data

**Implementation:**
- Collections: `users`, `groups`, `events`, `transactions`, `userGroupMemberships`
- Security rules in `firestore.rules`
- Composite indexes in `firestore.indexes.json`
- Real-time listeners for live updates

**Files:**
- `firestore.rules` - Security rules
- `firestore.indexes.json` - Query indexes
- `docs/DATA_MODEL.md` - Data model documentation

---

### 3. Cloud Functions
**Status:** Production | **Added:** Launch

**Purpose:** Serverless backend logic

**Implementation:**
- Region: us-east4
- Node.js 22, TypeScript
- 15+ functions for event registration, group management, notifications

**Key Functions:**
- `processEventRegistration` - Handle event signups
- `manageJoinRequest` - Approve/deny group requests
- `createGroup` - Atomic group creation
- `cancelEvent` - Event cancellation with refunds
- `sendNotification` - Push notification delivery
- `runDataLifecycleManagement` - Scheduled data cleanup

**Files:**
- `functions/src/` - All Cloud Functions
- `functions/package.json` - Dependencies

---

### 4. Firebase Crashlytics
**Status:** Production | **Added:** 2025-10-10

**Purpose:** Crash reporting and error tracking

**Implementation:**
- Singleton service: `CrashlyticsService`
- Automatic crash collection
- Custom error logging
- User context tracking

**Files:**
- `lib/services/crashlytics_service.dart`
- `lib/main.dart:37-44` - Initialization

**Usage:**
```dart
// Log errors
await CrashlyticsService().logError(error, stackTrace);

// Add context
await CrashlyticsService().setUserId(userId);
await CrashlyticsService().setCustomKey('group_id', groupId);
```

---

### 5. Firebase Analytics
**Status:** Production | **Added:** 2025-10-10

**Purpose:** User behavior analytics and event tracking

**Implementation:**
- Singleton service: `AnalyticsService`
- Screen view tracking
- Custom event logging
- User properties

**Files:**
- `lib/services/analytics_service.dart`
- `lib/main.dart:66` - NavigatorObserver

**Tracked Events:**
- `login`, `logout`
- `create_group`, `join_group`
- `create_event`, `register_event`, `withdraw_event`
- Screen views (automatic)

---

### 6. Firebase Cloud Messaging (FCM)
**Status:** Production | **Added:** 2025-10-08

**Purpose:** Push notifications

**Implementation:**
- Singleton service: `NotificationService`
- FCM tokens stored in `/users/{uid}.fcmTokens` array
- Background message handler
- Foreground notification display

**Files:**
- `lib/services/notification_service.dart`
- `functions/src/sendNotification.ts`
- `lib/main.dart:18-28` - Background handler

**Notification Types:**
- New events
- Join request approved/denied
- Event cancellations
- Waitlist promotions
- Event reminders

---

### 7. Firebase Hosting
**Status:** Production | **Added:** Launch

**Purpose:** Web app hosting

**Implementation:**
- Hosts Flutter web build
- Custom domain: www.getspot.org
- Serves from `build/web`

**Files:**
- `firebase.json` - Hosting configuration

---

### 8. Firebase Remote Config
**Status:** Production | **Added:** 2025-10-13

**Purpose:** Feature flags and dynamic configuration

**Implementation:**
- Singleton service: `FeatureFlagService`
- 1-hour cache interval
- Current flags: `crash_test_enabled_users`

**Files:**
- `lib/services/feature_flag_service.dart`
- `docs/FEATURE_FLAGS.md` - Setup guide

**Usage:**
```dart
// Initialize at startup
await FeatureFlagService().initialize();

// Check feature access
if (FeatureFlagService().canAccessCrashTest(userId)) {
  // Show debug tools
}
```

---

## Recommended Additions 🎯

### Priority 1: High Impact, Easy to Implement

#### 1. Firebase Performance Monitoring
**Effort:** Low (2-4 hours) | **Impact:** High

**Why:** Identify performance bottlenecks and slow operations

**Benefits:**
- Automatic app startup time tracking
- Network request duration monitoring
- Screen rendering performance
- Custom trace support

**Implementation Plan:**
1. Add dependency: `firebase_performance: ^0.10.0`
2. Initialize in `main.dart`
3. Add custom traces for critical flows:
   - Event registration process
   - Group loading time
   - Firestore query performance

**Estimated Cost:** Free (within Firebase Spark plan limits)

**Priority:** ⭐⭐⭐⭐⭐ (Do this first!)

---

#### 2. Firebase App Check
**Effort:** Medium (4-8 hours) | **Impact:** High (Security)

**Why:** Protect backend from abuse and unauthorized access

**Benefits:**
- Verify requests come from legitimate app
- Prevent bot abuse of Cloud Functions
- Protect Firestore from unauthorized clients
- Essential for production security

**Implementation Plan:**
1. Enable App Check in Firebase Console
2. Add dependency: `firebase_app_check: ^0.3.0`
3. Configure attestation providers:
   - iOS: DeviceCheck (production), Debug (development)
   - Android: Play Integrity API (production), Debug (development)
   - Web: reCAPTCHA v3
4. Enforce App Check in Cloud Functions
5. Enable Firestore App Check enforcement

**Estimated Cost:** Free (within generous limits)

**Priority:** ⭐⭐⭐⭐⭐ (Critical before scaling)

**Security Note:** Prevents malicious actors from calling your Cloud Functions directly

---

### Priority 2: High Impact, Medium Effort

#### 3. Firebase Dynamic Links
**Effort:** Medium (6-10 hours) | **Impact:** High (UX)

**Why:** Better sharing and deep linking

**Benefits:**
- Smart event invitation links
- Group invitation links (replace codes)
- Deep linking to specific screens
- App install attribution
- Works across platforms (iOS/Android/Web)

**Use Cases:**
- "Join this event" → Opens app to event details or App Store if not installed
- "Join my group" → Direct link instead of typing group code
- Share event results/photos
- Re-engagement campaigns

**Implementation Plan:**
1. Configure Dynamic Links in Firebase Console
2. Add dependency: `firebase_dynamic_links: ^5.5.0`
3. Create link patterns:
   - `https://getspot.page.link/event/{eventId}`
   - `https://getspot.page.link/group/{groupCode}`
4. Handle incoming links in app
5. Update sharing features to use Dynamic Links

**Estimated Cost:** Free (within limits, then $1/1000 links)

**Priority:** ⭐⭐⭐⭐ (Significantly improves UX)

---

#### 4. Firebase Cloud Storage
**Effort:** Medium (6-10 hours) | **Impact:** Medium-High

**Why:** Store user-generated images

**Benefits:**
- Custom profile pictures
- Group logos/banners
- Event photos
- Automatic image resizing (with extension)
- CDN-backed delivery

**Current Gap:** Can only use Google/Apple profile pictures

**Implementation Plan:**
1. Add dependency: `firebase_storage: ^12.3.2`
2. Create storage structure:
   - `/users/{uid}/profile.jpg`
   - `/groups/{groupId}/banner.jpg`
   - `/events/{eventId}/photos/{photoId}.jpg`
3. Add image upload UI
4. Configure Storage Security Rules
5. Implement image picker integration
6. Optional: Add Firebase Image Resizing extension

**Estimated Cost:** $0.026/GB stored, $0.12/GB downloaded (generous free tier)

**Priority:** ⭐⭐⭐ (Nice to have, enhances personalization)

---

### Priority 3: Medium Impact

#### 5. Firebase In-App Messaging
**Effort:** Low-Medium (3-6 hours) | **Impact:** Medium

**Why:** Contextual messages and user education

**Benefits:**
- Onboarding tips for new users
- Feature announcements
- Contextual prompts based on behavior
- A/B test message variants
- No code required after setup

**Use Cases:**
- "Create your first event!" after joining group
- "Invite friends to earn badges" for group admins
- App rating prompts after positive interactions
- New feature announcements

**Implementation Plan:**
1. Add dependency: `firebase_in_app_messaging: ^0.8.0`
2. Initialize in `main.dart`
3. Create campaigns in Firebase Console
4. Set targeting rules (user segments, behavior)
5. Design message templates

**Estimated Cost:** Free

**Priority:** ⭐⭐⭐ (Good for engagement)

---

### Priority 4: Lower Priority

#### 6. Firebase A/B Testing
**Effort:** Low (2-4 hours) | **Impact:** Medium (once you have traffic)

**Why:** Test UI/UX variations

**Note:** Requires sufficient user base for statistical significance

**Use Cases:**
- Test different event card layouts
- Optimize onboarding flow
- Test notification copy
- Button placement experiments

**Priority:** ⭐⭐ (Wait until you have 1000+ active users)

---

#### 7. Firebase Extensions

Several pre-built extensions could be useful:

**Stripe Payments** - If adding real money payments
- Priority: ⭐⭐⭐ (when ready to monetize)

**Trigger Email** - Email notifications alongside push
- Priority: ⭐⭐ (good fallback for users who disable push)

**Image Resizing** - Auto-create thumbnails
- Priority: ⭐⭐⭐ (use with Cloud Storage)

**Algolia Search** - Better search for groups/events
- Priority: ⭐⭐ (nice to have for large user bases)

---

## Not Recommended (Yet)

### Firebase ML Kit
**Why Not:** No obvious ML use case currently
**Reconsider When:** Adding features like photo moderation, text recognition

### Firebase Test Lab
**Why Not:** Overkill without comprehensive test suite
**Reconsider When:** You have extensive integration tests

### Firebase App Distribution
**Why Not:** Not actively doing beta testing
**Reconsider When:** Need to distribute test builds to beta testers

### Google Analytics 4 (GA4)
**Why Not:** Firebase Analytics is sufficient
**Reconsider When:** Need web-specific analytics or BigQuery integration

---

## Implementation Roadmap

### Phase 1: Performance & Security (This Month)
**Total Time:** 6-12 hours

1. ✅ Firebase Remote Config (Completed 2025-10-13)
2. 🎯 Firebase Performance Monitoring (2-4 hours)
3. 🎯 Firebase App Check (4-8 hours)

**Rationale:** Foundation for scaling safely

---

### Phase 2: Enhanced Sharing (Next Month)
**Total Time:** 6-10 hours

4. 🎯 Firebase Dynamic Links (6-10 hours)

**Rationale:** Significant UX improvement for viral growth

---

### Phase 3: User-Generated Content (Q1 2026)
**Total Time:** 6-10 hours

5. 🎯 Firebase Cloud Storage (6-10 hours)
6. 🎯 Image Resizing Extension (1 hour)

**Rationale:** Enhances personalization and engagement

---

### Phase 4: Engagement (Q2 2026)
**Total Time:** 3-6 hours

7. 🎯 Firebase In-App Messaging (3-6 hours)
8. 🎯 Email Extension (2 hours)

**Rationale:** Improve retention and feature discovery

---

### Phase 5: Optimization (Future)
**Timing:** When user base reaches 1000+ MAU

9. 🎯 Firebase A/B Testing
10. 🎯 Algolia Search (if search becomes pain point)

---

## Cost Estimates

**Current Monthly Cost:** ~$0 (within free tier)

**After Recommended Additions:**

| Feature | Free Tier | Estimated Monthly Cost |
|---------|-----------|------------------------|
| Performance Monitoring | 90% free | $0 |
| App Check | Very generous | $0 |
| Dynamic Links | 50k links/month free | $0-5 |
| Cloud Storage | 5 GB free | $0-10 |
| In-App Messaging | Unlimited | $0 |
| A/B Testing | Unlimited | $0 |

**Total Estimated:** $0-15/month at 1000 MAU

---

## Monitoring & Maintenance

### Firebase Console Dashboards to Monitor

1. **Analytics** - User engagement, retention
2. **Crashlytics** - Crash-free rate, top crashes
3. **Performance** - App startup time, screen rendering
4. **Cloud Messaging** - Delivery rates, open rates
5. **Remote Config** - Parameter fetch success
6. **App Check** - Valid vs. invalid requests (when implemented)

### Regular Review Schedule

- **Weekly:** Crashlytics errors, Performance alerts
- **Monthly:** Analytics trends, FCM delivery rates
- **Quarterly:** Feature flag cleanup, Storage usage review

---

## Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Firebase Extensions](https://extensions.dev/)

---

## Questions?

For Firebase setup questions, see:
- `docs/FEATURE_FLAGS.md` - Remote Config setup
- `docs/FIREBASE_ANALYTICS.md` - Analytics implementation
- `docs/FIREBASE_CRASHLYTICS.md` - Crashlytics setup
- `CLAUDE.md` - Overall architecture and patterns
