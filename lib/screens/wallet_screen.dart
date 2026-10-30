import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/services/transaction_cache_service.dart';
import 'package:getspot/theme/theme.dart';
import 'package:getspot/widgets/section_header.dart';
import 'package:getspot/widgets/constrained_content.dart';

class WalletScreen extends StatefulWidget {
  final String groupId;
  final String userId;

  const WalletScreen({super.key, required this.groupId, required this.userId});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _balanceFuture;
  late Future<List<CachedTransaction>?> _transactionsFuture;
  final _transactionCache = TransactionCacheService();

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

      // Use cache service for transactions
      _transactionsFuture = _transactionCache.getTransactions(
        widget.groupId,
        widget.userId,
      );
    });
  }

  void _invalidateCache() {
    // Invalidate transaction cache when user explicitly refreshes
    _transactionCache.invalidate(widget.groupId, widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walletAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _invalidateCache();
              _loadData();
            },
            tooltip: l10n.walletRefreshTooltip,
          ),
        ],
      ),
      body: SafeArea(
        child: ConstrainedContent(
          maxWidth: AppContentWidth.reading,
          child: RefreshIndicator(
            onRefresh: () async {
              _invalidateCache();
              _loadData();
              // Wait a bit to ensure data is refreshed
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _BalanceCard(future: _balanceFuture),
                ),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: l10n.walletHistoryHeader,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                  ),
                ),
                SliverFillRemaining(
                  child: _TransactionList(future: _transactionsFuture),
                ),
              ],
            ),
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final semantic = context.semantic;
        final onHero = semantic.onHero;
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = Center(child: CircularProgressIndicator(color: onHero));
        } else if (snapshot.hasError) {
          content = Text(
            l10n.walletErrorMessage(snapshot.error.toString()),
            style: context.textStyles.bodyMedium?.copyWith(color: onHero),
          );
        } else {
          final balance = snapshot.data?.data()?['walletBalance'] ?? 0;
          final formattedBalance = NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 2).format(balance);
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: AppSizes.iconMd, color: onHero.withValues(alpha: 0.8)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.walletCurrentBalance,
                    style: context.textStyles.labelLarge
                        ?.copyWith(color: onHero.withValues(alpha: 0.8)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                formattedBalance,
                style: context.textStyles.displaySmall?.tabular.copyWith(color: onHero),
              ),
            ],
          );
        }

        return Container(
          margin: AppSpacing.page,
          padding: const EdgeInsets.all(AppSpacing.xl),
          constraints: const BoxConstraints(minHeight: 132),
          decoration: BoxDecoration(
            borderRadius: AppRadius.circular(AppRadius.xl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [semantic.heroStart, semantic.heroEnd],
            ),
          ),
          child: content,
        );
      },
    );
  }
}

class _TransactionList extends StatelessWidget {
  final Future<List<CachedTransaction>?> future;
  const _TransactionList({required this.future});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return FutureBuilder<List<CachedTransaction>?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(l10n.walletErrorMessage(snapshot.error.toString())));
        }
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return Center(child: Text(l10n.walletNoTransactions));
        }

        return ListView.separated(
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const Divider(indent: 72, endIndent: AppSpacing.lg),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final type = transaction.type;
            final amount = transaction.amount;
            final description = transaction.description;
            final timestamp = transaction.createdAt;

            final isCredit = type == 'credit';
            final amountText = '${isCredit ? '+' : '-'}${NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 2).format(amount)}';
            final semantic = context.semantic;
            final amountColor = isCredit ? semantic.credit : semantic.debit;
            final formattedDate = timestamp != null ? DateFormat.yMMMd(locale).format(timestamp) : '';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isCredit
                    ? semantic.successContainer
                    : context.colors.errorContainer,
                foregroundColor: isCredit
                    ? semantic.onSuccessContainer
                    : context.colors.onErrorContainer,
                child: Icon(
                  isCredit ? Icons.south_west : Icons.north_east,
                  size: AppSizes.iconMd,
                ),
              ),
              title: Text(description, style: context.textStyles.bodyLarge),
              subtitle: Text(formattedDate),
              trailing: Text(
                amountText,
                style: context.textStyles.titleMedium?.tabular.copyWith(color: amountColor),
              ),
            );
          },
        );
      },
    );
  }
}
