# Documentation Cleanup Plan

This document tracks redundant or outdated documentation files that can be archived or removed.

**Last Updated:** 2025-10-13

---

## Files to Remove

### ✅ Consolidated into PRODUCT.md

These files have been consolidated into the comprehensive `PRODUCT.md`:

**Can be safely deleted:**
- [ ] `docs/REQUIREMENTS.md` → Moved to `PRODUCT.md` (sections: Vision, User Roles, Core Concepts, Implemented Features)
- [ ] `docs/IMPROVEMENT_BACKLOG.md` → Moved to `PRODUCT.md` (sections: Planned Features, Future Ideas, Technical Debt)

**Action:** Delete after verifying PRODUCT.md covers all content

---

### ✅ Consolidated into FIREBASE_FEATURES.md

New comprehensive Firebase documentation created:

**Can be kept** (specific implementation guides):
- `docs/FEATURE_FLAGS.md` - Detailed Remote Config setup
- `docs/FIREBASE_ANALYTICS.md` - Analytics implementation details
- `docs/FIREBASE_CRASHLYTICS.md` - Crashlytics setup details

**Note:** FIREBASE_FEATURES.md provides the overview and roadmap; specific feature docs provide implementation details.

---

### ⚠️ Task-Specific Documents (Completed Tasks)

These were created for specific implementation tasks that are now complete:

**Consider archiving (move to `docs/archive/`)**:
- [ ] `docs/TASK-Database-Optimization.md` - Completed optimization task
- [ ] `docs/TASK-Implement-Email-Password-Auth.md` - Not yet implemented (keep or move to PRODUCT.md backlog)
- [ ] `docs/TASK-Implement-Event-Cancellation.md` - Completed (event cancellation is live)
- [ ] `docs/TASK-Implement-Push-Notifications.md` - Completed (push notifications are live)

**Consider archiving:**
- [ ] `docs/SUMMARY-Database-Optimization.md` - Summary of completed work
- [ ] `docs/MIGRATION-PendingJoinRequestsCount.md` - Migration already run
- [ ] `docs/DEPLOYMENT-Checklist-Database-Optimization.md` - Specific to completed task

**Action:** Move to `docs/archive/` folder to preserve history without cluttering main docs

---

### ✅ Deployment Documentation (Keep)

Well-organized deployment docs:

**Keep as-is:**
- ✅ `DEPLOYMENT-GUIDE.md` (root) - Quick reference
- ✅ `docs/DEPLOYMENT.md` - Comprehensive guide
- ✅ `docs/IOS_RELEASE_QUICKSTART.md` - Quick iOS guide
- ✅ `docs/IOS_RELEASE_AUTOMATION.md` - Detailed iOS automation

**Rationale:** Clear hierarchy, no redundancy

---

### ⚠️ AI Context Files

Multiple files providing context to AI tools:

**Current files:**
- `CLAUDE.md` - For Claude Code (comprehensive)
- `COPILOT_CONTEXT.md` - For GitHub Copilot
- `GEMINI.md` - For Google Gemini

**Recommendation:**
- [ ] Keep `CLAUDE.md` as the primary AI context file (most comprehensive)
- [ ] Review `COPILOT_CONTEXT.md` and `GEMINI.md`:
  - If they duplicate CLAUDE.md: delete or add note pointing to CLAUDE.md
  - If they have tool-specific instructions: keep but sync with CLAUDE.md

**Action:** Audit and reduce duplication

---

### ✅ Core Documentation (Keep)

Well-structured core docs:

**Keep as-is:**
- ✅ `README.md` - Updated with new structure
- ✅ `CONTRIBUTING.md` - Contribution guidelines
- ✅ `docs/ARCHITECTURE.md` - System design
- ✅ `docs/DATA_MODEL.md` - Database structure
- ✅ `docs/USER_JOURNEYS.md` - User flows
- ✅ `docs/WIREFRAMES.md` - UI designs
- ✅ `docs/LOCAL_DEVELOPMENT.md` - Setup guide
- ✅ `docs/DATA_RETENTION.md` - Lifecycle policies
- ✅ `docs/ENVIRONMENTS.md` - Environment setup (planned)
- ✅ `docs/privacy.md` - Privacy policy
- ✅ `docs/IN_APP_UPDATES.md` - App update feature
- ✅ `docs/GOOGLE_PLAY_AD_ID.md` - Google Play compliance

---

## Proposed New Structure

