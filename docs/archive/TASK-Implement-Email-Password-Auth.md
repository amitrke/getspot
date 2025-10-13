# Task: Implement Email & Password Authentication

**Objective:** To enhance user accessibility and simplify automated testing by adding a complete email and password authentication flow, including registration and password recovery, alongside the existing Google Sign-In method.

---

## 1. Backend (Firebase Console)

No code changes are required in the backend Cloud Functions. The only necessary step is to enable the new sign-in provider.

-   **Action:** In the Firebase Console for both the `dev` and `prod` projects:
    1.  Navigate to **Authentication > Sign-in method**.
    2.  Click **"Add new provider"**.
    3.  Select **"Email/Password"** and enable it.

---

## 2. Frontend (Flutter)

This task involves modifying the existing `LoginScreen` and creating new screens for registration and password recovery. All new authentication logic will be encapsulated within the `AuthService`.

### 2.1. Authentication Service (`lib/services/auth_service.dart`)

The `AuthService` will be updated to handle the new authentication methods.

-   **`signUpWithEmailAndPassword(String email, String password, String displayName)`:**
    1.  Call `FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password)`.
    2.  On success, immediately call `user.updateProfile(displayName: displayName)` on the returned `User` object to save the user's name.
    3.  Create a corresponding user document in the `/users/{userId}` Firestore collection to store `displayName`, `email`, and `createdAt`.

-   **`signInWithEmailAndPassword(String email, String password)`:**
    1.  Call `FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password)`.
    2.  Handle and surface any login errors (e.g., wrong password, user not found).

-   **`sendPasswordResetEmail(String email)`:**
    1.  Call `FirebaseAuth.instance.sendPasswordResetEmail(email: email)`.
    2.  Provide feedback to the user that an email has been sent.

### 2.2. UI - Login Screen (`lib/screens/login_screen.dart`)

The existing login screen will be refactored into a stateful widget to manage different views (login, register, forgot password).

-   **Default View:**
    -   Continue to display the prominent **"Sign in with Google"** button.
    -   Add a new button or text link: **"Sign in with Email"**.

-   **Email Sign-In View:**
    -   Toggled by the "Sign in with Email" button.
    -   Display `TextFormField` widgets for **Email** and **Password**.
    -   A primary **"Sign In"** button that calls `authService.signInWithEmailAndPassword`.
    -   A text link for **"Forgot Password?"** that navigates to the password recovery view.
    -   A text link: **"Don't have an account? Register"** that navigates to the registration view.

### 2.3. UI - New Registration Screen/View

-   **Fields:**
    -   `TextFormField` for **Display Name**.
    -   `TextFormField` for **Email**.
    -   `TextFormField` for **Password** (with obscured text).
-   **Actions:**
    -   A primary **"Register"** button that calls `authService.signUpWithEmailAndPassword`.
    -   A text link: **"Already have an account? Sign In"** that returns to the email sign-in view.

### 2.4. UI - New Forgot Password Screen/View

-   **Fields:**
    -   `TextFormField` for **Email**.
-   **Actions:**
    -   A primary **"Send Reset Link"** button that calls `authService.sendPasswordResetEmail`.
    -   A text link to return to the sign-in view.

---

## 3. Acceptance Criteria

-   [x] The "Email/Password" provider is enabled in the Firebase Authentication settings.
-   [x] The login screen prominently features Google Sign-In but also provides an option to sign in with an email and password.
-   [x] A user can navigate to a registration screen, enter a display name, email, and password, and successfully create a new account.
-   [x] The new user's `displayName` is correctly saved to their Firebase Auth profile and their document in the `users` collection.
-   [x] A registered user can successfully sign in using their email and password.
-   [x] A user who has forgotten their password can enter their email address and receive a password reset email from Firebase.
-   [x] All UI components provide appropriate loading indicators and handle/display errors gracefully (e.g., "Invalid password", "Email already in use").
