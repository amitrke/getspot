import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/services/auth_service.dart';
import 'package:getspot/services/group_cache_service.dart';
import 'package:getspot/services/user_cache_service.dart';
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
        groupName: group?.name ?? 'Group',
        balance: member?.data()?['walletBalance'] ?? 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                                : 'A',
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
                                user.displayName ?? 'Anonymous',
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
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account?'),
                      content: const Text(
                          'This action is irreversible. All your data will be permanently deleted. If you have a positive balance in any of your groups, it will be forfeited. Are you sure you want to continue?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
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
                          title: const Text('Error'),
                          content:
                              Text(e.message ?? 'An unknown error occurred.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: const Text('Delete Account',
                    style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 24),
              _buildNotificationSettings(context, user.uid),
              const SizedBox(height: 24),
              Text('Group Balances',
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
                      return const Center(
                          child: Text('No group memberships yet.'));
                    }

                    // Use FutureBuilder at the top level, not in ListView
                    return FutureBuilder<List<GroupBalance>>(
                      future: _fetchGroupBalances(user.uid, memberships),
                      builder: (context, balanceSnapshot) {
                        if (balanceSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (balanceSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${balanceSnapshot.error}'));
                        }
                        final balances = balanceSnapshot.data ?? [];
                        return ListView.builder(
                          itemCount: balances.length,
                          itemBuilder: (context, index) {
                            final balance = balances[index];
                            return ListTile(
                              title: Text(balance.groupName),
                              subtitle: Text(
                                  'Balance: ${balance.balance.toStringAsFixed(2)}'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Settings',
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
                  title: const Text('Push Notifications'),
                  subtitle: const Text(
                      'Receive notifications for new events, join approvals, and reminders'),
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
                              ? 'Notifications enabled'
                              : 'Notifications disabled'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating settings: $e'),
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Display Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'New Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
                    const SnackBar(
                        content: Text('Display name updated successfully!')),
                  );
                  // The UI will update automatically via the StreamBuilder
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'An error occurred: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
