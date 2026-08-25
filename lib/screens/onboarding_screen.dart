import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getspot/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final bool showSkip;

  const OnboardingScreen({super.key, this.showSkip = true});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> _buildPages(AppLocalizations l10n) => [
        OnboardingPage(
          icon: Icons.groups,
          title: l10n.onboardingPage1Title,
          description: l10n.onboardingPage1Description,
          color: Colors.blue,
        ),
        OnboardingPage(
          icon: Icons.event,
          title: l10n.onboardingPage2Title,
          description: l10n.onboardingPage2Description,
          color: Colors.green,
        ),
        OnboardingPage(
          icon: Icons.account_balance_wallet,
          title: l10n.onboardingPage3Title,
          description: l10n.onboardingPage3Description,
          color: Colors.orange,
        ),
        OnboardingPage(
          icon: Icons.schedule,
          title: l10n.onboardingPage4Title,
          description: l10n.onboardingPage4Description,
          color: Colors.purple,
        ),
        OnboardingPage(
          icon: Icons.notifications_active,
          title: l10n.onboardingPage5Title,
          description: l10n.onboardingPage5Description,
          color: Colors.red,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _nextPage() {
    final pageCount = _buildPages(AppLocalizations.of(context)!).length;
    if (_currentPage < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _buildPages(l10n);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (widget.showSkip)
              Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  label: 'skip_onboarding_button',
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(l10n.onboardingSkipButton),
                  ),
                ),
              ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(pages[index]);
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: pages.length,
                effect: WormEffect(
                  dotHeight: 12,
                  dotWidth: 12,
                  activeDotColor: Theme.of(context).primaryColor,
                  dotColor: Colors.grey.shade300,
                ),
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_currentPage > 0)
                    Semantics(
                      label: 'onboarding_back_button',
                      child: TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(l10n.onboardingBackButton),
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  // Next/Get Started button
                  Semantics(
                    label: _currentPage == pages.length - 1
                        ? 'get_started_button'
                        : 'onboarding_next_button',
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        _currentPage == pages.length - 1
                            ? l10n.onboardingGetStartedButton
                            : l10n.onboardingNextButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
