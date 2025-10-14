# GetSpot - Product Requirements & Roadmap

This document consolidates product requirements, implemented features, and future roadmap for GetSpot.

**Last Updated:** 2025-10-13

---

## Table of Contents
1. [Vision & Goals](#vision--goals)
2. [User Roles](#user-roles)
3. [Core Concepts](#core-concepts)
4. [Implemented Features](#implemented-features)
5. [In Progress](#in-progress)
6. [Planned Features](#planned-features)
7. [Future Ideas](#future-ideas)
8. [Technical Debt & Bug Fixes](#technical-debt--bug-fixes)

---

## Vision & Goals

GetSpot streamlines the organization of local sports meetups, starting with badminton. The app connects organizers with participants, simplifying event creation, registration, and communication, with a focus on recurring games for established groups.

### Key Success Metrics
- Group retention rate
- Events per group per month
- Participant registration rate
- Wallet transaction volume
- User-reported satisfaction

---

## User Roles

### Participant (Default Role)
Every user starts as a participant with these capabilities:
- ✅ Request to join groups
- ✅ View and register for events
- ✅ Manage event attendance
- ✅ View wallet balance and transaction history
- ✅ Receive push notifications

### Organizer (Group Admin)
Users who create groups automatically become admins with additional capabilities:
- ✅ Create and manage groups
- ✅ Approve/deny join requests
- ✅ Create and cancel events
- ✅ Credit virtual currency to member wallets
- ✅ Remove members from groups
- ✅ Post announcements to group

---

## Core Concepts

### Groups
- ✅ Any user can create a group with unique shareable code
- ✅ Membership requires admin approval
- ✅ Each group has configurable negative balance limit
- ✅ Members can belong to multiple groups

### Event Commitment & Fee Model
**Philosophy:** Ensure event spots are paid for, giving organizers confidence to manage events.

**Flow:**
1. ✅ Participant must have sufficient balance: `walletBalance + negativeBalanceLimit >= fee`
2. ✅ Fee deducted immediately upon registration
3. ✅ Status assigned: "Confirmed" (spot available) or "Waitlisted" (event full)
4. ✅ Withdrawals before commitment deadline: full refund
5. ✅ Withdrawals after deadline: forfeit fee (unless spot filled from waitlist)
6. ✅ Automatic waitlist promotion when spots open
7. ✅ Automatic refunds for unfilled waitlist spots after event ends

### Virtual Currency
- ✅ Organizers "sell" virtual currency offline
- ✅ Organizers credit participant wallets via app
- ✅ Participants use currency for event fees
- ✅ Transaction history tracked per user
- 📋 Future: Real payment integration (Stripe)

### Waitlist System
- ✅ Join waitlist when event is full (fee paid upfront)
- ✅ Automatic promotion to confirmed when spot opens
- ✅ Withdraw anytime for full refund
- ✅ Automatic refund if event ends without getting spot

---

## Implemented Features

### ✅ Group Management
**Status:** Production | **Added:** Launch

- [x] Create group with unique code generation
- [x] View and share group code
- [x] Approve/deny join requests
- [x] View member list with wallet balances
- [x] Remove members (with balance validation)
- [x] Set negative balance limit per group
- [x] Post announcements to all members
- [x] View pending join request count

**Files:** `lib/screens/group_details_screen.dart`, `functions/src/manageGroupMember.ts`

---

### ✅ Event Management
**Status:** Production | **Added:** Launch

**For Organizers:**
- [x] Create events with date, time, location, capacity, fee
- [x] Set commitment deadline
- [x] View participant list (confirmed, waitlisted, pending)
- [x] Cancel events with automatic refunds
- [x] Send announcements to registered participants
- [x] Monitor registration counts in real-time

**For Participants:**
- [x] View event details
- [x] Register for events (first-come, first-served processing)
- [x] Withdraw from events (with penalty after deadline)
- [x] Join waitlist when full
- [x] Real-time status updates
- [x] Confirmation dialogs for withdrawals

**Not Yet Implemented:**
- [ ] Adjust capacity after creation
- [ ] Clear "denied" status for re-registration
- [ ] Recurring event templates
- [ ] View personal registration history

**Files:** `lib/screens/event_details_screen.dart`, `functions/src/processEventRegistration.ts`, `functions/src/cancelEvent.ts`

---

### ✅ Virtual Wallet System
**Status:** Production | **Added:** Launch

- [x] Display wallet balance per group
- [x] Credit wallet (organizer only)
- [x] Automatic fee deduction on registration
- [x] Automatic refunds on withdrawal/cancellation
- [x] Transaction history with descriptions
- [x] Two decimal place precision
- [x] Negative balance enforcement with limits

**Files:** `lib/screens/group_details_screen.dart`, `lib/screens/member_profile_screen.dart`

---

### ✅ Authentication
**Status:** Production | **Added:** Launch

- [x] Google Sign-In (Android, iOS, Web)
- [x] Apple Sign-In (iOS)
- [x] User profile with display name and photo
- [x] Edit display name
- [x] Logout functionality

**Not Yet Implemented:**
- [ ] Email/password authentication
- [ ] Email verification
- [ ] 2FA for admins
- [ ] Custom profile picture upload

**Files:** `lib/services/auth_service.dart`, `lib/screens/login_screen.dart`

---

### ✅ Push Notifications
**Status:** Production | **Added:** 2025-10-08

- [x] Event created
- [x] Join request approved/denied
- [x] Event cancelled
- [x] Waitlist promoted
- [x] Event reminder (24h before)
- [x] Toggle notifications on/off
- [x] FCM token management

**Not Yet Implemented:**
- [ ] Granular notification preferences
- [ ] Email notification fallback
- [ ] In-app notification center
- [ ] Notification history

**Files:** `lib/services/notification_service.dart`, `functions/src/sendNotification.ts`

---

### ✅ Analytics & Monitoring
**Status:** Production | **Added:** 2025-10-10

- [x] Firebase Analytics for user behavior
- [x] Firebase Crashlytics for error tracking
- [x] Custom event logging
- [x] Screen view tracking
- [x] User context in crash reports

**Files:** `lib/services/analytics_service.dart`, `lib/services/crashlytics_service.dart`

---

### ✅ Feature Flags
**Status:** Production | **Added:** 2025-10-13

- [x] Firebase Remote Config integration
- [x] User-specific feature flags
- [x] Crash test debug tools
- [x] 1-hour cache with manual refresh

**Files:** `lib/services/feature_flag_service.dart`, `docs/FEATURE_FLAGS.md`

---

### ✅ Data Lifecycle
**Status:** Production | **Added:** 2025-10-05

- [x] Archive old events (90 days after end)
- [x] Archive old transactions (90 days)
- [x] Archive inactive groups (180 days)
- [x] Archive inactive users (365 days)
- [x] Delete join requests (30 days)
- [x] User-initiated account deletion
- [x] GCS 2-year deletion policy

**Files:** `functions/src/dataLifecycle.ts`

---

### ✅ Developer Tools
**Status:** Production

- [x] In-app version upgrade prompts
- [x] Pull-to-refresh on home screen
- [x] Loading states and error handling
- [x] Crash test buttons (feature-flagged)
- [x] Analytics and Crashlytics integration

**Files:** `lib/main.dart`, `pubspec.yaml`

---

## In Progress

### 📋 Separate Dev/Prod Environments
**Status:** Planned | **Priority:** High

- [ ] Configure separate Firebase projects for dev and prod
- [ ] Environment-specific builds
- [ ] Testing without affecting production data

**See:** `docs/ENVIRONMENTS.md`

---

### 📋 Legal Compliance
**Status:** Required for App Stores | **Priority:** High

- [ ] Terms of Service document
- [ ] Privacy Policy document
- [ ] Accept ToS checkbox during signup
- [ ] Links in app settings
- [ ] GDPR data export functionality

---

## Planned Features

Features organized by priority and implementation complexity.

### High Priority

#### Error Handling & UX Improvements
**Complexity:** Medium | **Impact:** High | **Timeline:** 1-2 weeks

- [ ] Retry mechanisms for failed network requests
- [ ] Offline mode detection
- [ ] Skeleton screens instead of spinners
- [ ] Better error messages (no raw exceptions)
- [ ] Timeout handling for Cloud Functions
- [ ] Exponential backoff for retries

**Rationale:** Better error handling reduces support requests

---

#### Performance Optimization
**Complexity:** Medium-High | **Impact:** High | **Timeline:** 2-3 weeks

- [ ] Pagination for event lists
- [ ] Lazy loading for user avatars
- [ ] Incremental data loading for large groups
- [ ] Query result caching with TTL
- [ ] Optimize Firestore composite indexes

**Rationale:** Critical as groups grow larger

**Next Step:** Add Firebase Performance Monitoring (see FIREBASE_FEATURES.md)

---

#### Admin Dashboard
**Complexity:** High | **Impact:** High | **Timeline:** 3-4 weeks

- [ ] Group statistics (attendance rate, revenue)
- [ ] Member activity tracking
- [ ] Export functionality (CSV/PDF)
- [ ] Bulk operations (select multiple events/members)
- [ ] Template events (save and reuse configurations)
- [ ] Automated recurring events

**Rationale:** Admin efficiency impacts group management quality

---

#### Enhanced Search & Filtering
**Complexity:** Medium | **Impact:** High | **Timeline:** 1-2 weeks

- [ ] Search events by name/date
- [ ] Filter by event status (upcoming, past, my events)
- [ ] Calendar view for events
- [ ] Quick filters UI
- [ ] Sort options (date, participants, fee)

**Rationale:** Essential as event lists grow

---

### Medium Priority

#### Social Features
**Complexity:** Medium-High | **Impact:** Medium | **Timeline:** 3-4 weeks

- [ ] Event ratings and feedback
- [ ] Achievement badges for participants
- [ ] Leaderboards (most active, attendance streaks)
- [ ] Event photo sharing
- [ ] Social media sharing integration
- [ ] "Member of the Month" recognition

**Rationale:** Increases engagement and community building

---

#### Payment Improvements
**Complexity:** High | **Impact:** High | **Timeline:** 4-6 weeks

- [ ] Stripe/PayPal integration
- [ ] Auto-recharge when balance low
- [ ] Payment reminders for negative balances
- [ ] Expense splitting among participants
- [ ] Automated refund processing
- [ ] Multi-currency support

**Rationale:** Eliminate manual payment tracking

---

#### Enhanced Notifications
**Complexity:** Medium | **Impact:** Medium | **Timeline:** 2 weeks

- [ ] Granular notification preferences
- [ ] Email notification fallback
- [ ] In-app notification center
- [ ] Notification history
- [ ] Digest notifications (daily/weekly)
- [ ] Smart notifications (user's active hours only)

**Rationale:** Reduces notification fatigue

---

#### Member Profiles
**Complexity:** Medium | **Impact:** Medium | **Timeline:** 2 weeks

- [ ] Custom profile pictures (with Cloud Storage)
- [ ] Member stats (events attended, reliability score)
- [ ] Bio/about section
- [ ] Sport preferences
- [ ] Availability calendar

**Rationale:** Enhances community feeling

---

### Lower Priority

#### Advanced Features
**Complexity:** High | **Impact:** Medium | **Timeline:** 4-8 weeks

- [ ] Multi-sport categorization
- [ ] Venue management (availability, ratings, directions)
- [ ] Equipment tracking
- [ ] Skill-based player matching
- [ ] Tournament bracket mode
- [ ] Google/Apple Calendar sync
- [ ] Weather integration for outdoor events
- [ ] Car pooling coordination

**Rationale:** Differentiation from competitors

---

#### Internationalization
**Complexity:** Medium | **Impact:** Medium | **Timeline:** 3-4 weeks

- [ ] Multi-language support (Spanish, French, German, Chinese, Hindi)
- [ ] Currency localization
- [ ] Date/time format localization
- [ ] RTL language support
- [ ] Locale-specific regulations

**Rationale:** Required for international expansion

---

#### Accessibility
**Complexity:** Medium | **Impact:** Medium | **Timeline:** 2-3 weeks

- [ ] Full screen reader support
- [ ] Keyboard navigation (web)
- [ ] Semantic labels throughout app
- [ ] High contrast mode
- [ ] Font size adjustment
- [ ] Color blind friendly schemes
- [ ] Reduced motion mode

**Rationale:** Ensure app is usable by everyone

---

#### Testing Infrastructure
**Complexity:** Medium-High | **Impact:** High | **Timeline:** 3-4 weeks

- [ ] Widget tests for critical UI
- [ ] Integration tests for key flows
- [ ] E2E tests with Flutter Driver
- [ ] Performance profiling
- [ ] Automated regression testing
- [ ] Load testing for Cloud Functions
- [ ] Security testing

**Rationale:** Prevent bugs and regressions

---

## Future Ideas

Features for consideration once product-market fit is established.

### Quick Wins (Low Effort, Medium Impact)

Can be implemented in 1-2 days each:

1. [ ] Swipe-to-delete for admin actions
2. [ ] Haptic feedback on important actions
3. [ ] Empty state illustrations
4. [ ] Deep linking for event sharing (see FIREBASE_FEATURES.md)
5. [ ] "Copy event link" button
6. [ ] Participant avatar previews in lists
7. [ ] Event countdown timer
8. [ ] "Mark as read" for announcements
9. [ ] Last active time for members
10. [ ] Undo functionality for common actions
11. [ ] Share button for group code
12. [ ] Network status indicator
13. [ ] App version display in settings
14. [ ] Splash screen animations
15. [ ] Onboarding tutorial flow
16. [ ] "New" badge on announcements

---

### Community Requests

Track user-requested features here with dates and source.

#### Completed
- ✅ **2025-10-08** - Improved FAQ section
- ✅ **2025-10-08** - Fix Google sign-in navigation
- ✅ **2025-10-13** - Feature flags for debug tools

#### Pending
- _Add new requests here_

---

## Technical Debt & Bug Fixes

### Known Issues

**Authentication:**
- [ ] Google sign-in on web doesn't trigger auth stream reliably (workaround implemented)

**UI/Performance:**
- [ ] Profile pictures not loading consistently
- [ ] Occasional race condition in wallet balance updates
- [ ] Memory leaks in event listeners (needs investigation)

**Data:**
- [ ] Missing validation for some edge cases in event capacity changes

---

### Code Quality Improvements

**Architecture:**
- [ ] Implement proper state management (Provider/Riverpod/Bloc)
- [ ] Reduce nested StreamBuilders
- [ ] Refactor large widget files into smaller components

**Code Cleanup:**
- [ ] Extract hardcoded strings to localization files
- [ ] Consolidate duplicate code in service classes
- [ ] Remove commented-out code and debug logs
- [ ] Standardize date/time handling across app

**Type Safety:**
- [ ] Improve error types with custom exceptions
- [ ] Add type safety to Firestore document conversions
- [ ] Better null safety handling

**Performance:**
- [ ] Optimize widget rebuild performance
- [ ] Reduce unnecessary Firestore reads
- [ ] Implement more aggressive caching

---

## Implementation Guidelines

### Before Starting Any Feature

1. Review `ARCHITECTURE.md` and `DATA_MODEL.md`
2. Check if feature requires backend changes
3. Consider impact on existing features
4. Estimate complexity and time
5. Create detailed implementation plan
6. Get stakeholder approval if needed

### After Completing Any Feature

1. Update this document (move to "Implemented")
2. Update user-facing docs (FAQ, help screens)
3. Add to release notes
4. Monitor for issues after deployment
5. Gather user feedback

### Definition of Done

- [ ] Feature implemented and tested
- [ ] Security rules updated (if needed)
- [ ] Cloud Functions deployed (if needed)
- [ ] Documentation updated
- [ ] No new Crashlytics errors
- [ ] Analytics tracking added
- [ ] User-facing announcement prepared (if major feature)

---

## Priority & Complexity Definitions

### Priority Levels
- **High:** Critical for user satisfaction or business goals, do within 1 month
- **Medium:** Important but not urgent, schedule within 3 months
- **Low:** Nice to have, implement when resources available

### Complexity Estimates
- **Low:** < 1 day (4-8 hours)
- **Medium:** 1-3 days (8-24 hours)
- **High:** > 3 days (24+ hours)

---

## Review Schedule

- **Weekly:** Check community requests, update status of in-progress items
- **Monthly:** Reassess priorities based on user feedback and analytics
- **Quarterly:** Major roadmap review, add/remove items

---

## Related Documentation

- `ARCHITECTURE.md` - System architecture and patterns
- `DATA_MODEL.md` - Firestore data structure
- `FIREBASE_FEATURES.md` - Firebase services roadmap
- `USER_JOURNEYS.md` - User flow documentation
- `FEATURE_FLAGS.md` - Remote Config setup
- `CLAUDE.md` - Developer quick reference

---

**Next Review Date:** 2025-11-13
