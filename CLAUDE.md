# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GetSpot is a Flutter-based event organization app (starting with badminton/sports meetups) with Firebase backend. It enables organizers to create groups, schedule events, manage participants, and handle virtual wallet-based payments.

**Tech Stack:**
- Frontend: Flutter (mobile + web)
- Backend: Firebase (Auth, Firestore, Cloud Functions, Hosting)
- Functions: TypeScript with Node.js 22
- Region: us-east4 (Northern Virginia)

## Common Commands

### Flutter (Mobile/Web)
```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run on Chrome
flutter run -d chrome

# Build for platforms
flutter build apk           # Android APK
flutter build ios           # iOS (requires macOS/Xcode)
flutter build web           # Web (output in build/web)
```

### Firebase Functions
```bash
cd functions

# Install dependencies
npm install  # or pnpm install

# Lint code
npm run lint
npm run lint:fix

# Build TypeScript
npm run build
npm run build:watch

# Local development
npm run serve           # Start emulators (functions only)

# Deploy
npm run deploy          # Deploy functions to Firebase
firebase deploy --only functions

# View logs
npm run logs
```

### Firebase Deployment
```bash
# Deploy everything
firebase deploy

# Deploy specific services
firebase deploy --only hosting
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions
```

## Architecture Patterns

GetSpot uses three distinct architectural patterns for different operations:

### 1. Write-to-Trigger Pattern (Event Registration)
Used for asynchronous, multi-step operations:
- Client writes a "request" document with status `"requested"` (e.g., `/events/{eventId}/participants/{userId}`)
- Firestore Security Rules allow only initial write with status `"requested"`
- `onCreate` Cloud Function is triggered
- Function performs validation (wallet balance, capacity, fairness checks) in trusted environment
- Function updates document with final status (`"Confirmed"`, `"Waitlisted"`, etc.)
- Client's real-time listener updates UI automatically

**Key Functions:** `processEventRegistration`, `withdrawFromEvent`, `processWaitlist`

### 2. Callable Function Pattern (Group Creation)
Used for atomic, synchronous operations requiring transactionality:
- Client calls function with data (e.g., `createGroup`)
- Function verifies authentication via `context.auth`
- Function performs atomic operations (generate unique code, create multiple documents)
- Function returns result to client

**Key Functions:** `manageJoinRequest`, `manageGroupMember`, `cancelEvent`

### 3. Denormalized Data Lookup (User Memberships)
For efficient queries without expensive collection group queries:
- `/userGroupMemberships/{userId}/groups/{groupId}` stores each user's group memberships
- Enables fast lookup of all groups for a user
- Backend maintains consistency via Functions
- Powers the home screen query for performance

## Data Model

**Root Collections:**
- `/users` - User profiles with FCM tokens
- `/groups` - Groups with subcollections: `/members`, `/joinRequests`, `/announcements`
- `/events` - Events (root-level for cross-group querying) with subcollection: `/participants`
- `/transactions` - Financial activity log (root-level for efficient user queries)
- `/userGroupMemberships` - Denormalized user→groups index

**Key Design Decisions:**
- Events and transactions are root-level (not subcollections) to enable efficient cross-group queries
- `/userGroupMemberships` denormalizes group membership to avoid expensive collection group queries
- Events store denormalized `confirmedCount` and `waitlistCount` for fast reads
- See `docs/DATA_MODEL.md` for detailed rationale and consistency guarantees

**Invariants Enforced by Functions:**
- Single membership per (groupId, uid)
- Participant capacity limits per event
- Wallet balance constraints per group
- Atomic multi-document updates via batched writes/transactions
- Denormalized counts and indexes maintained atomically

**Timestamp Handling:**
- All timestamps stored in UTC (Firestore `Timestamp` type)
- Flutter client converts to/from local timezone for display

**Composite Indexes:**
- Defined in `firestore.indexes.json`
- Deploy with: `firebase deploy --only firestore:indexes`
- See `docs/DATA_MODEL.md` for complete index documentation

## Code Structure

### Flutter (`lib/`)
- `main.dart` - App entry point
- `firebase_options.dart` - Firebase configuration
- `screens/` - UI screens (home, login, group details, event details, etc.)
- `services/` - Business logic services
  - `auth_service.dart` - Authentication logic
  - `group_service.dart` - Group and membership queries
  - `notification_service.dart` - Push notification handling
  - `user_cache_service.dart` - User profile caching (15min TTL)
  - `group_cache_service.dart` - Group metadata caching (30min TTL)
- `widgets/` - Reusable UI components
- `models/` - Data models
- `helpers/` - Utility functions

### Firebase Functions (`functions/src/`)
- `index.ts` - Function exports and registration
- Individual function files: `processEventRegistration.ts`, `manageJoinRequest.ts`, etc.
- `dataLifecycle.ts` - Data retention and lifecycle management
- `maintainJoinRequestCount.ts` - Firestore triggers to maintain `pendingJoinRequestsCount`
- `migrations/` - One-time migration scripts
- Functions compile from `src/` to `lib/` (TypeScript → JavaScript)

## Development Guidelines

From CONTRIBUTING.md:
- **Prefer Cloud Function triggers for invariants** (membership index, participant capacity)
- **Use batched writes/transactions** for multi-document consistency
- **Add composite indexes proactively** when introducing new multi-field queries
- **Include short rationale comments** at top of new functions for maintainability

## Testing

Currently the project has basic testing infrastructure. When adding tests, ensure:
- Widget tests for UI components
- Integration tests for critical user flows
- Function tests use `firebase-functions-test` (see `functions/package.json`)

## Firebase Configuration

- Project ID: `getspot01`
- Firestore rules: `firestore.rules`
- Hosting serves from: `build/web`
- Functions predeploy: runs `npm run lint` and `npm run build`
- All resources deployed to us-east4

## Important Notes

- **Security:** Firestore Security Rules enforce read/write permissions. Functions operate in trusted environment with admin SDK.
- **Real-time Updates:** Client uses Firestore real-time listeners for UI updates (participants, wallet balance, etc.).
- **Push Notifications:** FCM tokens stored in `/users/{uid}.fcmTokens` array. Managed by `updateFcmToken` function.
- **Data Lifecycle:** `dataLifecycle.ts` handles account deletion requests and data retention policies.
- **Caching:** `UserCacheService` and `GroupCacheService` cache frequently-accessed data with TTL. Always call `invalidate()` after updates:
  - `UserCacheService().invalidate(userId)` after updating user display name
  - `GroupCacheService().invalidate(groupId)` after updating group metadata (when implemented)
