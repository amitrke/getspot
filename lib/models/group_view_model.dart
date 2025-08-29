
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class GroupViewModel {
  final String groupId;
  final String name;
  final String description;
  final String groupCode;
  final int walletBalance;
  final DateTime? nextEventDate;
  final String? eventStatus;
  final String admin;

  GroupViewModel({
    required this.groupId,
    required this.name,
    required this.description,
    required this.groupCode,
    required this.walletBalance,
    required this.admin,
    this.nextEventDate,
    this.eventStatus,
  });

  factory GroupViewModel.fromGroupMembership(
      QueryDocumentSnapshot<Map<String, dynamic>> membership,
      DocumentSnapshot<Map<String, dynamic>> group,
      DocumentSnapshot<Map<String, dynamic>> member,
      DocumentSnapshot<Map<String, dynamic>>? nextEvent,
      DocumentSnapshot<Map<String, dynamic>>? participant) {
    return GroupViewModel(
      groupId: group.id,
      name: group.data()?['name'] ?? 'Unnamed Group',
      description: group.data()?['description'] ?? '',
      groupCode: group.data()?['groupCode'] ?? '',
      walletBalance: member.data()?['walletBalance'] ?? 0,
      admin: group.data()?['admin'] ?? '',
      nextEventDate: (nextEvent?.data()?['eventTimestamp'] as Timestamp?)?.toDate(),
      eventStatus: participant?.data()?['status'],
    );
  }
}
