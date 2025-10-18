import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/services/user_cache_service.dart';

class GroupMembersScreen extends StatelessWidget {
  final String groupId;
  final String adminUid;
  const GroupMembersScreen({super.key, required this.groupId, required this.adminUid});

  @override
  Widget build(BuildContext context) {
    final isAdmin = FirebaseAuth.instance.currentUser?.uid == adminUid;
    final membersQuery = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .orderBy('displayName');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: membersQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No members yet.'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = docs[index];
                  final data = d.data();
                  final uid = data['uid'] ?? d.id;
                  final name = data['displayName'] ?? 'No Name';
                  final balance = (data['walletBalance'] ?? 0).toString();
                  final isOwner = uid == adminUid; // single admin model

                  return FutureBuilder(
                    future: UserCacheService().getUser(uid),
                    builder: (context, snapshot) {
                      final photoURL = snapshot.data?.photoURL;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                          child: photoURL == null
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                              : null,
                        ),
                        title: Text(name),
                        subtitle: Text('Balance: $balance'),
                        trailing: isAdmin ? _AdminActions(
                          groupId: groupId,
                          targetUid: uid,
                          name: name,
                          isOwner: isOwner,
                          balance: double.tryParse(balance) ?? 0,
                        ) : null,
                      );
                    },
                  );
                },
              );
          },
        ),
      ),
    );
  }
}

class _AdminActions extends StatefulWidget {
  final String groupId;
  final String targetUid;
  final String name;
  final bool isOwner;
  final double balance;
  const _AdminActions({required this.groupId, required this.targetUid, required this.name, required this.isOwner, required this.balance});

  @override
  State<_AdminActions> createState() => _AdminActionsState();
}

class _AdminActionsState extends State<_AdminActions> {
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  Future<void> _remove() async {
    if (widget.isOwner) return; // cannot remove owner

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${widget.name}?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('manageGroupMember');
      await callable.call({
        'groupId': widget.groupId,
        'targetUserId': widget.targetUid,
        'action': 'remove',
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) _showSnack(e.message ?? 'Error');
    } catch (e) {
      if (mounted) _showSnack('Unexpected error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _credit() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Credit ${widget.name}'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }
                    if (amount <= 0) {
                      return 'Amount must be positive';
                    }
                    if (value.split('.').length > 1 && value.split('.')[1].length > 2) {
                      return 'Please enter up to two decimal places';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, {
                    'amount': double.parse(amountController.text.trim()),
                    'description': noteController.text.trim(),
                  });
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    final amount = result['amount'];
    final description = result['description'];

    setState(() => _busy = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('manageGroupMember');
      await callable.call({
        'groupId': widget.groupId,
        'targetUserId': widget.targetUid,
        'action': 'credit',
        'amount': amount,
        'description': description,
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) _showSnack(e.message ?? 'Error');
    } catch (e) {
      if (mounted) _showSnack('Unexpected error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(width: 80, child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))));
    }

    final canRemove = !widget.isOwner && widget.balance == 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          onPressed: _credit,
          tooltip: 'Add Credits',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') _remove();
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'remove',
              enabled: canRemove,
              child: Text(canRemove ? 'Remove Member' : 'Remove (balance > 0)'),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }
}
