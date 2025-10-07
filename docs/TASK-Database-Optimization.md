# Database Optimization Task

## Overview

This task tracks the implementation of database optimizations to reduce Firestore reads, improve performance, and lower costs.

**Expected Impact:**
- 30-50% reduction in Firestore read costs
- Faster screen loads
- Reduced bandwidth usage
- Better scalability

---

## Phase 1: Quick Wins (35 minutes) ✅ COMPLETED

### ✅ Task 1.1: Add limit to announcements query
**File:** `lib/screens/group_details_screen.dart` (line ~307)
**Effort:** 5 minutes
**Priority:** High

**Current Code:**
```dart
stream: FirebaseFirestore.instance
    .collection('groups')
    .doc(widget.groupId)
    .collection('announcements')
    .orderBy('createdAt', descending: true)
    .snapshots(),
```

**Updated Code:**
```dart
stream: FirebaseFirestore.instance
    .collection('groups')
    .doc(widget.groupId)
    .collection('announcements')
    .orderBy('createdAt', descending: true)
    .limit(50)  // Add this line
    .snapshots(),
```

**Impact:** Prevents unbounded growth of announcement reads

---

### ✅ Task 1.2: Add limit to transactions query
**File:** `lib/screens/wallet_screen.dart` (line ~20)
**Effort:** 5 minutes
**Priority:** High

**Current Code:**
```dart
final transactionsStream = FirebaseFirestore.instance
    .collection('transactions')
    .where('groupId', isEqualTo: groupId)
    .where('uid', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .snapshots();
```

**Updated Code:**
```dart
final transactionsStream = FirebaseFirestore.instance
    .collection('transactions')
    .where('groupId', isEqualTo: groupId)
    .where('uid', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .limit(100)  // Add this line
    .snapshots();
```

**Impact:** Limits transaction history to most recent 100 entries

---

### ✅ Task 1.3: Convert WalletScreen to one-time reads with manual refresh
**File:** `lib/screens/wallet_screen.dart`
**Effort:** 15 minutes
**Priority:** Medium

**Change:** Convert from real-time listeners to one-time reads with a refresh button

**Rationale:** Users don't typically stay on wallet screen for long periods. One-time reads with manual refresh are more efficient.

**Implementation Steps:**
1. Convert StatelessWidget to StatefulWidget
2. Replace `.snapshots()` with `.get()` for both balance and transactions
3. Add refresh button to AppBar
4. Wrap UI with FutureBuilder instead of StreamBuilder

**See full implementation in analysis report**

**Impact:** Eliminates continuous listeners for wallet data

---

### ✅ Task 1.4: Pass isGroupAdmin to EventDetailsScreen
**File:** `lib/screens/event_details_screen.dart`
**Effort:** 10 minutes
**Priority:** Medium

**Changes:**
1. Add `isGroupAdmin` parameter to EventDetailsScreen constructor
2. Pass it from GroupDetailsScreen when navigating
3. Remove `_fetchGroupAdminStatus()` method and its usage
4. Use the passed parameter directly

**Files to modify:**
- `lib/screens/event_details_screen.dart`
- `lib/screens/group_details_screen.dart` (where navigation occurs)

**Impact:** Eliminates 1-2 reads per event details screen visit

---

## Phase 2: High Impact Optimizations (3-4 hours) ✅ COMPLETED

### ✅ Task 2.1: Fix N+1 query pattern in MemberProfileScreen
**File:** `lib/screens/member_profile_screen.dart` (lines 138-187)
**Effort:** 45 minutes
**Priority:** Critical

**Problem:** Nested FutureBuilders in ListView create N+1 queries. For 10 groups = 20 queries!

**Solution:** Batch all queries upfront before building the ListView

**Implementation Steps:**
1. Create `_fetchGroupBalances()` method to batch queries
2. Use `whereIn` to fetch all groups in one query
3. Use `Future.wait()` to fetch all member documents
4. Build map of results
5. Use single FutureBuilder at top level, not in ListView

**See full implementation in analysis report**

**Impact:** For 10 groups: 20 reads → 11 reads (45% reduction)

---

### ✅ Task 2.2: Implement UserCacheService
**File:** `lib/services/user_cache_service.dart` (NEW)
**Effort:** 1-2 hours
**Priority:** High

**Purpose:** Cache user profile data (display names, photos) with 15-minute TTL

**Implementation Steps:**
1. Create `UserCacheService` singleton class
2. Implement in-memory cache with TTL
3. Add `getUser()`, `invalidate()`, and `clear()` methods
4. Create `CachedUser` data class
5. Update screens to use cache instead of direct Firestore queries

**Usage locations:**
- Event details screen (participant lists)
- Group member lists
- Any place displaying user profiles

**Impact:** 100-500+ reads saved per day

---

### ✅ Task 2.3: Implement GroupCacheService
**File:** `lib/services/group_cache_service.dart` (NEW)
**Effort:** 1 hour
**Priority:** High

**Purpose:** Cache group metadata (name, description, code, admin) with 30-minute TTL

