import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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
      print(e);
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
