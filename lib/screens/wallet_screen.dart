import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  final String groupId;
  final String userId;

  const WalletScreen({super.key, required this.groupId, required this.userId});

  @override
  Widget build(BuildContext context) {
    final memberDocStream = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .snapshots();

    final transactionsStream = FirebaseFirestore.instance
        .collection('transactions')
        .where('groupId', isEqualTo: groupId)
        .where('uid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Wallet'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _BalanceCard(stream: memberDocStream),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _TransactionList(stream: transactionsStream),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Stream<DocumentSnapshot<Map<String, dynamic>>> stream;
  const _BalanceCard({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final balance = snapshot.data?.data()?['walletBalance'] ?? 0;
        final formattedBalance = NumberFormat.currency(symbol: '', decimalDigits: 2).format(balance);

        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  const Text('Current Balance', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(formattedBalance, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TransactionList extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  const _TransactionList({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No transactions yet.'));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final type = data['type'] ?? '';
            final amount = data['amount'] ?? 0;
            final description = data['description'] ?? 'No description';
            final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

            final isCredit = type == 'credit';
            final amountText = '${isCredit ? '+' : '-'}${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)}';
            final amountColor = isCredit ? Colors.green : Colors.red;
            final formattedDate = timestamp != null ? DateFormat.yMMMd().format(timestamp) : '';

            return ListTile(
              title: Text(description),
              subtitle: Text(formattedDate),
              trailing: Text(
                amountText,
                style: TextStyle(color: amountColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}
