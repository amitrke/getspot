import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getspot/firebase_options.dart';
import 'package:getspot/screens/home_screen.dart';
import 'package:getspot/screens/login_screen.dart';
import 'dart:developer' as developer;
import 'package:getspot/services/notification_service.dart';
import 'package:getspot/services/analytics_service.dart';
import 'package:getspot/services/crashlytics_service.dart';
import 'package:getspot/services/feature_flag_service.dart';
import 'package:upgrader/upgrader.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log(
    'Handling background message: ${message.messageId}',
    name: 'BackgroundMessageHandler',
  );
  developer.log(
    'Background notification - Title: ${message.notification?.title}, Body: ${message.notification?.body}',
    name: 'BackgroundMessageHandler',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by Flutter to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Remote Config for feature flags
  await FeatureFlagService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GetSpot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        AnalyticsService().getAnalyticsObserver(),
      ],
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final NotificationService _notificationService = NotificationService();
  final AnalyticsService _analytics = AnalyticsService();
  final CrashlyticsService _crashlytics = CrashlyticsService();

  @override
  void initState() {
    super.initState();
    // Set up notification tap handler for navigation
    NotificationService.onNotificationTap = _handleNotificationNavigation;
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    developer.log('Handling notification navigation: $data', name: 'AuthWrapper');

    final type = data['type'] as String?;
    final eventId = data['eventId'] as String?;
    final groupId = data['groupId'] as String?;

    // TODO: Navigate based on notification type
    // For now, just log the navigation intent
    if (type == 'new_event' && eventId != null) {
      developer.log('Would navigate to event: $eventId', name: 'AuthWrapper');
    } else if (type == 'join_approved' && groupId != null) {
      developer.log('Would navigate to group: $groupId', name: 'AuthWrapper');
    } else if (type == 'event_reminder' && eventId != null) {
      developer.log('Would navigate to event: $eventId', name: 'AuthWrapper');
    } else if (type == 'event_cancelled' && eventId != null) {
      developer.log('Would navigate to event: $eventId', name: 'AuthWrapper');
    } else if (type == 'waitlist_promoted' && eventId != null) {
      developer.log('Would navigate to event: $eventId', name: 'AuthWrapper');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Use userChanges() instead of authStateChanges() for better web compatibility
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        developer.log(
          'AuthWrapper StreamBuilder - connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, user: ${snapshot.data?.uid}',
          name: 'AuthWrapper',
        );

        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        // User is logged in
        if (user != null) {
          developer.log('Showing HomeScreen for user: ${user.uid}', name: 'AuthWrapper');
          // Set analytics user ID
          _analytics.setUserId(user.uid);
          // Set crashlytics user ID
          _crashlytics.setUserId(user.uid);
          // Initialize notifications when user signs in
          _notificationService.initNotifications();
          return UpgradeAlert(
            upgrader: Upgrader(
              durationUntilAlertAgain: const Duration(days: 1),
            ),
            child: const HomeScreen(),
          );
        }

        // User is not logged in
        developer.log('Showing LoginScreen', name: 'AuthWrapper');
        return const LoginScreen();
      },
    );
  }
}

