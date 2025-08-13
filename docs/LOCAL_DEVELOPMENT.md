# Local Development Guide

This guide provides instructions on how to set up and run the GetSpot project on your local machine for development and testing purposes.

## Prerequisites

Before you begin, ensure you have the following installed:

*   **Flutter SDK:** Make sure you have the Flutter SDK installed and configured correctly. You can find installation instructions on the [official Flutter website](https://flutter.dev/docs/get-started/install).
*   **An IDE:** An IDE like Visual Studio Code with the Flutter extension or Android Studio is recommended.

## Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/getspot.git
    cd getspot
    ```

2.  **Install dependencies:**
    Run the following command to fetch the project's dependencies:
    ```bash
    flutter pub get
    ```

## Running the App

You can run the app on a mobile emulator, a physical device, or in a web browser.

### Mobile (Android/iOS)

To run the app on a connected device or emulator, use the following command:

```bash
flutter run
```

### Web

To run the app in a Chrome web browser, use the following command:

```bash
flutter run -d chrome
```

## Building the App

You can build the app for various platforms. Here are some common build commands:

*   **Build an Android APK:**
    ```bash
    flutter build apk
    ```

*   **Build an iOS App:**
    *(Note: This requires a macOS machine with Xcode installed.)*
    ```bash
    flutter build ios
    ```

*   **Build for the Web:**
    ```bash
    flutter build web
    ```
    The output will be in the `build/web` directory.
