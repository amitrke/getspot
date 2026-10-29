import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/models/group_view_model.dart';
import 'package:getspot/screens/group_details_screen.dart';
import 'package:getspot/theme/theme.dart';
import 'package:getspot/widgets/status_badge.dart';
import 'package:intl/intl.dart';

class GroupListItem extends StatelessWidget {
  final GroupViewModel viewModel;

  const GroupListItem({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final bool isPending =
        viewModel.membershipStatus == GroupMembershipStatus.pending;
    final bool isAdmin =
        viewModel.admin == FirebaseAuth.instance.currentUser?.uid;
    final bool hasPendingRequests = viewModel.pendingJoinRequestsCount > 0;

    return Semantics(
      label: 'group_item_${viewModel.groupId}',
      child: Card(
        key: ValueKey('group_item_${viewModel.groupId}'),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs + 2,
        ),
        child: InkWell(
          onTap: isPending
              ? null
              : () {
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
                },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GroupAvatar(name: viewModel.name),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        viewModel.name,
                        style: context.textStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isPending)
                      Icon(
                        Icons.chevron_right,
                        color: context.colors.onSurfaceVariant,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (isPending)
                  const StatusBadge(kind: StatusKind.pending)
                else
                  _buildMemberContent(
                    context,
                    isAdmin: isAdmin,
                    hasPendingRequests: hasPendingRequests,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberContent(
    BuildContext context, {
    required bool isAdmin,
    required bool hasPendingRequests,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final semantic = context.semantic;
    final balance = viewModel.walletBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin && hasPendingRequests) ...[
          StatusBadge(
            kind: StatusKind.requested,
            label: l10n.groupItemPendingApproval(
              viewModel.pendingJoinRequestsCount,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Icon(
              Icons.event,
              size: AppSizes.iconSm,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: Text(
                viewModel.nextEventDate != null
                    ? DateFormat.MMMEd(
                        locale,
                      ).add_jm().format(viewModel.nextEventDate!)
                    : l10n.groupItemNoUpcomingEvents,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            StatusBadge.fromParticipantStatus(viewModel.eventStatus),
            const Spacer(),
            Icon(
              Icons.account_balance_wallet_outlined,
              size: AppSizes.iconSm,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              balance < 0 ? '-\$${-balance}' : '\$$balance',
              style: context.textStyles.titleSmall?.tabular.copyWith(
                color: balance < 0 ? semantic.debit : semantic.credit,
              ),
            ),
          ],
        ),
      ],
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
