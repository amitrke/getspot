import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:getspot/firebase_options.dart';
import 'package:getspot/screens/home_screen.dart';
import 'package:getspot/screens/login_screen.dart';
import 'dart:developer' as developer;
import 'package:getspot/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          // Initialize notifications when user signs in
          _notificationService.initNotifications();
          return const HomeScreen();
        }

        // User is not logged in
        developer.log('Showing LoginScreen', name: 'AuthWrapper');
        return const LoginScreen();
      },
    );
  }
}

