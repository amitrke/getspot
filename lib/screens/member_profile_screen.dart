import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/services/auth_service.dart';
import 'package:getspot/screens/login_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(user.displayName ?? 'Anonymous',
                      style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditNameDialog(context, user),
                  ),
                ],
              ),
              Text(user.email ?? ''),
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
                    return ListView.builder(
                      itemCount: memberships.length,
                      itemBuilder: (context, index) {
                        final m = memberships[index].data();
                        final groupId = m['groupId'];
                        return FutureBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance
                              .collection('groups')
                              .doc(groupId)
                              .get(),
                          builder: (context, groupSnap) {
                            String groupName = 'Group';
                            final gs = groupSnap.data; // property, not method
                            if (gs != null) {
                              final raw = gs.data();
                              if (raw != null) {
                                final nameVal = raw['name'];
                                if (nameVal is String) groupName = nameVal;
                              }
                            }
                            return FutureBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              future: FirebaseFirestore.instance
                                  .collection('groups')
                                  .doc(groupId)
                                  .collection('members')
                                  .doc(user.uid)
                                  .get(),
                              builder: (context, memberSnap) {
                                num? balNum;
                                final ms = memberSnap.data; // property
                                if (ms != null) {
                                  final rawMember = ms.data();
                                  final val = rawMember?['walletBalance'];
                                  if (val is num) balNum = val;
                                }
                                final balanceStr = balNum == null
                                    ? '--'
                                    : balNum.toStringAsFixed(2);
                                return ListTile(
                                  title: Text(groupName),
                                  subtitle: Text('Balance: $balanceStr'),
                                );
                              },
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
