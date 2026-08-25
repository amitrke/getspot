import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/services/auth_service.dart';
import 'package:getspot/services/group_cache_service.dart';
import 'package:getspot/services/user_cache_service.dart';
import 'package:getspot/services/feature_flag_service.dart';
import 'package:getspot/services/crashlytics_service.dart';
import 'package:getspot/screens/login_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

class GroupBalance {
  final String groupName;
  final num balance;

  GroupBalance({required this.groupName, required this.balance});
}

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  Future<List<GroupBalance>> _fetchGroupBalances(
    String userId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> memberships,
    AppLocalizations l10n,
  ) async {
    if (memberships.isEmpty) return [];

    final groupIds = memberships
        .map((m) => m.data()['groupId'] as String)
        .toList();

    // Use GroupCacheService for batch fetching groups (with cache)
    final groupCache = GroupCacheService();
    final groupsMap = await groupCache.getGroups(groupIds);

    // Batch query for all member documents
    final memberFutures = groupIds.map((groupId) =>
        FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(userId)
            .get());

    final memberSnapshots = await Future.wait(memberFutures);
    final membersMap = {
      for (var doc in memberSnapshots)
        if (doc.exists) doc.reference.parent.parent!.id: doc
    };

    // Build the list
    return groupIds.map((groupId) {
      final group = groupsMap[groupId];
      final member = membersMap[groupId];
      return GroupBalance(
        groupName: group?.name ?? l10n.profileFallbackGroupName,
        balance: member?.data()?['walletBalance'] ?? 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.profileNotSignedIn)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName?.isNotEmpty == true
                                ? user.displayName![0].toUpperCase()
                                : l10n.profileAnonymousName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName ?? l10n.profileAnonymousName,
                                style: Theme.of(context).textTheme.headlineSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditNameDialog(context, user),
                            ),
                          ],
                        ),
                        Text(
                          user.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Debug: Crash test button (only visible to specific users via Remote Config)
              if (FeatureFlagService().canAccessCrashTest(user.uid))
                Column(
                  children: [
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bug_report, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.profileDebugToolsTitle,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.orange.shade700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      CrashlyticsService().testCrash();
                                    },
                                    icon: const Icon(Icons.warning),
                                    label: Text(l10n.profileTestCrashButton),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await CrashlyticsService().testError();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.profileTestErrorLogged),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.error_outline),
                                    label: Text(l10n.profileTestErrorButton),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.profileDeleteConfirmTitle),
                      content: Text(l10n.profileDeleteConfirmContent),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.commonCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.profileDeleteButton),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      final functions =
                          FirebaseFunctions.instanceFor(region: 'us-east4');
                      final callable =
                          functions.httpsCallable('requestAccountDeletion');
                      await callable.call();

                      if (!context.mounted) return;
                      await AuthService().signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    } on FirebaseFunctionsException catch (e) {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.profileErrorTitle),
                          content:
                              Text(e.message ?? l10n.createGroupUnknownError),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.commonOk),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: Text(l10n.profileDeleteAccountButton,
                    style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 24),
              _buildNotificationSettings(context, user.uid),
              const SizedBox(height: 24),
              Text(l10n.profileGroupBalancesHeader,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('userGroupMemberships')
                      .doc(user.uid)
                      .collection('groups')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final memberships = snapshot.data?.docs ?? [];
                    if (memberships.isEmpty) {
                      return Center(
                          child: Text(l10n.profileNoGroupMemberships));
                    }

                    // Use FutureBuilder at the top level, not in ListView
                    return FutureBuilder<List<GroupBalance>>(
                      future: _fetchGroupBalances(user.uid, memberships, l10n),
                      builder: (context, balanceSnapshot) {
                        if (balanceSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (balanceSnapshot.hasError) {
                          return Center(
                              child: Text(l10n.profileBalanceError(balanceSnapshot.error.toString())));
                        }
                        final balances = balanceSnapshot.data ?? [];
                        return ListView.builder(
                          itemCount: balances.length,
                          itemBuilder: (context, index) {
                            final balance = balances[index];
                            return ListTile(
                              title: Text(balance.groupName),
                              subtitle: Text(
                                  l10n.membersScreenBalanceLabel(balance.balance.toStringAsFixed(2))),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context, String userId) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileNotificationSettingsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                final userData = snapshot.data?.data();
                final notificationsEnabled =
                    userData?['notificationsEnabled'] ?? true;

                return SwitchListTile(
                  title: Text(l10n.profilePushNotificationsTitle),
                  subtitle: Text(l10n.profilePushNotificationsSubtitle),
                  value: notificationsEnabled,
                  onChanged: (bool value) async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .set({
                        'notificationsEnabled': value,
                      }, SetOptions(merge: true));

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value
                              ? l10n.profileNotificationsEnabled
                              : l10n.profileNotificationsDisabled),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.profileErrorUpdatingSettings(e.toString())),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, User user) {
    final nameController = TextEditingController(text: user.displayName);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.profileEditNameTitle),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: l10n.profileNewNameLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) return;

                try {
                  // 1. Update Firebase Auth
                  await user.updateDisplayName(newName);

                  // 2. Call Cloud Function to update Firestore
                  final functions =
                      FirebaseFunctions.instanceFor(region: 'us-east4');
                  final callable =
                      functions.httpsCallable('updateUserDisplayName');
                  await callable.call({'displayName': newName});

                  // 3. Invalidate user cache to force fresh data on next access
                  UserCacheService().invalidate(user.uid);

                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.profileNameUpdated)),
                  );
                  // The UI will update automatically via the StreamBuilder
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          l10n.profileGenericErrorOccurred(e.toString())),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: Text(l10n.profileSaveButton),
            ),
          ],
        );
      },
    );
  }
}
