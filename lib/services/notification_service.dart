import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-east4');
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Request permission for iOS and web
    await _firebaseMessaging.requestPermission();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(initializationSettings);

    final fcmToken = await _firebaseMessaging.getToken();
    developer.log('FCM Token: $fcmToken', name: 'NotificationService');

    if (fcmToken != null) {
      await _updateTokenInFirestore(fcmToken);
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_updateTokenInFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(notification);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
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
