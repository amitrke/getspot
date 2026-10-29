import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:getspot/models/group_view_model.dart';

import 'package:getspot/screens/faq_screen.dart';
import 'package:getspot/services/group_service.dart';
import 'package:getspot/services/group_cache_service.dart';
import 'package:getspot/services/user_cache_service.dart';
import 'package:getspot/screens/member_profile_screen.dart';
import 'package:getspot/widgets/group_list_item.dart';
import 'package:getspot/widgets/create_group_modal.dart';
import 'package:getspot/widgets/join_group_modal.dart';
import 'package:getspot/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/theme/theme.dart';
import 'package:getspot/widgets/constrained_content.dart';
import 'package:getspot/widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (!onboardingComplete && mounted) {
      // Show onboarding after a short delay to let the home screen render
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const OnboardingScreen(showSkip: true),
            ),
          );
        }
      });
    }
  }

  void _openCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const CreateGroupModal(),
    );
  }

  void _openJoinGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const JoinGroupModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log(
      'HomeScreen build method executed. Logging should be working.',
      name: 'HomeScreen',
    );
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FaqScreen()));
            },
          ),
          Semantics(
            label: 'user_profile_button',
            child: IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MemberProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: const SafeArea(child: ConstrainedContent(child: _GroupList())),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: SafeArea(
          child: ConstrainedContent(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openJoinGroupModal(context),
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(l10n.homeJoinGroupButton),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openCreateGroupModal(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.homeCreateGroupButton),
                    ),
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

class _GroupList extends StatefulWidget {
  const _GroupList();

  @override
  State<_GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<_GroupList> {
  late final Stream<List<GroupViewModel>> _groupsViewModelStream;
  final GroupService _groupService = GroupService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _groupsViewModelStream = _groupService.getGroupViewModelsStream();
  }

  Future<void> _handleRefresh() async {
    developer.log(
      'Pull-to-refresh triggered on Home Screen',
      name: 'HomeScreen',
    );

    // Invalidate all caches to force fresh data
    GroupCacheService().clear();
    UserCacheService().clear();

    // Wait a bit to allow the stream to pick up fresh data
    await Future.delayed(const Duration(milliseconds: 500));

    developer.log('Caches cleared, data refreshing', name: 'HomeScreen');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      child: StreamBuilder<List<GroupViewModel>>(
        stream: _groupsViewModelStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final user = FirebaseAuth.instance.currentUser;
            developer.log(
              'Error fetching groups stream for user ${user?.uid}.',
              name: 'HomeScreen',
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
            return EmptyState(
              icon: Icons.error_outline,
              isError: true,
              title: l10n.homeErrorLoadingGroups,
              message: '${snapshot.error}',
              action: FilledButton.tonalIcon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.homeRetryButton),
              ),
            );
          }

          final viewModels = snapshot.data;

          if (viewModels == null || viewModels.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: EmptyState(
                    icon: Icons.sports_tennis,
                    title: l10n.homeWelcomeTitle,
                    message: l10n.homeWelcomeDescription,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: viewModels.length,
            itemBuilder: (context, index) {
              return GroupListItem(viewModel: viewModels[index]);
            },
          );
        },
      ),
    );
  }
}