### Root Directory
```
README.md              - Main entry point (✅ Updated)
CONTRIBUTING.md        - How to contribute
CLAUDE.md              - AI assistant context
LICENSE                - License file
```

### docs/ Directory

**Product & Planning:**
```
PRODUCT.md             - Requirements & roadmap (✅ New - consolidates REQUIREMENTS + IMPROVEMENT_BACKLOG)
USER_JOURNEYS.md       - User flows
WIREFRAMES.md          - UI mockups
```

**Technical:**
```
ARCHITECTURE.md        - System design
DATA_MODEL.md          - Database schema
FIREBASE_FEATURES.md   - Firebase roadmap (✅ New)
LOCAL_DEVELOPMENT.md   - Dev setup
ENVIRONMENTS.md        - Dev/prod setup
```

**Deployment:**
```
DEPLOYMENT.md          - Main deployment guide
IOS_RELEASE_QUICKSTART.md
IOS_RELEASE_AUTOMATION.md
DATA_RETENTION.md      - Data lifecycle
```

**Features:**
```
FEATURE_FLAGS.md       - Remote Config
FIREBASE_ANALYTICS.md  - Analytics setup
FIREBASE_CRASHLYTICS.md - Crashlytics setup
IN_APP_UPDATES.md      - Update prompts
GOOGLE_PLAY_AD_ID.md   - Ad ID compliance
```

**Legal:**
```
privacy.md             - Privacy policy
```

**Archive (new folder):**
```
archive/
  ├── TASK-Database-Optimization.md
  ├── SUMMARY-Database-Optimization.md
  ├── MIGRATION-PendingJoinRequestsCount.md
  ├── DEPLOYMENT-Checklist-Database-Optimization.md
  ├── TASK-Implement-Event-Cancellation.md
  ├── TASK-Implement-Push-Notifications.md
  └── README.md (explains these are historical documents)
```

---

## Action Plan

### Phase 1: Safe Deletions (Do First)
1. [ ] Verify PRODUCT.md contains all content from REQUIREMENTS.md and IMPROVEMENT_BACKLOG.md
2. [ ] Delete `docs/REQUIREMENTS.md`
3. [ ] Delete `docs/IMPROVEMENT_BACKLOG.md`
4. [ ] Update any cross-references to point to PRODUCT.md

### Phase 2: Archive Completed Tasks
1. [ ] Create `docs/archive/` directory
2. [ ] Create `docs/archive/README.md` explaining purpose
3. [ ] Move completed task documents to archive:
   - TASK-Database-Optimization.md
   - SUMMARY-Database-Optimization.md
   - MIGRATION-PendingJoinRequestsCount.md
   - DEPLOYMENT-Checklist-Database-Optimization.md
   - TASK-Implement-Event-Cancellation.md
   - TASK-Implement-Push-Notifications.md
4. [ ] Update any references (if any exist)

### Phase 3: AI Context Cleanup
1. [x] Review `COPILOT_CONTEXT.md`
   - [x] Deleted (file was essentially empty with only 1 line)
2. [x] Review `GEMINI.md`
   - [x] Consolidated to reduce duplication, added pointers to comprehensive docs

### Phase 4: Final Verification
1. [ ] Check all links in README.md work
2. [ ] Check all cross-references in docs work
3. [ ] Run a doc link checker (if available)
4. [ ] Update this document with completion status

---

## Decision Log

### Why Keep Separate Feature Docs?

Even though we have FIREBASE_FEATURES.md, we're keeping individual feature docs like:
- FEATURE_FLAGS.md
- FIREBASE_ANALYTICS.md
- FIREBASE_CRASHLYTICS.md

**Rationale:**
- **Overview vs Detail:** FIREBASE_FEATURES.md = high-level roadmap; individual docs = step-by-step implementation
- **Easy to find:** Developers searching for "feature flags setup" will find FEATURE_FLAGS.md quickly
- **Reference while coding:** Detailed setup steps belong in dedicated docs, not mixed with roadmap planning

### Why Archive vs Delete Task Docs?

We're archiving completed task documents instead of deleting them.

**Rationale:**
- **Historical context:** Future developers may want to understand past decisions
- **Implementation examples:** Can serve as templates for future similar tasks
- **Git history:** While git history preserves deleted files, archived files are easier to discover
- **Zero cost:** Archived docs don't clutter main docs but remain accessible

---

## Estimated Impact

