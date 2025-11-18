# Quick Deployment Guide: Database Optimizations

## TL;DR

```bash
# 1. Deploy Functions
cd functions
npm run build
firebase deploy --only functions

# 2. Run Migration (choose one method):

## Option A: Firebase Console (Recommended)
# Go to console.firebase.google.com → Functions → initializePendingJoinRequestsCount → Run

## Option B: Firebase CLI
firebase functions:call initializePendingJoinRequestsCount --region us-east4

# 3. Verify (check logs and Firestore)
# Firebase Console → Functions → Logs
# Firebase Console → Firestore → groups (check for pendingJoinRequestsCount field)

# 4. Deploy Flutter (if ready)
flutter build web
firebase deploy --only hosting

# 5. Cleanup migration function (after success)
# Edit functions/src/index.ts - comment out initializePendingJoinRequestsCount
npm run build
firebase deploy --only functions
```

## What You're Deploying

- **3 Firestore Triggers:** Auto-maintain `pendingJoinRequestsCount`
- **1 Migration Function:** Initialize counts for existing groups (run once)
- **Flutter Changes:** Cache services, ParticipantProvider, optimized queries

## Expected Results

- ✅ 30-50% reduction in Firestore reads
- ✅ 90% reduction in real-time listeners
- ✅ Faster screen loads
- ✅ Lower costs

## Detailed Guides

- **Full Deployment:** `docs/DEPLOYMENT-Checklist-Database-Optimization.md`
- **Migration Details:** `docs/MIGRATION-PendingJoinRequestsCount.md`
- **Summary:** `docs/SUMMARY-Database-Optimization.md`

## Need Help?

Check Firebase Console → Functions → Logs for any errors during deployment or migration.
