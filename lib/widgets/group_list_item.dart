
import 'package:flutter/material.dart';
import 'package:getspot/models/group_view_model.dart';
import 'package:getspot/screens/group_details_screen.dart';
import 'package:intl/intl.dart';

class GroupListItem extends StatelessWidget {
  final GroupViewModel viewModel;

  const GroupListItem({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(viewModel.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(viewModel.description),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  viewModel.nextEventDate != null
                      ? DateFormat.yMMMEd().add_jm().format(viewModel.nextEventDate!)
                      : 'No upcoming events',
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
                    color: viewModel.walletBalance < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
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
    );
  }

  Widget _getStatusIcon(String? status) {
    switch (status) {
      case 'registered':
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case 'waitlisted':
        return const Icon(Icons.pending, color: Colors.orange, size: 16);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 16);
    }
  }
}
