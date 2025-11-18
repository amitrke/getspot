import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getspot/firebase_options.dart';
import 'package:getspot/screens/home_screen.dart';
import 'package:getspot/screens/login_screen.dart';
import 'package:getspot/screens/event_details_screen.dart';
import 'package:getspot/screens/group_details_screen.dart';
import 'dart:developer' as developer;
import 'package:getspot/services/notification_service.dart';
import 'package:getspot/services/analytics_service.dart';
import 'package:getspot/services/crashlytics_service.dart';
import 'package:getspot/services/feature_flag_service.dart';
import 'package:getspot/screens/join_group_screen.dart';
import 'package:app_links/app_links.dart';
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

  // Configure system UI for edge-to-edge on Android
  // Use transparent system bars (handled by native code for Android 15+)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase App Check for security
  // Protects backend resources from abuse and unauthorized access
  await FirebaseAppCheck.instance.activate(
    // iOS: Use DeviceCheck for production, Debug provider for development
    // Android: Use Play Integrity for production, Debug provider for development
    // Web: Use ReCAPTCHA v3
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.deviceCheck,
    webProvider: ReCaptchaV3Provider('6LcNYKYqAAAAADQGaWv-f3W8kVxaFT84HMO9JfSX'),
  );

  developer.log(
    'App Check activated - Provider: ${kDebugMode ? 'Debug' : 'Production'}',
    name: 'AppCheck',
  );

  // Initialize Firebase Crashlytics
  // Note: setCrashlyticsCollectionEnabled is handled automatically by Firebase
  // on iOS via firebase.json configuration
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

  // Global key for navigation from notification handlers
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GetSpot',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        AnalyticsService().getAnalyticsObserver(),
      ],
      onGenerateRoute: (settings) {
        // Handle /join/{code} route for web
        if (settings.name != null && settings.name!.startsWith('/join/')) {
          final code = settings.name!.substring('/join/'.length);
          if (code.isNotEmpty) {
            developer.log('Handling web route: ${settings.name}', name: 'MyApp');
            return MaterialPageRoute(
              builder: (context) => JoinGroupScreen(groupCode: code),
              settings: settings,
            );
          }
        }
        return null;
      },
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
  late AppLinks _appLinks;
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    // Set up notification tap handler for navigation
    NotificationService.onNotificationTap = _handleNotificationNavigation;
    // Initialize deep link handler
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links when app is already running
    _appLinks.uriLinkStream.listen((uri) {
      developer.log('Deep link received: $uri', name: 'AuthWrapper');
      _handleDeepLink(uri);
    }, onError: (e) {
      developer.log('Error handling deep link', name: 'AuthWrapper', error: e);
    });

    // Check if app was opened from a deep link
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        developer.log('App opened with deep link: $uri', name: 'AuthWrapper');
        _handleDeepLink(uri);
      }
    } catch (e) {
      developer.log('Error getting initial link', name: 'AuthWrapper', error: e);
    }
  }

  void _handleDeepLink(Uri uri) {
    developer.log('Processing deep link: $uri', name: 'AuthWrapper');

    // Get the navigator context
    final navigatorContext = MyApp.navigatorKey.currentContext;
    if (navigatorContext == null) {
      developer.log('Navigator context not available', name: 'AuthWrapper');
      return;
    }

    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('User not authenticated, cannot handle deep link', name: 'AuthWrapper');
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to join a group'),
        ),
      );
      return;
    }

    // Parse the deep link
    // Expected format: https://getspot.org/join/{GROUP_CODE}
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
      final groupCode = uri.pathSegments[1];
      if (groupCode.isNotEmpty) {
        developer.log('Navigating to join group with code: $groupCode', name: 'AuthWrapper');
        Navigator.of(navigatorContext).push(
          MaterialPageRoute(
            builder: (context) => JoinGroupScreen(groupCode: groupCode),
          ),
        );
      }
    } else {
      developer.log('Unknown deep link format: $uri', name: 'AuthWrapper');
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    developer.log('Handling notification navigation: $data', name: 'AuthWrapper');

    final type = data['type'] as String?;
    final eventId = data['eventId'] as String?;
    final groupId = data['groupId'] as String?;

    // Get the navigator context
    final navigatorContext = MyApp.navigatorKey.currentContext;
    if (navigatorContext == null) {
      developer.log('Navigator context not available, cannot navigate', name: 'AuthWrapper');
      return;
    }

    // Navigate based on notification type
    if (type == 'new_event' && eventId != null) {
      developer.log('Navigating to event: $eventId', name: 'AuthWrapper');
      _navigateToEvent(navigatorContext, eventId);
    } else if (type == 'announcement' && groupId != null) {
      developer.log('Navigating to group (from announcement): $groupId', name: 'AuthWrapper');
      _navigateToGroup(navigatorContext, groupId);
    } else if (type == 'join_approved' && groupId != null) {
      developer.log('Navigating to group: $groupId', name: 'AuthWrapper');
      _navigateToGroup(navigatorContext, groupId);
    } else if (type == 'event_reminder' && eventId != null) {
      developer.log('Navigating to event: $eventId', name: 'AuthWrapper');
      _navigateToEvent(navigatorContext, eventId);
    } else if (type == 'event_cancelled' && eventId != null) {
      developer.log('Navigating to event: $eventId', name: 'AuthWrapper');
      _navigateToEvent(navigatorContext, eventId);
    } else if (type == 'waitlist_promoted' && eventId != null) {
      developer.log('Navigating to event: $eventId', name: 'AuthWrapper');
      _navigateToEvent(navigatorContext, eventId);
    }
  }

  void _navigateToEvent(BuildContext context, String eventId) async {
    try {
      // Fetch event to check if user is admin of the group
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (!eventDoc.exists) {
        developer.log('Event not found: $eventId', name: 'AuthWrapper');
        return;
      }

      final eventData = eventDoc.data();
      final groupId = eventData?['groupId'] as String?;

      if (groupId == null) {
        developer.log('Group ID not found for event: $eventId', name: 'AuthWrapper');
        return;
      }

      // Check if current user is admin of the group
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      final groupData = groupDoc.data();
      final currentUser = FirebaseAuth.instance.currentUser;
      final isAdmin = currentUser != null && groupData?['admin'] == currentUser.uid;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EventDetailsScreen(
            eventId: eventId,
            isGroupAdmin: isAdmin,
          ),
        ),
      );
    } catch (e, st) {
      developer.log(
        'Error navigating to event',
        name: 'AuthWrapper',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _navigateToGroup(BuildContext context, String groupId) async {
    try {
      // Fetch group data
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        developer.log('Group not found: $groupId', name: 'AuthWrapper');
        return;
      }

      final groupData = groupDoc.data();
      if (groupData == null) {
        developer.log('Group data is null for: $groupId', name: 'AuthWrapper');
        return;
      }

      // Add groupId to the map
      final groupWithId = {...groupData, 'groupId': groupId};

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GroupDetailsScreen(group: groupWithId),
        ),
      );
    } catch (e, st) {
      developer.log(
        'Error navigating to group',
        name: 'AuthWrapper',
        error: e,
        stackTrace: st,
      );
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
          // Initialize notifications when user signs in (only once)
          if (!_notificationsInitialized) {
            _notificationsInitialized = true;
            _notificationService.initNotifications();
          }
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

