import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/screens/onboarding_screen.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Widget _faqTile(String title, String body) {
    return ExpansionTile(
      title: Text(title),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(body),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.faqAppBarTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Text(
              l10n.faqForUsersHeader,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _faqTile(l10n.faqUsersQ1Title, l10n.faqUsersQ1Body),
            _faqTile(l10n.faqUsersQ2Title, l10n.faqUsersQ2Body),
            _faqTile(l10n.faqUsersQ3Title, l10n.faqUsersQ3Body),
            _faqTile(l10n.faqUsersQ4Title, l10n.faqUsersQ4Body),
            _faqTile(l10n.faqUsersQ5Title, l10n.faqUsersQ5Body),
            _faqTile(l10n.faqUsersQ6Title, l10n.faqUsersQ6Body),
            _faqTile(l10n.faqUsersQ7Title, l10n.faqUsersQ7Body),
            _faqTile(l10n.faqUsersQ8Title, l10n.faqUsersQ8Body),
            _faqTile(l10n.faqUsersQ9Title, l10n.faqUsersQ9Body),
            const SizedBox(height: 20),
            Text(
              l10n.faqForAdminsHeader,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _faqTile(l10n.faqAdminsQ1Title, l10n.faqAdminsQ1Body),
            _faqTile(l10n.faqAdminsQ2Title, l10n.faqAdminsQ2Body),
            _faqTile(l10n.faqAdminsQ3Title, l10n.faqAdminsQ3Body),
            _faqTile(l10n.faqAdminsQ4Title, l10n.faqAdminsQ4Body),
            _faqTile(l10n.faqAdminsQ5Title, l10n.faqAdminsQ5Body),
            _faqTile(l10n.faqAdminsQ6Title, l10n.faqAdminsQ6Body),
            _faqTile(l10n.faqAdminsQ7Title, l10n.faqAdminsQ7Body),
            _faqTile(l10n.faqAdminsQ8Title, l10n.faqAdminsQ8Body),
            _faqTile(l10n.faqAdminsQ9Title, l10n.faqAdminsQ9Body),
            _faqTile(l10n.faqAdminsQ10Title, l10n.faqAdminsQ10Body),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            // How It Works button
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingScreen(showSkip: false),
                    ),
                  );
                },
                icon: const Icon(Icons.school),
                label: Text(l10n.faqHowItWorksButton),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // About section
            Center(
              child: Text(
                l10n.faqAboutHeader,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'GetSpot',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.faqAppTagline,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.faqVersionLabel,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(_version.isEmpty ? l10n.faqLoadingPlaceholder : _version),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.faqBuildLabel,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(_buildNumber.isEmpty ? l10n.faqLoadingPlaceholder : _buildNumber),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
