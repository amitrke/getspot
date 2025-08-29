import 'package:flutter/material.dart';
import 'package:getspot/services/auth_service.dart';
import 'package:getspot/widgets/app_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const AppLogo(size: 120),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => AuthService().signInWithGoogle(),
              child: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
