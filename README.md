# GetSpot - Event Organization App

[![GetSpot Website](https://img.shields.io/badge/Website-getspot.org-blue?style=for-the-badge)](https://www.getspot.org)
[![Google Play Store](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=org.getspot)
[![Download on the App Store](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/us/app/sports-getspot/id6752911639)

GetSpot streamlines the organization of local sports meetups, starting with badminton games. Organizers can create events, manage participants, and handle registrations, while providing a simple and clear experience for players.

---

## Features

- **Group Management:** Create and manage private groups for your sports activities
- **Event Creation:** Easily schedule events with capacity management and waitlists
- **Virtual Wallet:** Handle event fees and penalties with a virtual currency system
- **Smart Waitlist:** Automatic promotion when spots open up
- **Push Notifications:** Stay updated on events, cancellations, and registrations
- **Real-time Updates:** Live participant counts and status changes
- **Cross-platform:** Works on iOS, Android, and Web

---

## Technologies

- **Frontend:** Flutter (Mobile & Web)
- **Backend:** Firebase
  - Authentication (Google, Apple Sign-In)
  - Cloud Firestore (NoSQL database)
  - Cloud Functions (Serverless backend)
  - Cloud Messaging (Push notifications)
  - Hosting (Web deployment)
  - Analytics & Crashlytics
  - Remote Config (Feature flags)

---

## Documentation

### Getting Started
- **[Local Development Guide](./docs/LOCAL_DEVELOPMENT.md)** - Set up your development environment
- **[CLAUDE.md](./CLAUDE.md)** - Quick reference for AI-assisted development

### Product & Planning
- **[PRODUCT.md](./docs/PRODUCT.md)** - Requirements, roadmap, and feature backlog
- **[USER_JOURNEYS.md](./docs/USER_JOURNEYS.md)** - User flows and scenarios
- **[WIREFRAMES.md](./docs/WIREFRAMES.md)** - UI mockups and design

### Technical Documentation
- **[ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - System architecture and design patterns
- **[DATA_MODEL.md](./docs/DATA_MODEL.md)** - Firestore data structure
- **[FIREBASE_FEATURES.md](./docs/FIREBASE_FEATURES.md)** - Firebase services used and recommended

### Deployment & Operations
- **[DEPLOYMENT.md](./docs/DEPLOYMENT.md)** - Deploy to Web, Android, and iOS
- **[IOS_RELEASE_QUICKSTART.md](./docs/IOS_RELEASE_QUICKSTART.md)** - Quick iOS release guide
- **[IOS_RELEASE_AUTOMATION.md](./docs/IOS_RELEASE_AUTOMATION.md)** - Detailed iOS automation
- **[DATA_RETENTION.md](./docs/DATA_RETENTION.md)** - Data lifecycle policies

### Feature-Specific Guides
- **[FEATURE_FLAGS.md](./docs/FEATURE_FLAGS.md)** - Remote Config setup
- **[FIREBASE_ANALYTICS.md](./docs/FIREBASE_ANALYTICS.md)** - Analytics implementation
- **[FIREBASE_CRASHLYTICS.md](./docs/FIREBASE_CRASHLYTICS.md)** - Crash reporting setup
- **[IN_APP_UPDATES.md](./docs/IN_APP_UPDATES.md)** - App update prompts

### Other
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Contribution guidelines
- **[ENVIRONMENTS.md](./docs/ENVIRONMENTS.md)** - Dev/prod environment setup (planned)
- **[privacy.md](./docs/privacy.md)** - Privacy policy

---

## Quick Start

### Prerequisites
- Flutter SDK (3.8.1+)
- Firebase CLI
- Node.js 22+ (for Cloud Functions)

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/getspot.git
cd getspot

# Install Flutter dependencies
flutter pub get

# Install Cloud Functions dependencies
cd functions
npm install
cd ..

# Run on connected device
flutter run

# Or run on Chrome
flutter run -d chrome
```

See [LOCAL_DEVELOPMENT.md](./docs/LOCAL_DEVELOPMENT.md) for detailed setup instructions.

---

## Project Status

### Production Features ✅
- Group creation and management
- Event scheduling with capacity limits
- Event registration with waitlist support
- Virtual wallet system
- Push notifications
- Google & Apple authentication
- Firebase Analytics & Crashlytics
- Feature flags (Remote Config)
- Data lifecycle management

### In Progress 🚧
- Separate dev/prod environments
- Terms of Service and Privacy Policy

### Coming Soon 🎯
See [PRODUCT.md](./docs/PRODUCT.md) for the complete roadmap.

**Top Priorities:**
1. Performance optimization (pagination, caching)
2. Error handling improvements
3. Admin dashboard and analytics
4. Enhanced search and filtering
5. Social features (ratings, badges, leaderboards)

---

## Firebase Configuration

- **Project ID:** `getspot01`
- **Region:** us-east4 (Northern Virginia)
- **Firestore:** Rules and indexes configured
- **Functions:** TypeScript with Node.js 22
- **Hosting:** www.getspot.org

---

## Architecture Highlights

### Design Patterns

**1. Write-to-Trigger Pattern** (Event Registration)
- Client writes "requested" status
- Cloud Function processes and updates status
- Real-time listener updates UI

**2. Callable Function Pattern** (Group Creation)
- Atomic operations with transactionality
- Returns result synchronously
- Server-side validation

**3. Denormalized Data** (User Memberships)
- Fast lookups without expensive collection group queries
- `/userGroupMemberships/{userId}/groups/{groupId}`
- Maintained by Cloud Functions

See [ARCHITECTURE.md](./docs/ARCHITECTURE.md) for details.

---

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

**Development Principles:**
- Prefer Cloud Function triggers for invariants
- Use batched writes/transactions for multi-document consistency
- Add composite indexes proactively
- Include rationale comments for maintainability

---

## Support

- **Documentation:** See `/docs` folder
- **Issues:** GitHub Issues
- **Website:** [www.getspot.org](https://www.getspot.org)

---

## License

This project is licensed under the terms specified in the [LICENSE](./LICENSE) file.

---

**Built with ❤️ using Flutter and Firebase**
