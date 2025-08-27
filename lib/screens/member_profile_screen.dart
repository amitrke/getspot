import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.displayName ?? 'Anonymous', style: Theme.of(context).textTheme.headlineSmall),
            Text(user.email ?? ''),
            const SizedBox(height: 24),
            Text('Group Balances', style: Theme.of(context).textTheme.titleMedium),
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
                    return const Center(child: Text('No group memberships yet.'));
                  }
                  return ListView.builder(
                    itemCount: memberships.length,
                    itemBuilder: (context, index) {
                      final m = memberships[index].data();
                      final groupId = m['groupId'];
                      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
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
                          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                              final balanceStr = balNum == null ? '--' : balNum.toStringAsFixed(2);
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
    );
  }
}
