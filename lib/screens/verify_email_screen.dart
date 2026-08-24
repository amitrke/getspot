import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/services/auth_service.dart';
import 'dart:developer' as developer;

/// Shown by [AuthWrapper] instead of [HomeScreen] whenever a signed-in
/// user's email/password account has not verified its email address, so
/// no part of the app is reachable until they do (or they sign out).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;
  DateTime? _lastResendAt;

  Future<void> _checkVerified() async {
    setState(() {
      _isChecking = true;
    });
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      // AuthWrapper listens on userChanges(), which fires on reload(), so
      // it will automatically swap to HomeScreen once this flips to true.
      if (mounted && FirebaseAuth.instance.currentUser?.emailVerified != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Still not verified. Check your inbox (and spam folder) for the link.'),
          ),
        );
      }
    } catch (e) {
      developer.log('Error checking verification status', name: 'VerifyEmailScreen', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendEmail() async {
    if (_lastResendAt != null &&
        DateTime.now().difference(_lastResendAt!) < const Duration(seconds: 60)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait a bit before requesting another email.')),
      );
      return;
    }

    setState(() {
      _isResending = true;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _lastResendAt = DateTime.now();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent. Check your inbox.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Could not send verification email.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify your email',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to $email. Click it, then come back and tap '
                    '"I\'ve verified my email" below.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isChecking ? null : _checkVerified,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: _isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('I\'ve verified my email'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isResending ? null : _resendEmail,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend verification email'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _authService.signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
