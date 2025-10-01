import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getspot/helpers/platform_helper.dart';
import 'package:getspot/services/auth_service.dart';
import 'package:getspot/widgets/app_logo.dart';
import 'package:url_launcher/url_launcher.dart';

enum AuthMode { signIn, register, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  AuthMode _authMode = AuthMode.signIn;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  bool _isIOS() {
    if (kIsWeb) {
      final userAgent = getUserAgent();
      return userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod');
    }
    return false;
  }

  bool _isAndroid() {
    if (kIsWeb) {
      final userAgent = getUserAgent();
      return userAgent.contains('android');
    }
    return false;
  }

  Future<void> _launchAppStore() async {
    final Uri url =
        Uri.parse('https://apps.apple.com/app/getspot/6752911639');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchPlayStore() async {
    final Uri url = Uri.parse(
        'https://play.google.com/store/apps/details?id=org.getspot');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _setAuthMode(AuthMode mode) {
    setState(() {
      _authMode = mode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      switch (_authMode) {
        case AuthMode.signIn:
          await _authService.signInWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
          );
          break;
        case AuthMode.register:
          await _authService.signUpWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
            _displayNameController.text,
          );
          break;
        case AuthMode.forgotPassword:
          await _authService.sendPasswordResetEmail(_emailController.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset link sent to your email.'),
              ),
            );
            _setAuthMode(AuthMode.signIn);
          }
          break;
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "An error occurred."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const AppLogo(size: 100),
                  const SizedBox(height: 24),
                  Text(
                    _showEmailForm
                        ? (_authMode == AuthMode.signIn
                            ? 'Sign In'
                            : _authMode == AuthMode.register
                                ? 'Create Account'
                                : 'Reset Password')
                        : 'Welcome to GetSpot',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (_isIOS()) ...[
                    _buildIOSAppButton(),
                    const SizedBox(height: 24),
                  ],
                  if (_isAndroid()) ...[
                    _buildAndroidAppButton(),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login), // Replace with a proper Google icon
                    onPressed: () => _authService.signInWithGoogle(),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_showEmailForm)
                    _buildAuthForm()
                  else
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showEmailForm = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Sign in with Email'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSAppButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.apple),
      onPressed: _launchAppStore,
      label: const Text('Get the iPhone App'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildAndroidAppButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.android),
      onPressed: _launchPlayStore,
      label: const Text('Get the Android App'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_authMode == AuthMode.register)
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your name' : null,
            ),
          if (_authMode != AuthMode.signIn) const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value!.isEmpty || !value.contains('@') ? 'Invalid email' : null,
          ),
          if (_authMode != AuthMode.forgotPassword) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) => value!.length < 6
                  ? 'Password must be at least 6 characters'
                  : null,
            ),
          ],
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(_authMode == AuthMode.signIn
                  ? 'Sign In'
                  : (_authMode == AuthMode.register
                      ? 'Register'
                      : 'Send Reset Link')),
            ),
          const SizedBox(height: 16),
          _buildAuthModeSwitch(),
        ],
      ),
    );
  }

  Widget _buildAuthModeSwitch() {
    if (_authMode == AuthMode.signIn) {
      return Column(
        children: [
          TextButton(
            onPressed: () => _setAuthMode(AuthMode.forgotPassword),
            child: const Text('Forgot Password?'),
          ),
          TextButton(
            onPressed: () => _setAuthMode(AuthMode.register),
            child: const Text('Don\'t have an account? Register'),
          ),
        ],
      );
    } else {
      return TextButton(
        onPressed: () => _setAuthMode(AuthMode.signIn),
        child: const Text('Already have an account? Sign In'),
      );
    }
  }
}
