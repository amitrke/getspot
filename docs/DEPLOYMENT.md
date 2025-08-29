# Deployment Guide

This document outlines the process for deploying the GetSpot application to Web, Android (Google Play Store), and iOS (Apple App Store).

## 1. Web Deployment (Firebase Hosting)

Web deployment is **fully automated** via GitHub Actions.

- **Trigger:** A push or merge to the `main` branch.
- **Workflow File:** `.github/workflows/firebase-hosting-merge.yml`
- **Process:**
    1. The workflow checks out the code.
    2. It sets up Flutter and builds the web application (`flutter build web`).
    3. It deploys the contents of the `build/web` directory to Firebase Hosting.
- **Staging:** Pull requests automatically trigger a preview deployment, visible in the PR checks. The workflow file is `.github/workflows/firebase-hosting-pull-request.yml`.

No manual steps are required for web deployment.

---

## 2. Android Deployment (Google Play Store)

Deploying to the Google Play Store is a manual process.

### Prerequisites

- You must have a Google Play Developer account.
- You have created an app listing in the Google Play Console.

### Step 1: Create an Upload Key

You only need to do this once. This key is used to sign your app bundle for release.

1.  **Generate a Keystore:**
    ```sh
    keytool -genkey -v -keystore C:\Users\YOUR_USER\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```
    - Replace `YOUR_USER` with your Windows username.
    - You will be prompted to create a password for the keystore and the key. **Do not forget these passwords.**
    - Store this `upload-keystore.jks` file in a secure location **outside** of the project repository.

2.  **Create `android/key.properties`:**
    Create a file named `key.properties` inside the `android` directory. This file should **not** be committed to version control (it's included in the `.gitignore`). Add the following content, replacing the placeholder values with your actual passwords and file location:

    ```properties
    storePassword=your_keystore_password
    keyPassword=your_key_password
    keyAlias=upload
    storeFile=C:\Users\YOUR_USER\upload-keystore.jks
    ```
    *Note the double backslashes `\` for the Windows path.*

### Step 2: Configure Release Signing

Modify the `android/app/build.gradle.kts` file to use your upload key for release builds.

1.  **Add Keystore Properties Logic:**
    At the top of `android/app/build.gradle.kts`, add the following code to read `key.properties`:

    ```kotlin
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(keystorePropertiesFile.inputStream())
    }
    ```

2.  **Define Signing Config:**
    Inside the `android { ... }` block, add a `signingConfigs` section:

    ```kotlin
    android {
        // ... existing config
    
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = file(keystoreProperties["storeFile"] as String?)
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }

        buildTypes {
            release {
                // Use the new signing config
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
    ```

### Step 3: Build and Deploy

1.  **Update Version Number:**
    In `pubspec.yaml`, increment the version number (e.g., `1.0.0+1` to `1.0.1+2`).

2.  **Build the App Bundle:**
    Run the following command in your terminal:
    ```sh
    flutter build appbundle
    ```

3.  **Upload to Play Console:**
    - The output will be located at `build/app/outputs/bundle/release/app-release.aab`.
    - Go to your app's dashboard in the Google Play Console.
    - Navigate to a release track (e.g., "Internal testing" or "Production").
    - Upload the `app-release.aab` file and follow the on-screen instructions to roll out the release.

---

## 3. iOS Deployment (Apple App Store)

Deploying to the App Store is a manual process that requires a macOS machine with Xcode.

### Prerequisites

- You must have an Apple Developer Program account.
- You have Xcode installed on a macOS computer.
- You have created an App ID and an app record in App Store Connect.

### Step 1: Configure in Xcode

1.  **Open the Project:**
    On your Mac, open the iOS project in Xcode:
    ```sh
    open ios/Runner.xcworkspace
    ```

2.  **Set Bundle Identifier:**
    In Xcode, select the `Runner` target. Go to the "General" tab and set the "Bundle Identifier" to the one you created in your Apple Developer account (e.g., `com.yourcompany.getspot`).

3.  **Configure Signing & Capabilities:**
    - Go to the "Signing & Capabilities" tab.
    - Select your developer team.
    - Ensure Xcode can automatically manage signing. It will create the necessary provisioning profiles and certificates.

### Step 2: Build and Deploy

1.  **Update Version Number:**
    In `pubspec.yaml`, increment the version number (e.g., `1.0.0+1` to `1.0.1+2`).

2.  **Build the IPA:**
    Run the following command in your terminal on your Mac:
    ```sh
    flutter build ipa
    ```

3.  **Upload via Xcode:**
    - After the build completes, follow the instructions in the terminal, which will typically guide you to open Xcode.
    - In Xcode, go to `Product > Archive`.
    - The Archives organizer will open. Select your new archive and click "Distribute App".
    - Follow the prompts to upload the build to App Store Connect.

4.  **Submit for Review:**
    - Once the upload is processed, go to your app's page in App Store Connect.
    - You can add the build to a test group in TestFlight for beta testing.
    - When ready, you can submit the build for App Store review.
