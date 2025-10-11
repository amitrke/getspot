import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  final String groupId;
  final String userId;

  const WalletScreen({super.key, required this.groupId, required this.userId});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _balanceFuture;
  late Future<QuerySnapshot<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _balanceFuture = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .doc(widget.userId)
          .get();

      _transactionsFuture = FirebaseFirestore.instance
          .collection('transactions')
          .where('groupId', isEqualTo: widget.groupId)
          .where('uid', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadData();
            // Wait a bit to ensure data is refreshed
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _BalanceCard(future: _balanceFuture),
              ),
              const SliverToBoxAdapter(
                child: Divider(height: 1),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SliverFillRemaining(
                child: _TransactionList(future: _transactionsFuture),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Future<DocumentSnapshot<Map<String, dynamic>>> future;
  const _BalanceCard({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 4,
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            ),
          );
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
  final Future<QuerySnapshot<Map<String, dynamic>>> future;
  const _TransactionList({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: future,
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
