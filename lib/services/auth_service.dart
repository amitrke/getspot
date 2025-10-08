import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoogleSignIn _getGoogleSignIn() {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId: "932396176333-3gb68omehtpqigsc4733tvfojm72dur6.apps.googleusercontent.com",
      );
    } else if (Platform.isAndroid) {
      return GoogleSignIn(
        serverClientId: "932396176333-3gb68omehtpqigsc4733tvfojm72dur6.apps.googleusercontent.com",
      );
    } else {
      // For iOS and other platforms, the configuration is often handled via plist files
      return GoogleSignIn();
    }
  }

  late final GoogleSignIn _googleSignIn = _getGoogleSignIn();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web, use the Firebase popup flow so Firebase gets a valid idToken
        final provider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(provider);
        final user = userCredential.user;

        if (user != null) {
          developer.log('Web sign-in successful: ${user.uid}', name: 'AuthService');
          developer.log('Current auth user: ${_auth.currentUser?.uid}', name: 'AuthService');
          // Create user document in Firestore if it doesn't exist (non-blocking)
          _createUserDocumentIfNeeded(user.uid, user.displayName ?? '', user.email);
        }

        return userCredential;
      }

      // Trigger the authentication flow (mobile)
      developer.log('Starting Google Sign-In flow', name: 'AuthService');

      // Sign out first to ensure clean state
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('Google Sign-In cancelled by user', name: 'AuthService');
        return null;
      }

      developer.log('Google account selected: ${googleUser.email}', name: 'AuthService');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      developer.log('Signing in with Firebase credential', name: 'AuthService');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        developer.log('Firebase sign-in successful: ${user.uid}', name: 'AuthService');

        // Force reload to ensure auth state is updated
        await user.reload();
        await _auth.currentUser?.reload();

        developer.log('User reloaded, current user: ${_auth.currentUser?.uid}', name: 'AuthService');

        // Create user document in Firestore if it doesn't exist (non-blocking)
        _createUserDocumentIfNeeded(user.uid, user.displayName ?? '', user.email);
      }

      return userCredential;
    } catch (e) {
      // Handle error
      developer.log('Error during Google Sign-In: $e', name: 'AuthService');
      return null;
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb) {
        // For web platform, use Firebase's signInWithPopup
        final appleProvider = OAuthProvider("apple.com");
        appleProvider.addScope('email');
        appleProvider.addScope('name');

        // Use popup for web
        final userCredential = await _auth.signInWithPopup(appleProvider);
        final user = userCredential.user;

        if (user != null) {
          developer.log('Web Apple sign-in successful: ${user.uid}', name: 'AuthService');
          // For the first sign-in, create a new user document in Firestore
          _createUserDocumentIfNeeded(user.uid, user.displayName ?? '', user.email);
        }

        return userCredential;
      } else {
        // For mobile platforms (iOS/Android), use sign_in_with_apple package
        final rawNonce = _generateNonce();
        final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

        developer.log('Starting Apple Sign-In for mobile platform', name: 'AuthService');
        developer.log('Generated nonce (hashed): $nonce', name: 'AuthService');

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        if (appleCredential.identityToken == null) {
          throw FirebaseAuthException(
            code: 'missing-identity-token',
            message: 'Apple Sign-In failed: Identity token is null',
          );
        }

        final oAuthProvider = OAuthProvider("apple.com");
        final credential = oAuthProvider.credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode, // Add authorization code
        );

        developer.log('Attempting to sign in with Firebase credential', name: 'AuthService');
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          // For the first sign-in, create a new user document in Firestore
          final userDoc = _firestore.collection('users').doc(user.uid);
          final userDocSnapshot = await userDoc.get();

          if (!userDocSnapshot.exists) {
            await userDoc.set({
              'uid': user.uid,
              'displayName': appleCredential.givenName ?? user.displayName ?? '',
              'email': appleCredential.email ?? user.email,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }

        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      developer.log('Firebase Auth Error during Apple Sign-In: ${e.code} - ${e.message}', name: 'AuthService');
      developer.log('Error details: ${e.toString()}', name: 'AuthService');
      rethrow;
    } catch (e, stackTrace) {
      developer.log('Error during Apple Sign-In: $e', name: 'AuthService');
      developer.log('Stack trace: $stackTrace', name: 'AuthService');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateProfile(displayName: displayName);
        await user.reload(); // Reload user to get the updated profile
        final updatedUser = _auth.currentUser;

        // Create a document in Firestore
        await _firestore.collection('users').doc(updatedUser!.uid).set({
          'uid': updatedUser.uid,
          'displayName': displayName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return userCredential;
      }
      return null;
    } catch (e) {
      developer.log('Error during Email/Password Sign-Up: $e',
          name: 'AuthService');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      developer.log('Error during Email/Password Sign-In: $e',
          name: 'AuthService');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      developer.log('Error sending password reset email: $e',
          name: 'AuthService');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      developer.log('Signing out user', name: 'AuthService');

      // Sign out from Google first
      await _googleSignIn.signOut();

      // Disconnect Google account to ensure fresh sign-in next time
      if (!kIsWeb && await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }

      // Sign out from Firebase
      await _auth.signOut();

      developer.log('Sign out successful', name: 'AuthService');
    } catch (e) {
      developer.log('Error during sign out: $e', name: 'AuthService');
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Helper method to create user document asynchronously
  void _createUserDocumentIfNeeded(String uid, String displayName, String? email) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final userDocSnapshot = await userDoc.get();

      if (!userDocSnapshot.exists) {
        developer.log('Creating new user document for $uid', name: 'AuthService');
        await userDoc.set({
          'uid': uid,
          'displayName': displayName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        developer.log('User document created successfully', name: 'AuthService');
      }
    } catch (e) {
      developer.log('Error creating user document: $e', name: 'AuthService');
    }
  }
}