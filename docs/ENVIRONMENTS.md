# Development and Production Environment Strategy

This document outlines the strategy for maintaining separate development (`dev`) and production (`prod`) environments for the GetSpot application.

## 1. Firebase Project Strategy: Complete Separation

The foundation of this setup is to use **two completely separate Firebase projects**.

- **`getspot-dev`**: The development project.
- **`getspot-prod`**: The production project.

**Justification:**
- **Data Isolation**: Development data (Firestore, Auth, Storage) remains completely separate from production data, preventing accidental corruption and enabling free testing.
- **Security**: Permissive security rules can be used in `dev` for easier testing, while `prod` rules remain stringent and secure.
- **Resource Quotas**: Firebase usage in the `dev` project does not consume `prod` quotas.

## 2. Flutter Client Configuration: Flavors

Flutter's **flavors** mechanism will be used to build the single codebase with different configurations for `dev` and `prod`.

- **Android**: Create two `google-services.json` files, one for each Firebase project, and place them in flavor-specific source directories:
  - `android/app/src/dev/google-services.json`
  - `android/app/src/prod/google-services.json`

- **iOS**: Create two `GoogleService-Info.plist` files and use a build script in Xcode to copy the correct one into the `Runner` directory at build time based on the selected flavor/configuration.

- **Web & Dart Configuration**: Use the `FirebaseOptions` class. Generate environment-specific files (e.g., `firebase_options_dev.dart`, `firebase_options_prod.dart`) using the FlutterFire CLI. The application will import and use the appropriate options at startup based on the build flavor.

## 3. Cloud Functions Deployment

The single `functions` codebase will be deployed to both Firebase projects using Firebase CLI **project aliases**.

1.  **Configure Aliases**: Set up `dev` and `prod` aliases pointing to the respective Firebase projects.
    ```shell
    firebase use --add
    ```
2.  **Deploy to a Specific Environment**:
    ```shell
    # Deploy to development
    firebase deploy --project dev

    # Deploy to production
    firebase deploy --project prod
    ```

## 4. Build & CI/CD Workflow

The build and deployment process will be flavor-aware.

- **Local Development**: Use `flutter run --flavor dev` to connect to the `dev` environment.
- **Testing/Staging**: CI/CD pipelines triggered from a `develop` branch should build the `dev` flavor and deploy resources to the `dev` Firebase project.
- **Production Release**: Merges to the `main` branch should trigger a `prod` build (e.g., `flutter build appbundle --flavor prod`) and deploy resources to the `prod` Firebase project.
