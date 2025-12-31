import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/models/group_view_model.dart';
import 'package:getspot/screens/group_details_screen.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(viewModel.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (isPending)
                const Chip(
                  label: Text('Pending'),
                  backgroundColor: Colors.orange,
                  labelStyle: TextStyle(color: Colors.white),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdmin && hasPendingRequests) ...[
          Text(
            '${viewModel.pendingJoinRequestsCount} member(s) pending approval',
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
                    ? DateFormat.yMMMEd()
                        .add_jm()
                        .format(viewModel.nextEventDate!)
                    : 'No upcoming events',
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
            Text(viewModel.eventStatus ?? 'Not Registered'),
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
