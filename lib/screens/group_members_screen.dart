import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                return ListTile(
                  title: Text(name),
                  subtitle: Text('Balance: $balance'),
                  trailing: isAdmin ? _AdminActions(
                    groupId: groupId,
                    targetUid: uid,
                    isOwner: isOwner,
                    balance: double.tryParse(balance) ?? 0,
                  ) : null,
                );
              },
            );
        },
      ),
    );
  }
}

class _AdminActions extends StatefulWidget {
  final String groupId;
  final String targetUid;
  final bool isOwner;
  final double balance;
  const _AdminActions({required this.groupId, required this.targetUid, required this.isOwner, required this.balance});

  @override
  State<_AdminActions> createState() => _AdminActionsState();
}

class _AdminActionsState extends State<_AdminActions> {
  bool _busy = false;

  Future<void> _remove() async {
    if (widget.isOwner) return; // cannot remove owner
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
    final amount = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Credits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          TextButton(onPressed: () {
            final a = double.tryParse(amountController.text.trim());
            Navigator.pop(ctx, a);
          }, child: const Text('Confirm')),
        ],
      ),
    );
    if (amount == null || amount <= 0) return;
    setState(() => _busy = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('manageGroupMember');
      await callable.call({
        'groupId': widget.groupId,
        'targetUserId': widget.targetUid,
        'action': 'credit',
        'amount': amount,
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
      return const SizedBox(width: 56, height: 24, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
    }
    // Prevent remove button if owner or balance non-zero
    final canRemove = !widget.isOwner && widget.balance == 0;
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'credit':
            _credit();
            break;
          case 'remove':
            _remove();
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'credit', child: Text('Add Credits')),
        PopupMenuItem(
          value: 'remove',
          enabled: canRemove,
          child: Text(canRemove ? 'Remove Member' : 'Remove (disabled)'),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}
