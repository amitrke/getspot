import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/models/group_view_model.dart';
import 'package:getspot/screens/group_details_screen.dart';
import 'package:getspot/screens/wallet_screen.dart';
import 'package:getspot/theme/theme.dart';
import 'package:getspot/widgets/status_badge.dart';
import 'package:intl/intl.dart';

/// Compact row for one group on Home: initial, name, a one-line summary
/// (next event, or pending approvals for admins), and the wallet balance,
/// which opens that group's wallet. Meant to sit inside a shared Card with
/// dividers between rows.
class GroupListItem extends StatelessWidget {
  final GroupViewModel viewModel;

  const GroupListItem({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final bool isPending =
        viewModel.membershipStatus == GroupMembershipStatus.pending;
    final bool isAdmin = viewModel.admin == uid;
    final bool hasPendingRequests = viewModel.pendingJoinRequestsCount > 0;

    return Semantics(
      label: 'group_item_${viewModel.groupId}',
      child: InkWell(
        key: ValueKey('group_item_${viewModel.groupId}'),
        onTap: isPending ? null : () => _openGroup(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              _GroupAvatar(name: viewModel.name),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.name,
                      style: context.textStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (isPending)
                      const StatusBadge(kind: StatusKind.pending)
                    else if (isAdmin && hasPendingRequests)
                      Text(
                        l10n.groupItemPendingApproval(
                          viewModel.pendingJoinRequestsCount,
                        ),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.semantic.info,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        _nextEventLabel(context, l10n),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (!isPending) ...[
                const SizedBox(width: AppSpacing.sm),
                _BalanceChip(
                  balance: viewModel.walletBalance,
                  onTap: uid == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WalletScreen(
                              groupId: viewModel.groupId,
                              userId: uid,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _nextEventLabel(BuildContext context, AppLocalizations l10n) {
    final next = viewModel.nextEventDate;
    if (next == null) return l10n.groupItemNoUpcomingEvents;
    final locale = Localizations.localeOf(context).toString();
    return l10n.homeGroupNextEvent(DateFormat.MMMEd(locale).format(next));
  }

  void _openGroup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(
          group: {
            'groupId': viewModel.groupId,
            'name': viewModel.name,
            'description': viewModel.description,
            'admin': viewModel.admin,
            'groupCode': viewModel.groupCode,
          },
        ),
      ),
    );
  }
}

/// Tappable wallet balance; red tint when negative.
class _BalanceChip extends StatelessWidget {
  final int balance;
  final VoidCallback? onTap;

  const _BalanceChip({required this.balance, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final negative = balance < 0;
    final fg = negative ? colors.onErrorContainer : colors.onSurfaceVariant;
    final label = negative ? '-\$${-balance}' : '\$$balance';

    return Material(
      color: negative ? colors.errorContainer : colors.surfaceContainerHigh,
      borderRadius: AppRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: AppSizes.iconSm,
                  color: fg,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: context.textStyles.labelLarge?.tabular.copyWith(
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded-square initial for a group.
class _GroupAvatar extends StatelessWidget {
  final String name;
  const _GroupAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.circular(AppRadius.md),
      ),
      child: Text(
        initial,
        style: context.textStyles.titleMedium?.copyWith(
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
