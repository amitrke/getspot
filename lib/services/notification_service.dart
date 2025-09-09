import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-east4');

  Future<void> initNotifications() async {
    // Request permission for iOS and web
    await _firebaseMessaging.requestPermission();

    final fcmToken = await _firebaseMessaging.getToken();
    developer.log('FCM Token: $fcmToken', name: 'NotificationService');

    if (fcmToken != null) {
      await _updateTokenInFirestore(fcmToken);
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_updateTokenInFirestore);
  }

  Future<void> _updateTokenInFirestore(String token) async {
    try {
      final callable = _functions.httpsCallable('updateFcmToken');
      await callable.call({'token': token});
      developer.log('Successfully updated FCM token in Firestore.', name: 'NotificationService');
    } on FirebaseFunctionsException catch (e) {
      developer.log(
        'Error updating FCM token: ${e.message}',
        name: 'NotificationService',
        error: e,
      );
    } catch (e) {
      developer.log(
        'An unexpected error occurred while updating FCM token.',
        name: 'NotificationService',
        error: e,
      );
    }
  }
}
