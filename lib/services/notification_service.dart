import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callback for notification tap navigation
  static Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> initNotifications() async {
    // Verify user is authenticated before initializing
    final currentUser = FirebaseAuth.instance.currentUser;
    developer.log('Initializing notifications for user: ${currentUser?.uid}', name: 'NotificationService');

    if (currentUser == null) {
      developer.log('WARNING: User not authenticated during notification init', name: 'NotificationService');
    }

    // Request permission for iOS and web
    final permission = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    developer.log('Notification permission status: ${permission.authorizationStatus.toString()}', name: 'NotificationService');

    // Set foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications with tap handling
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_launcher_foreground');
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

    // On iOS, wait for APNS token before getting FCM token
    try {
      final apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken != null) {
        developer.log('APNS Token obtained: ${apnsToken.substring(0, 20)}...', name: 'NotificationService');
      } else {
        developer.log('WARNING: APNS Token is null, waiting for it...', name: 'NotificationService');
        // Wait a bit for APNS token to be available
        await Future.delayed(const Duration(seconds: 2));
        final retryApnsToken = await _firebaseMessaging.getAPNSToken();
        if (retryApnsToken != null) {
          developer.log('APNS Token obtained after retry: ${retryApnsToken.substring(0, 20)}...', name: 'NotificationService');
        } else {
          developer.log('ERROR: APNS Token still null after retry - notifications may not work on iOS!', name: 'NotificationService');
        }
      }
    } catch (e) {
      developer.log('Error getting APNS token: $e', name: 'NotificationService');
    }

    final fcmToken = await _firebaseMessaging.getToken();
    developer.log('FCM Token obtained: ${fcmToken != null ? "${fcmToken.substring(0, 20)}..." : "NULL"}', name: 'NotificationService');

    if (fcmToken != null) {
      developer.log('Attempting to save FCM token to Firestore...', name: 'NotificationService');
      await _updateTokenInFirestore(fcmToken);
    } else {
      developer.log('ERROR: FCM Token is null - notifications will not work!', name: 'NotificationService');
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_updateTokenInFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        'Notification received in foreground: ${message.notification?.title}',
        name: 'NotificationService',
      );
      developer.log(
        'Notification data: ${message.data}',
        name: 'NotificationService',
      );
      final notification = message.notification;
      if (notification != null) {
        developer.log('Showing local notification', name: 'NotificationService');
        _showLocalNotification(notification, message.data);
      } else {
        developer.log('No notification payload in message', name: 'NotificationService');
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
      // Verify user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        developer.log('ERROR: User not authenticated, cannot save FCM token!', name: 'NotificationService');
        return;
      }

      developer.log('Saving FCM token for user: ${currentUser.uid}', name: 'NotificationService');

      // Write token directly to Firestore
      final userRef = _firestore.collection('users').doc(currentUser.uid);
      await userRef.set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      developer.log('✓ Successfully saved FCM token to Firestore for user ${currentUser.uid}', name: 'NotificationService');

      // Verify token was saved by reading it back
      final userDoc = await userRef.get();
      final savedTokens = userDoc.data()?['fcmTokens'] as List?;
      developer.log('Verified: User now has ${savedTokens?.length ?? 0} FCM token(s)', name: 'NotificationService');
    } catch (e) {
      developer.log(
        'ERROR: Failed to save FCM token to Firestore',
        name: 'NotificationService',
        error: e,
      );
    }
  }
}
