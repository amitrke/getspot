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

  // Callback for notification tap navigation
  static Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> initNotifications() async {
    // Request permission for iOS and web
    await _firebaseMessaging.requestPermission();

    // Initialize local notifications with tap handling
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

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
        _showLocalNotification(notification, message.data);
      }
    });

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        'Notification tapped (from background): ${message.data}',
        name: 'NotificationService',
      );
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        'App opened from terminated state via notification: ${initialMessage.data}',
        name: 'NotificationService',
      );
      // Delay to allow navigation setup
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    developer.log(
      'Local notification tapped: ${response.payload}',
      name: 'NotificationService',
    );
    if (response.payload != null) {
      // Parse payload if needed
      _handleNotificationTap({'source': 'local', 'payload': response.payload});
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    if (onNotificationTap != null) {
      onNotificationTap!(data);
    } else {
      developer.log(
        'No notification tap handler registered',
        name: 'NotificationService',
      );
    }
  }

  Future<void> _showLocalNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
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
      payload: data.isNotEmpty ? data.toString() : null,
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
