# Deployment Checklist: Database Optimization

This checklist guides you through deploying all the database optimization changes.

## Pre-Deployment Checklist

- [ ] All Phase 1, 2, and 3 optimizations have been tested locally
- [ ] Flutter app builds successfully: `flutter build web`
- [ ] Cloud Functions compile successfully: `cd functions && npm run build`
- [ ] Cloud Functions pass linting: `cd functions && npm run lint`
- [ ] No TypeScript errors in functions

## Deployment Steps

### Step 1: Deploy Cloud Functions

```bash
cd functions
npm install
npm run lint
npm run build
firebase deploy --only functions
```

**Expected output:**
- ✓ All existing functions updated
- ✓ New functions deployed:
  - `onJoinRequestCreated`
  - `onJoinRequestUpdated`
  - `onJoinRequestDeleted`
  - `initializePendingJoinRequestsCount`

**Time:** ~3-5 minutes

### Step 2: Run Migration

Follow the detailed guide in `MIGRATION-PendingJoinRequestsCount.md`

**Quick version:**
1. Go to Firebase Console → Functions
2. Find `initializePendingJoinRequestsCount`
3. Run the function (Testing tab or via CLI)
4. Wait for completion
5. Verify in logs and Firestore

**Time:** ~1-2 minutes (depending on number of groups)

### Step 3: Verify Migration

- [ ] Check migration response shows success
- [ ] Spot-check a few groups in Firestore Console
- [ ] Verify `pendingJoinRequestsCount` field exists
- [ ] Check Firebase Functions logs for errors

### Step 4: Deploy Flutter App

```bash
# For web
flutter build web
firebase deploy --only hosting

# For mobile (if applicable)
flutter build apk
flutter build ios
```

### Step 5: Cleanup Migration Function

After successful migration:

1. Edit `functions/src/index.ts`
2. Comment out or remove:
   ```typescript
   // Migration function - call once, then comment out or remove
   export const initializePendingJoinRequestsCount = onCall(
     initializePendingJoinRequestsCountHandler(db)
   );
   ```
3. Remove the import line
4. Redeploy: `cd functions && npm run build && firebase deploy --only functions`

## Post-Deployment Verification

### Test Phase 1 Changes

- [ ] Open WalletScreen - verify refresh button works
- [ ] Check announcements list - should be limited to 50
- [ ] Check transactions list - should be limited to 100
- [ ] Navigate to EventDetailsScreen - should load without extra queries

### Test Phase 2 Changes

- [ ] Open MemberProfileScreen
- [ ] Verify group balances load quickly
- [ ] Check Firebase Console for reduced read counts
- [ ] Update user display name - verify cache invalidation works

### Test Phase 3 Changes

- [ ] Navigate to GroupDetailsScreen with multiple events
- [ ] Check Firebase Console → Functions → Logs
- [ ] Verify only one ParticipantProvider instance created
- [ ] Verify participant status updates in real-time
- [ ] As admin, check pending request count appears instantly (no delay)

## Monitoring

### Check Firebase Console Metrics

1. **Firestore → Usage tab**
   - Monitor read/write counts before and after
   - Should see 30-50% reduction in reads

2. **Functions → Dashboard**
   - Check invocation counts
   - Monitor error rates
   - Verify new trigger functions are firing

3. **Functions → Logs**
   - Look for cache hit/miss logs from ParticipantProvider
   - Check for any errors in trigger functions

### Expected Improvements

- **Home Screen Load:** Faster, fewer queries for admins
- **Member Profile Screen:** 45% fewer reads (20 → 11 for 10 groups)
- **Event Lists:** 90% fewer listeners (N listeners → 1 provider)
- **Overall:** 30-50% reduction in Firestore read costs

## Rollback Plan

If issues arise:

### Rollback Functions Only
```bash
# Revert to previous deployment
firebase functions:delete onJoinRequestCreated --region us-east4
firebase functions:delete onJoinRequestUpdated --region us-east4
firebase functions:delete onJoinRequestDeleted --region us-east4
# Then redeploy previous version
```

### Rollback Flutter Changes
```bash
git revert <commit-hash>
flutter build web
firebase deploy --only hosting
```

### Quick Fix for pendingJoinRequestsCount
If the denormalized counter causes issues, the old query method still works as a fallback. Simply revert `lib/services/group_service.dart` to use the query approach.

## Post-Deployment Tasks

- [ ] Monitor Firebase Console for 24 hours
- [ ] Check error rates in Functions logs
- [ ] Verify read/write costs are lower
- [ ] Document any issues encountered
- [ ] Update team on successful deployment

## Notes

- The `pendingJoinRequestsCount` field in existing groups is safe even if migration hasn't run yet - the app will just show 0 until migration completes
- ParticipantProvider automatically cleans up listeners on navigation
- Cache services use in-memory storage and will be cleared on app restart
- All changes are backward compatible

## Support

If you encounter issues:
1. Check Firebase Console → Functions → Logs
2. Review `MIGRATION-PendingJoinRequestsCount.md`
3. Check `TASK-Database-Optimization.md` for implementation details
4. All optimization code is well-commented for troubleshooting
