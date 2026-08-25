import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/models/group_view_model.dart';
import 'package:getspot/screens/group_details_screen.dart';
import 'package:intl/intl.dart';

class GroupListItem extends StatelessWidget {
  final GroupViewModel viewModel;

  const GroupListItem({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isPending =
        viewModel.membershipStatus == GroupMembershipStatus.pending;
    final bool isAdmin =
        viewModel.admin == FirebaseAuth.instance.currentUser?.uid;
    final bool hasPendingRequests = viewModel.pendingJoinRequestsCount > 0;

    return Semantics(
      label: 'group_item_${viewModel.groupId}',
      child: Card(
        key: ValueKey('group_item_${viewModel.groupId}'),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(viewModel.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (isPending)
                Chip(
                  label: Text(l10n.groupItemPendingChip),
                  backgroundColor: Colors.orange,
                  labelStyle: const TextStyle(color: Colors.white),
                )
              else
                _buildMemberContent(context,
                    isAdmin: isAdmin, hasPendingRequests: hasPendingRequests),
            ],
          ),
          trailing: isPending ? null : const Icon(Icons.chevron_right),
          onTap: isPending
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GroupDetailsScreen(group: {
                        'groupId': viewModel.groupId,
                        'name': viewModel.name,
                        'description': viewModel.description,
                        'admin': viewModel.admin,
                        'groupCode': viewModel.groupCode,
                      }),
                    ),
                  );
                },
        ),
      ),
    );
  }

  Widget _buildMemberContent(BuildContext context,
      {required bool isAdmin, required bool hasPendingRequests}) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin && hasPendingRequests) ...[
          Text(
            l10n.groupItemPendingApproval(viewModel.pendingJoinRequestsCount),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                viewModel.nextEventDate != null
                    ? DateFormat.yMMMEd(locale)
                        .add_jm()
                        .format(viewModel.nextEventDate!)
                    : l10n.groupItemNoUpcomingEvents,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _getStatusIcon(viewModel.eventStatus),
            const SizedBox(width: 4),
            Text(_statusLabel(l10n, viewModel.eventStatus)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 16),
            const SizedBox(width: 4),
            Text(
              '\$${viewModel.walletBalance}',
              style: TextStyle(
                color:
                    viewModel.walletBalance < 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'confirmed':
        return l10n.groupItemStatusConfirmed;
      case 'waitlisted':
        return l10n.groupItemStatusWaitlisted;
      case 'denied':
        return l10n.groupItemStatusDenied;
      default:
        return l10n.groupItemStatusNotRegistered;
    }
  }

  Widget _getStatusIcon(String? status) {
    switch (status) {
      case 'confirmed':
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case 'waitlisted':
        return const Icon(Icons.pending, color: Colors.orange, size: 16);
      case 'denied':
        return const Icon(Icons.cancel, color: Colors.red, size: 16);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 16);
    }
  }
}
