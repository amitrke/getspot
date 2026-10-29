import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:getspot/models/group_view_model.dart';

import 'package:getspot/screens/faq_screen.dart';
import 'package:getspot/services/group_service.dart';
import 'package:getspot/services/group_cache_service.dart';
import 'package:getspot/services/user_cache_service.dart';
import 'package:getspot/services/upcoming_events_service.dart';
import 'package:getspot/providers/participant_provider.dart';
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
import 'package:getspot/widgets/section_header.dart';
import 'package:getspot/widgets/upcoming_event_card.dart';

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
    return Scaffold(
      appBar: AppBar(
        // Brand name rather than "My Groups": Home now leads with games
        // across all groups, not just the group list.
        title: const Text('GetSpot'),
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
      body: SafeArea(
        child: ConstrainedContent(
          child: _HomeFeed(
            onJoinGroup: () => _openJoinGroupModal(context),
            onCreateGroup: () => _openCreateGroupModal(context),
          ),
        ),
      ),
    );
  }
}

/// Home content: "Your next games" across all groups, then "Your groups".
/// With no groups yet it shows the first-run welcome with Join / Create.
class _HomeFeed extends StatefulWidget {
  final VoidCallback onJoinGroup;
  final VoidCallback onCreateGroup;

  const _HomeFeed({required this.onJoinGroup, required this.onCreateGroup});

  @override
  State<_HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<_HomeFeed> {
  late final Stream<List<GroupViewModel>> _groupsViewModelStream;
  final GroupService _groupService = GroupService();
  final UpcomingEventsService _upcomingEventsService = UpcomingEventsService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  ParticipantProvider? _participantProvider;

  // The groups stream re-emits on every participant change, so the events
  // query is only rebuilt when the set of member groups actually changes.
  String? _upcomingKey;
  Stream<List<UpcomingEvent>>? _upcomingStream;

  @override
  void initState() {
    super.initState();
    _groupsViewModelStream = _groupService.getGroupViewModelsStream();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _participantProvider = ParticipantProvider(userId: user.uid);
    }
  }

  @override
  void dispose() {
    _participantProvider?.dispose();
    super.dispose();
  }

  Stream<List<UpcomingEvent>> _upcomingFor(List<GroupViewModel> groups) {
    final ids =
        groups
            .where((g) => g.membershipStatus == GroupMembershipStatus.member)
            .map((g) => g.groupId)
            .toList()
          ..sort();
    final key = ids.join(',');
    if (key != _upcomingKey || _upcomingStream == null) {
      _upcomingKey = key;
      _upcomingStream = _upcomingEventsService.getUpcomingEventsStream(
        groups,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
    }
    return _upcomingStream!;
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
            return _buildFirstRun(context, l10n);
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              SectionHeader(title: l10n.homeNextGamesHeader),
              _buildUpcoming(l10n, viewModels),
              const SizedBox(height: AppSpacing.md),
              SectionHeader(title: l10n.homeYourGroupsHeader),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < viewModels.length; i++) ...[
                      if (i > 0) const Divider(indent: 64),
                      GroupListItem(viewModel: viewModels[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  TextButton.icon(
                    onPressed: widget.onJoinGroup,
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text(l10n.homeJoinGroupButton),
                  ),
                  TextButton.icon(
                    onPressed: widget.onCreateGroup,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.homeCreateGroupButton),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpcoming(AppLocalizations l10n, List<GroupViewModel> groups) {
    return StreamBuilder<List<UpcomingEvent>>(
      stream: _upcomingFor(groups),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          developer.log(
            'Error loading upcoming events',
            name: 'HomeScreen',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return _UpcomingMessage(text: l10n.groupDetailsErrorLoadingEvents);
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final events = snapshot.data!;
        if (events.isEmpty) {
          return _UpcomingMessage(text: l10n.homeNoUpcomingGames);
        }
        return Column(
          children: [
            for (final event in events)
              UpcomingEventCard(
                key: ValueKey(event.id),
                event: event,
                participantProvider: _participantProvider,
              ),
          ],
        );
      },
    );
  }

  Widget _buildFirstRun(BuildContext context, AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: EmptyState(
            icon: Icons.sports_tennis,
            title: l10n.homeWelcomeTitle,
            message: l10n.homeWelcomeDescription,
            action: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: widget.onJoinGroup,
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text(l10n.homeJoinGroupButton),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: widget.onCreateGroup,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.homeCreateGroupButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Muted one-line message shown in place of the upcoming-games list.
class _UpcomingMessage extends StatelessWidget {
  final String text;
  const _UpcomingMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.event_available_outlined,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