**Before cleanup:**
- 25+ markdown files in docs/
- 3 AI context files in root
- Duplication between REQUIREMENTS.md and IMPROVEMENT_BACKLOG.md

**After cleanup:**
- ~17 active docs (clearly categorized)
- 6-7 archived docs (preserved for history)
- 1-2 AI context files (reduced duplication)
- Single source of truth for product requirements (PRODUCT.md)
- Single source of truth for Firebase roadmap (FIREBASE_FEATURES.md)

**Benefits:**
- ✅ Easier to find relevant documentation
- ✅ Less duplication and conflicting information
- ✅ Clear distinction between active and historical docs
- ✅ Better organized by category
- ✅ Single source of truth for requirements and backlog

---

## Maintenance Going Forward

### When to Create a New Doc

**Create separate doc when:**
- Topic is substantial (>500 lines)
- Multiple developers will reference it frequently
- It's a step-by-step guide or tutorial
- It needs to be linked from multiple places

**Add to existing doc when:**
- Topic is short (<200 lines)
- It's closely related to existing content
- It's a one-time task or decision log
- It's supplementary information

### Regular Reviews

**Monthly:**
- [ ] Check for new task-specific docs to archive
- [ ] Update PRODUCT.md with completed features
- [ ] Update FIREBASE_FEATURES.md with new Firebase features

**Quarterly:**
- [ ] Review all docs for accuracy
- [ ] Check for outdated information
- [ ] Consolidate if duplication appears
- [ ] Update this cleanup plan

---

## Quick Reference: Documentation Map

```
📁 getspot/
├── 📄 README.md ..................... Start here
├── 📄 CLAUDE.md ..................... AI context
├── 📄 CONTRIBUTING.md ............... How to contribute
│
└── 📁 docs/
    ├── 📋 Product
    │   ├── PRODUCT.md ............... Requirements & roadmap ⭐
    │   ├── USER_JOURNEYS.md ......... User flows
    │   └── WIREFRAMES.md ............ UI mockups
    │
    ├── 🔧 Technical
    │   ├── ARCHITECTURE.md .......... System design
    │   ├── DATA_MODEL.md ............ Database schema
    │   ├── FIREBASE_FEATURES.md ..... Firebase roadmap ⭐
    │   ├── LOCAL_DEVELOPMENT.md ..... Dev setup
    │   └── ENVIRONMENTS.md .......... Dev/prod config
    │
    ├── 🚀 Deployment
    │   ├── DEPLOYMENT.md ............ Main guide
    │   ├── IOS_RELEASE_QUICKSTART.md
    │   ├── IOS_RELEASE_AUTOMATION.md
    │   └── DATA_RETENTION.md ........ Lifecycle
    │
    ├── ✨ Features
    │   ├── FEATURE_FLAGS.md ......... Remote Config
    │   ├── FIREBASE_ANALYTICS.md .... Analytics
    │   ├── FIREBASE_CRASHLYTICS.md .. Crashlytics
    │   ├── IN_APP_UPDATES.md ........ Updates
    │   └── GOOGLE_PLAY_AD_ID.md ..... Ad ID
    │
    ├── 📜 Legal
    │   └── privacy.md ............... Privacy policy
    │
    └── 📦 archive/
        ├── README.md ................ Archive explanation
        └── [Historical task docs]

⭐ = New consolidated documents
```

---

## Completion Checklist

- [x] Create FIREBASE_FEATURES.md
- [x] Create PRODUCT.md
- [x] Update README.md
- [x] Delete REQUIREMENTS.md (verified - not found)
- [x] Delete IMPROVEMENT_BACKLOG.md (verified - not found)
- [x] Create archive/ folder
- [x] Move completed task docs to archive
- [x] Review AI context files (COPILOT_CONTEXT.md deleted, GEMINI.md consolidated)
- [x] Archive DEPLOYMENT-GUIDE.md (outdated migration info)
- [x] Update CLAUDE.md with all services and screens
- [ ] Update cross-references (if needed)
- [ ] Final verification of all links

---

**Status:** Nearly complete
**Last Updated:** 2025-10-24
**Recent Updates:**
- Deleted COPILOT_CONTEXT.md (essentially empty)
- Consolidated GEMINI.md to reduce redundancy with CLAUDE.md
- Updated CLAUDE.md Code Structure section with all 8 services and 11 screens
- Fixed processWaitlist documentation (marked as utility function)
- Archived DEPLOYMENT-GUIDE.md to docs/archive/
