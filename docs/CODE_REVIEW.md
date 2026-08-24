# Code Review Findings

This document captures the code review findings for the GetSpot project conducted on January 2026.

## Summary

| Priority | Count | Area |
|----------|-------|------|
| **Critical** | 2 | Unbounded queries, App Check enforcement |
| **High** | 8 | Code duplication, state management, collection group query load |
| **Medium** | 12 | Type safety, logging, Firebase patterns, Firestore rule optimization |
| **Low** | 7 | Widget composition, magic numbers, pagination, offline support |

---

## Critical Issues

### 1. Unbounded Firestore Queries

**Status:** ✅ Fixed

**Locations:**
- `lib/services/group_service.dart:36-39` - participants collection group query
- `lib/services/event_cache_service.dart:132-138` - events query

**Risk:** Performance degradation and quota issues at scale. Without limits, these queries could return thousands of documents.

**Fix:** Add `.limit(100)` to both queries.

### 2. App Check Not Enforced

**Status:** ⚠️ Documented (intentional for now)

**Location:** `functions/src/index.ts:58-60`

**Details:** App Check is in metrics-only mode. Should transition to enforcement mode once metrics confirm legitimate traffic patterns.

---

## High-Impact Improvements

### 1. Code Duplication - User Document Creation

**Status:** 📋 Backlog

**Location:** `lib/services/auth_service.dart` - lines 57, 127, 206-211, 336-342

**Issue:** User document creation logic duplicated in 3+ places.

**Recommendation:** Extract to `_createOrUpdateUserDocument()` method.

### 2. Cache Invalidation Boilerplate

**Status:** ✅ Fixed

**Locations:**
- `lib/screens/group_details_screen.dart:46-48`
- `lib/screens/home_screen.dart:153-154`

**Issue:** Manual invalidation of 3 caches repeated across screens.

**Fix:** Created `CacheInvalidationHelper` utility in `lib/helpers/cache_invalidation_helper.dart`.

### 3. State Management - Multiple Loading States

**Status:** 📋 Backlog

**Location:** `lib/screens/event_details_screen.dart:27-30`

**Issue:** 4+ independent boolean loading states per screen (`_isRegistering`, `_isWithdrawing`, `_isCancelling`, `_isUpdatingCapacity`).

**Recommendation:** Consider creating a `LoadingState` enum or adopting a state management solution.

```dart
enum LoadingState { idle, loading, success, error }
```

### 4. Large Widget Trees

**Status:** ✅ Fixed

**Location:** `lib/screens/home_screen.dart:234-640`

**Issue:** Modal forms are 100+ lines inline, making the file hard to maintain.

**Fix:** Extracted to separate files:
- `lib/widgets/create_group_modal.dart`
- `lib/widgets/join_group_modal.dart`

---

## Medium Priority Improvements

### 1. Inconsistent Error Handling Patterns

**Status:** 📋 Backlog

**Issue:** Mix of `catch (e)` and `catch (e, st)` patterns across the codebase.

**Locations:**
- `lib/services/auth_service.dart:138-143`
- `lib/services/group_service.dart:112-120`

**Recommendation:** Standardize on `catch (e, st)` pattern with proper stack trace logging via CrashlyticsService.

### 2. Inconsistent Mounted Checks

**Status:** 📋 Backlog

**Issue:** 61 occurrences of `mounted` checks with varying patterns (`if (mounted)` vs `if (!mounted) return`).

**Recommendation:** Standardize on early return pattern:
```dart
// Preferred pattern
if (!mounted) return;
// ... proceed with context operations
```

### 3. Missing Composite Index Awareness

**Status:** 📋 Backlog

**Location:** `lib/services/group_service.dart:144-150`

**Issue:** Orders by `eventTimestamp` with multiple `where` clauses - requires composite index.

### 4. Firebase Functions - Inconsistent Error Handling

**Status:** 📋 Backlog

**Locations:**
- `createGroup` (defined inline in `functions/src/index.ts`) vs `functions/src/manageJoinRequest.ts`

**Issue:** Different error wrapping patterns across functions.

**Recommendation:** Create validation utility and standardize error handling with wrapper function.

### 5. Type Safety - Unsafe Data Access

**Status:** 📋 Backlog

**Issue:** Excessive null coalescing and optional chaining without validation.

**Example from `lib/models/group_view_model.dart:39-41`:**
```dart
name: group.data()?['name'] ?? 'Unnamed Group',
```

**Recommendation:** Use strongly-typed model classes instead of `Map<String, dynamic>`.

---

## Low Priority Improvements

### 1. No Pagination in Lists

**Status:** 📋 Backlog

**Locations:**
- `lib/services/event_cache_service.dart`
- `lib/services/transaction_cache_service.dart`

**Issue:** No cursor-based pagination support.

### 2. No Request Debouncing

**Status:** 📋 Backlog

**Issue:** Rapid button clicks can trigger multiple Firebase calls, risking double-registration.

**Recommendation:** Add debouncing to critical action buttons.

### 3. Missing Retry Mechanisms

**Status:** ✅ Fixed

**Location:** `lib/screens/home_screen.dart:182`

**Issue:** Error states show message but no retry button.

**Fix:** Added retry button to error UI.

### 4. Magic Numbers

**Status:** 📋 Backlog

**Examples:**
- `lib/screens/home_screen.dart:38` - `Duration(milliseconds: 500)`
- `lib/screens/event_details_screen.dart:77` - hardcoded limit values

**Recommendation:** Extract to named constants.

### 5. No Offline Support

