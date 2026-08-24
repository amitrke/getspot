# GetSpot: Gemini Context Pack

GetSpot is a Flutter + Firebase app for small sports groups (e.g. badminton) to manage membership, events, registration, and a virtual wallet/penalty system.

For architecture, data model, Cloud Functions, security rules, and project status, **`CLAUDE.md` is the canonical, actively-maintained reference** — read that first. This file exists only to add the Gemini-specific prompting guide below; duplicating the rest here would just create a second copy to keep in sync.

### Gemini Prompting Guide
**Minimal Prompt Template:**
```
Context: GetSpot (Flutter/Firebase). Pain point: <describe>. Task: <describe>. Constraints: <constraints>. Output: <format>.
```

**Examples:**
- Refactor: `Task: Refactor Dart home screen to use userGroupMemberships index with batch fetching`
- Security: `Task: Propose Firestore rule for userGroupMemberships allowing read only where request.auth.uid == uid`
- Feature: `Task: Add event capacity update with waitlist promotion logic`

---

**For comprehensive documentation, refer to:**
- `CLAUDE.md` - Complete AI assistant context
- `docs/ARCHITECTURE.md` - System design patterns
- `docs/DATA_MODEL.md` - Complete database schema
- `docs/PRODUCT.md` - Requirements and roadmap
- `CONTRIBUTING.md` - Development guidelines