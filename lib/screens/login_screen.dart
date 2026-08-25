import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getspot/helpers/platform_helper.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/screens/home_screen.dart';
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

  bool _shouldShowAppleSignIn() {
    // Show Apple Sign-In on web and iOS, hide on Android
    if (kIsWeb) {
      return true; // Works via Firebase popup on web
    }
    return defaultTargetPlatform == TargetPlatform.iOS; // Only show on iOS native, not Android
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
              SnackBar(
                content: Text(AppLocalizations.of(context)!.loginPasswordResetSent),
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
            content: Text(e.message ?? AppLocalizations.of(context)!.loginGenericError),
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
    final l10n = AppLocalizations.of(context)!;
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
                            ? l10n.loginSignIn
                            : _authMode == AuthMode.register
                                ? l10n.loginCreateAccount
                                : l10n.loginResetPasswordTitle)
                        : l10n.loginWelcomeTitle,
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
                  if (_shouldShowAppleSignIn()) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.apple),
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          final result = await _authService.signInWithApple();
                          if (!mounted) return;

                          // On web, signInWithPopup doesn't reliably trigger auth streams
                          // Navigate manually if sign-in was successful
                          if (result != null && result.user != null) {
                            if (mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                              );
                            }
                          }
                        } catch (e) {
                          if (!mounted) return;
                          setState(() {
                            _isLoading = false;
                          });
                          final messenger = ScaffoldMessenger.of(context);
                          final colorScheme = Theme.of(context).colorScheme;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.loginSignInFailed(e.toString())),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      },
                      label: Text(l10n.loginSignInWithApple),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login), // Replace with a proper Google icon
                    onPressed: _isLoading ? null : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        final result = await _authService.signInWithGoogle();
                        if (!mounted) return;

                        // On web, signInWithPopup doesn't reliably trigger auth streams
                        // Navigate manually if sign-in was successful
                        if (result != null && result.user != null) {
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                            );
                          }
                        }
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _isLoading = false;
                        });
                        final messenger = ScaffoldMessenger.of(context);
                        final colorScheme = Theme.of(context).colorScheme;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.loginSignInFailed(e.toString())),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      }
                    },
                    label: Text(l10n.loginSignInWithGoogle),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(l10n.loginOrDivider),
                      ),
                      const Expanded(child: Divider()),
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
                      child: Text(l10n.loginSignInWithEmail),
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
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      icon: const Icon(Icons.apple),
      onPressed: _launchAppStore,
      label: Text(l10n.loginGetIphoneApp),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildAndroidAppButton() {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      icon: const Icon(Icons.android),
      onPressed: _launchPlayStore,
      label: Text(l10n.loginGetAndroidApp),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildAuthForm() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_authMode == AuthMode.register)
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(labelText: l10n.loginDisplayNameLabel),
              validator: (value) =>
                  value!.isEmpty ? l10n.loginValidatorEnterName : null,
            ),
          if (_authMode != AuthMode.signIn) const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: l10n.loginEmailLabel),
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value!.isEmpty || !value.contains('@')
                ? l10n.loginValidatorInvalidEmail
                : null,
          ),
          if (_authMode != AuthMode.forgotPassword) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
              obscureText: true,
              validator: (value) => value!.length < 6
                  ? l10n.loginValidatorPasswordLength
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
                  ? l10n.loginSignIn
                  : (_authMode == AuthMode.register
                      ? l10n.loginRegisterButton
                      : l10n.loginSendResetLinkButton)),
            ),
          const SizedBox(height: 16),
          _buildAuthModeSwitch(),
        ],
      ),
    );
  }

  Widget _buildAuthModeSwitch() {
    final l10n = AppLocalizations.of(context)!;
    if (_authMode == AuthMode.signIn) {
      return Column(
        children: [
          TextButton(
            onPressed: () => _setAuthMode(AuthMode.forgotPassword),
            child: Text(l10n.loginForgotPassword),
          ),
          TextButton(
            onPressed: () => _setAuthMode(AuthMode.register),
            child: Text(l10n.loginNoAccountRegisterLink),
          ),
        ],
      );
    } else {
      return TextButton(
        onPressed: () => _setAuthMode(AuthMode.signIn),
        child: Text(l10n.loginHaveAccountSignInLink),
      );
    }
  }
}