**Status:** 📋 Backlog

**Issue:** No service worker or local-first caching strategy for web.

### 6. Missing ListView Keys

**Status:** 📋 Backlog

**Location:** `lib/screens/home_screen.dart:221-227`

**Issue:** `ListView.builder` without keys can cause widget reuse issues.

**Recommendation:** Add keys using unique IDs:
```dart
itemBuilder: (context, index) {
  return GroupListItem(
    key: ValueKey(viewModels[index].groupId),
    viewModel: viewModels[index],
  );
},
```

---

## Code Smells

| File | Line(s) | Issue | Priority |
|------|---------|-------|----------|
| `auth_service.dart` | 327 | Async function without `await` (fire-and-forget) | Medium |
| `event_details_screen.dart` | 256-303 | 47-line method doing event navigation | High |
| `create_event_screen.dart` | 72-90 | Prefill duplicates last event query logic | Low |
| `group_service.dart` | 16-62 | Complex stream combination without clear contract | Medium |
| `notification_service.dart` | 56-73 | APNS token retry logic is hardcoded | Medium |
| `firestore.rules` | 64-67 | Complex nested exists() calls impact performance | Medium |

---

## What's Working Well

- Clear architectural patterns (Write-to-Trigger, Callable Functions)
- Good separation of concerns with service layer
- Cache services with TTL-based expiration
- Comprehensive Firestore security rules
- Well-documented codebase (CLAUDE.md, DATA_MODEL.md)
- Proper use of CrashlyticsService for error logging
- Consistent use of `developer.log` for debug logging

---

## Quick Wins Implemented

1. ✅ Added `.limit(100)` to unbounded queries
2. ✅ Created `CacheInvalidationHelper` utility
3. ✅ Added retry button to home screen error state
4. ✅ Extracted modal forms to separate widget files

## Patterns Worth Improving - Implemented

### 1. Standardized Error Handling

**Status:** ✅ Implemented

**Created:** `lib/helpers/error_handler.dart`

Provides centralized error handling with:
- Always captures stack traces with `catch (e, st)` pattern
- Logs to both developer console and Crashlytics
- Categorized error handlers for different scenarios:
  - `handle()` - General errors
  - `handleFunctionError()` - Cloud Function errors
  - `handleAuthError()` - Authentication errors
  - `handleFirestoreError()` - Firestore operation errors
  - `handleEventError()` - Event-related errors
  - `handleWalletError()` - Wallet/transaction errors
- `getUserMessage()` - Converts technical errors to user-friendly messages

**Usage:**
```dart
try {
  await someOperation();
} catch (e, st) {
  ErrorHandler().handle(e, st, context: 'MyScreen._loadData');
}
```

### 2. Request Debouncing

**Status:** ✅ Implemented

**Created:** `lib/helpers/debounce_helper.dart`

Provides multiple debouncing utilities:
- `ActionDebounceMixin` - Mixin for StatefulWidgets to prevent duplicate actions
- `Debouncer` - Standalone debouncer for services
- `DebouncedButton` - Pre-built button with loading state
- `DebouncedTextButton` - Pre-built text button with loading state

**Usage with Mixin:**
```dart
class _MyScreenState extends State<MyScreen> with ActionDebounceMixin {
  void _onRegisterTapped() {
    debounceAction('register', () async {
      await registerForEvent();
    });
  }
}
```

**Usage with DebouncedButton:**
```dart
DebouncedButton(
  onPressed: () async {
    await saveData();
  },
  child: Text('Save'),
)
```

### 3. Cursor-Based Pagination

**Status:** ✅ Implemented

**Updated:** `lib/services/transaction_cache_service.dart`

Added pagination support:
- `loadMore(groupId, userId)` - Loads next page of transactions
- `hasMore(groupId, userId)` - Checks if more data is available
- `lastDocument` stored in cache for cursor-based queries

**Usage:**
```dart
// Initial load
final transactions = await cache.getTransactions(groupId, userId);

// Load more when user scrolls to bottom
if (cache.hasMore(groupId, userId)) {
  final more = await cache.loadMore(groupId, userId);
  // Append to existing list
}
```

### 4. Firebase Functions Error Handling

**Status:** ✅ Implemented

**Created:** `functions/src/utils/errorHandler.ts`

Provides standardized error handling for Cloud Functions:
- `handleError()` - Normalizes errors and logs with context
- `createError()` - Creates HttpsError with logging
- `validateAuth()` - Validates authentication
- `validateArgs()` - Validates required arguments
- `validateDocExists()` - Validates document existence
- `validateGroupAdmin()` - Validates admin permissions
- `withErrorHandler()` - Higher-order function wrapper

**Usage:**
```typescript
import {handleError, validateAuth, validateArgs} from "./utils/errorHandler";

export const myFunction = onCall(async (request) => {
  try {
    validateAuth(request);
    validateArgs(request.data, ["groupId", "action"]);
    // ... function logic
  } catch (error) {
    throw handleError(error, "myFunction");
  }
});
```

---

## Recommended Next Steps

1. **Short-term (1-2 days):**
   - Standardize mounted check pattern across all screens
   - Add keys to ListView items

2. **Medium-term (1 week):**
   - Extract user document creation to utility method in auth_service
   - Create Firebase Functions validation utility
   - Standardize error handling patterns

3. **Long-term (2+ weeks):**
   - Implement cursor-based pagination
   - Add request debouncing to critical actions
   - Consider state management solution (Provider/Riverpod)
   - Transition App Check to enforcement mode
