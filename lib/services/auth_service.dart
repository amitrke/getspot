import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:developer' as developer;

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
        return await _auth.signInWithPopup(provider);
      }

      // Trigger the authentication flow (mobile)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      await FirebaseAuth.instance.currentUser?.reload();
      return userCredential;
    } catch (e) {
      // Handle error
      developer.log('Error during Google Sign-In: $e', name: 'AuthService');
      return null;
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
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}