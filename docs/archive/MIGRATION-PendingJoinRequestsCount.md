# Migration Guide: Initialize pendingJoinRequestsCount

This guide will help you initialize the `pendingJoinRequestsCount` field for all existing groups in your Firestore database.

## Background

As part of the database optimization work, we've added a `pendingJoinRequestsCount` field to group documents. This field is automatically maintained by Cloud Functions for new groups and join request changes, but existing groups need to be initialized with the correct count.

## Prerequisites

- Firebase CLI installed (`npm install -g firebase-tools`)
- Logged in to Firebase (`firebase login`)
- Functions deployed to Firebase

## Step 1: Deploy Updated Cloud Functions

First, deploy all the new Cloud Functions including the migration script:

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

This will deploy:
- `createGroup` (updated to initialize `pendingJoinRequestsCount: 0`)
- `onJoinRequestCreated` (maintains count on new requests)
- `onJoinRequestUpdated` (maintains count on status changes)
- `onJoinRequestDeleted` (maintains count on deletions)
- `initializePendingJoinRequestsCount` (migration function)

**Wait for deployment to complete** before proceeding.

## Step 2: Run the Migration

You have three options to run the migration:

### Option A: Using Firebase Console (Recommended)

1. Go to the Firebase Console: https://console.firebase.google.com
2. Select your project: `getspot01`
3. Navigate to **Functions** in the left sidebar
4. Find the function `initializePendingJoinRequestsCount`
5. Click on the function name to open its details
6. Go to the **Logs** tab (we'll check logs here after running)
7. Go back and click the **Testing** tab or use the Functions dashboard
8. Click **Run** or use the Cloud Functions testing interface
9. Wait for the function to complete
10. Check the **Logs** tab for the migration summary

### Option B: Using Firebase CLI

```bash
# Call the function using Firebase CLI
firebase functions:call initializePendingJoinRequestsCount --region us-east4
```

### Option C: Using curl (if you need more control)

First, get the function URL from the Firebase Console or from the deployment output.

```bash
# Replace with your actual function URL
curl -X POST https://us-east4-getspot01.cloudfunctions.net/initializePendingJoinRequestsCount \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -d '{}'
```

## Step 3: Verify the Migration

### Check the Response

The migration function will return a JSON response like this:

```json
{
  "status": "completed",
  "message": "Migration completed. 15 groups updated successfully, 0 errors.",
  "summary": {
    "total": 15,
    "success": 15,
    "errors": 0,
    "errorDetails": []
  }
}
```

### Check Firestore Console

1. Go to Firebase Console → Firestore Database
2. Open the `groups` collection
3. Select a few group documents
4. Verify that each has a `pendingJoinRequestsCount` field with the correct value

### Check Function Logs

1. Firebase Console → Functions
2. Click on `initializePendingJoinRequestsCount`
3. Go to **Logs** tab
4. Look for entries like:
   ```
   Updated group abc123 with pendingJoinRequestsCount: 3
   Migration completed { total: 15, success: 15, errors: 0 }
   ```

## Step 4: Cleanup (After Successful Migration)

Once you've verified the migration was successful, you should remove the migration function to avoid accidental re-runs:

1. Open `functions/src/index.ts`
2. Comment out or remove these lines:

```typescript
// Migration function - call once, then comment out or remove
export const initializePendingJoinRequestsCount = onCall(
  initializePendingJoinRequestsCountHandler(db)
);
```

3. Also remove the import:

```typescript
import {initializePendingJoinRequestsCount as initializePendingJoinRequestsCountHandler} from "./migrations/initializePendingJoinRequestsCount";
```

4. Redeploy functions:

```bash
cd functions
npm run build
firebase deploy --only functions
```

## Troubleshooting

### Error: "Function not found"

- Ensure functions were deployed successfully: `firebase deploy --only functions`
- Check the function exists in Firebase Console → Functions
- Verify you're using the correct region (us-east4)

### Error: "Permission denied"

- Ensure you're logged in: `firebase login`
- Verify you have appropriate permissions on the project
- For curl approach, ensure your auth token is valid

### Some groups show errors

- Check the `errorDetails` in the response
- Common issues:
  - Missing permissions (should not happen with Cloud Functions)
  - Corrupt data in join requests
- You can re-run the migration function - it skips groups that already have the field

### Migration seems stuck

- Check Firebase Console → Functions → Logs for progress
- The function has a default timeout of 60 seconds
- For large databases (100+ groups), you may need to increase the timeout or batch the migration

## Expected Behavior After Migration

Once the migration is complete:

1. All existing groups will have `pendingJoinRequestsCount` field
2. New groups automatically get `pendingJoinRequestsCount: 0`
3. When users request to join a group, the count increments automatically
4. When admins approve/deny/delete requests, the count updates automatically
5. The home screen for admins loads ~10 fewer queries per group

## Rollback

If you need to rollback:

1. Revert the Flutter code changes in `lib/services/group_service.dart`
2. Restore the `getPendingJoinRequestsCount()` method
3. Redeploy the app

The `pendingJoinRequestsCount` field in Firestore can remain - it won't cause issues.

## Support

If you encounter issues during migration:
1. Check Firebase Console → Functions → Logs for detailed error messages
2. Review the migration script: `functions/src/migrations/initializePendingJoinRequestsCount.ts`
3. You can safely run the migration multiple times - it skips already-migrated groups
