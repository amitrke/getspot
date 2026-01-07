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
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              );
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
      body: const SafeArea(child: _GroupList()),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _openJoinGroupModal(context),
                  child: const Text('Join a Group'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _openCreateGroupModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create a Group'),
                ),
              ),
            ],
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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _groupsViewModelStream = _groupService.getGroupViewModelsStream();
  }

  Future<void> _handleRefresh() async {
    developer.log('Pull-to-refresh triggered on Home Screen', name: 'HomeScreen');

    // Invalidate all caches to force fresh data
    GroupCacheService().clear();
    UserCacheService().clear();

    // Wait a bit to allow the stream to pick up fresh data
    await Future.delayed(const Duration(milliseconds: 500));

    developer.log('Caches cleared, data refreshing', name: 'HomeScreen');
  }

  @override
  Widget build(BuildContext context) {
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading groups',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _handleRefresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
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
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome to GetSpot!',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'This is your space to manage sports groups and events. '
                            'Get started by creating a new group or joining an existing one with a code.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
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