**Implementation Steps:**
1. Create `GroupCacheService` singleton class
2. Implement in-memory cache with TTL
3. Add `getGroup()` and `invalidate()` methods
4. Create `CachedGroup` data class
5. Update screens to use cache

**Usage locations:**
- Member profile screen
- Navigation breadcrumbs
- Any place displaying group names

**Impact:** 50-100+ reads saved per day

---

## Cache Integration (Completed)

### ✅ Integrated cache services into application
**Files Modified:**
- `lib/screens/member_profile_screen.dart` - Now uses GroupCacheService for batched group fetching
- `lib/services/group_cache_service.dart` - Added documentation for when to invalidate
- `CLAUDE.md` - Added caching documentation

**Cache Invalidation Points:**
- ✅ User display name updates: `UserCacheService().invalidate(userId)` called in MemberProfileScreen
- ✅ Group metadata updates: Documentation added for future group edit features

**Current Usage:**
- `MemberProfileScreen`: Uses `GroupCacheService.getGroups()` for efficient batch fetching with cache
- User cache invalidation implemented in display name update flow
- Cache services ready for use across the app

---

## Phase 3: Advanced Optimizations (6-9 hours) ✅ COMPLETED

### ✅ Task 3.1: Implement shared ParticipantProvider
**File:** `lib/providers/participant_provider.dart` (NEW)
**Effort:** 2-3 hours
**Priority:** High

**Problem:** Each event in a list creates its own real-time listener (10 events = 10 listeners)

**Solution:** Use a centralized provider that shares participant data across all event items

**Implementation Steps:**
1. Create `ParticipantProvider` with ChangeNotifier
2. Implement subscription management for multiple events
3. Store participant data in a map keyed by eventId
4. Update `group_details_screen.dart` event list to use provider
5. Add proper cleanup in dispose()

**Impact:** For 10 events: 10 listeners → 1 shared approach (90% reduction)

---

### ✅ Task 3.2: Add pendingJoinRequestsCount field to groups
**Files:**
- Cloud Functions: `functions/src/manageJoinRequest.ts`
- Flutter: `lib/services/group_service.dart`
**Effort:** 2-3 hours
**Priority:** Medium

**Purpose:** Eliminate separate query for pending join requests count

**Implementation Steps:**
1. Add `pendingJoinRequestsCount` field to group document schema
2. Update `manageJoinRequest` Cloud Function to maintain counter
3. Initialize field for existing groups (migration script)
4. Update GroupService to read from group document instead of querying
5. Update DATA_MODEL.md documentation

**Impact:** Eliminates ~10 queries per home screen load for admins

**Migration Required:**
- See `docs/MIGRATION-PendingJoinRequestsCount.md` for detailed instructions
- Run `initializePendingJoinRequestsCount` function once after deployment
- Remove migration function after successful completion

---

### ⬜ Task 3.3: Implement centralized GroupMembershipProvider
**File:** `lib/providers/group_membership_provider.dart` (NEW)
**Effort:** 2-3 hours
**Priority:** Medium

**Purpose:** Share group membership data across multiple screens

**Implementation Steps:**
1. Create provider at app level
2. Implement real-time listener for user's group memberships
3. Expose membership data to all screens
4. Update home screen and other locations to use provider
5. Eliminate duplicate queries

**Impact:** Reduces redundant membership queries across navigation

---

## Phase 4: Additional Improvements (Optional)

### ⬜ Task 4.1: Enable Firestore offline persistence
**File:** `lib/main.dart`
**Effort:** 5 minutes
**Priority:** Low

**Code:**
```dart
await FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

**Impact:** Improves offline experience and reduces reads from cache

---

### ⬜ Task 4.2: Implement pagination for long lists
**Files:**
- `lib/screens/wallet_screen.dart` (transactions)
- `lib/screens/group_details_screen.dart` (announcements)
**Effort:** 2-3 hours per screen
**Priority:** Low

**Purpose:** Add "Load More" functionality for better UX and performance

---

### ⬜ Task 4.3: Add monitoring and alerts
**Effort:** 1 hour
**Priority:** Low

**Tasks:**
1. Set up Firebase Console monitoring for query performance
2. Create alerts for expensive queries
3. Monitor missing indexes
4. Track read/write costs over time

---

## Testing Checklist

After each phase, verify:
- [ ] All screens load correctly
- [ ] No console errors
- [ ] Data displays accurately
- [ ] Real-time updates still work where expected
- [ ] Manual refresh buttons work (Phase 1)
- [ ] Cache invalidation works correctly (Phase 2)
- [ ] No memory leaks from listeners (Phase 3)

---

## Metrics to Track

**Before optimization:**
- Document reads per day: _____
- Active listeners: _____
- Average screen load time: _____

**After Phase 1:**
- Document reads per day: _____
- Active listeners: _____
- Average screen load time: _____

**After Phase 2:**
- Document reads per day: _____
- Active listeners: _____
- Average screen load time: _____

**After Phase 3:**
- Document reads per day: _____
- Active listeners: _____
- Average screen load time: _____

---

## Notes

- Mark tasks complete (✅) as you finish them
- Update this document with any deviations or additional findings
- Document any issues encountered in the relevant task section
- Keep track of actual time spent vs estimated
