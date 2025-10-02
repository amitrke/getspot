# GetSpot - Event Organization App

[![GetSpot Website](https://img.shields.io/badge/Website-getspot.org-blue?style=for-the-badge)](https://www.getspot.org)
[![Google Play Store](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=org.getspot)
[![Download on the App Store](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/us/app/sports-getspot/id6752911639)

Welcome to the GetSpot project! This application is designed to streamline the organization of local meetups, starting with badminton games. It helps organizers create events, manage participants, and handle registrations, while providing a simple and clear experience for players.

## Features

- **Group Management:** Create and manage private groups for your sports activities.
- **Event Creation:** Easily create and schedule events for your group.
- **Member Registration:** Members can register for events with a single tap.
- **Virtual Wallet:** Each group has a virtual wallet to handle event fees and penalties.
- **Waitlist Management:** Automatic waitlist handling for full events.
- **Push Notifications:** Get notified for new events, cancellations, and waitlist promotions.

## Technologies Used

- **Frontend:** Flutter (for Mobile and Web)
- **Backend:** Firebase (Authentication, Firestore, Cloud Functions, Hosting)
- **Infrastructure Automation:** GitHub Actions for CI/CD

## Getting Started

For instructions on how to set up and run the project locally, please see the **[Local Development Guide](./docs/LOCAL_DEVELOPMENT.md)**.

## Project Status & Next Steps

The core features for group creation, event management, registration, waitlists, and withdrawals (including refunds/penalties) are **fully implemented and functional**. The home screen uses an efficient, denormalized query for fast performance.

### Potential Future Enhancements
- **Admin Dashboard:** A dedicated UI for admins to view group statistics and manage settings.
- **Improved Testing:** Expand the test harness with more comprehensive widget and integration tests.

## Project Documentation

This project is well-documented to ensure a clear understanding of its goals, architecture, and data structure. Please review the following documents for a complete overview:

*   **[REQUIREMENTS.md](./docs/REQUIREMENTS.md):** Detailed functional and non-functional requirements.
*   **[ARCHITECTURE.md](./docs/ARCHITECTURE.md):** A high-level overview of the system architecture.
*   **[DATA_MODEL.md](./docs/DATA_MODEL.md):** The data model for the Firestore database.
*   **[USER_JOURNEYS.md](./docs/USER_JOURNEYS.md):** Describes the paths users take to complete core tasks.

## Contributing

Contributions are welcome! Please see the **[Contributing Guide](./CONTRIBUTING.md)** for more information.

## License

This project is licensed under the terms of the **[LICENSE](./LICENSE)** file.