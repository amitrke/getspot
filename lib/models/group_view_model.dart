import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupMembershipStatus { member, pending }

class GroupViewModel {
  final String groupId;
  final String name;
  final String description;
  final String groupCode;
  final int walletBalance;
  final DateTime? nextEventDate;
  final String? eventStatus;
  final String admin;
  final GroupMembershipStatus membershipStatus;
  final int pendingJoinRequestsCount;

  GroupViewModel({
    required this.groupId,
    required this.name,
    required this.description,
    required this.groupCode,
    required this.walletBalance,
    required this.admin,
    required this.membershipStatus,
    this.pendingJoinRequestsCount = 0,
    this.nextEventDate,
    this.eventStatus,
  });

  factory GroupViewModel.fromGroupMembership(
      QueryDocumentSnapshot<Map<String, dynamic>> membership,
      DocumentSnapshot<Map<String, dynamic>> group,
      DocumentSnapshot<Map<String, dynamic>> member,
      DocumentSnapshot<Map<String, dynamic>>? nextEvent,
      DocumentSnapshot<Map<String, dynamic>>? participant,
      {int pendingJoinRequestsCount = 0}) {
    return GroupViewModel(
      groupId: group.id,
      name: group.data()?['name'] ?? 'Unnamed Group',
      description: group.data()?['description'] ?? '',
      groupCode: group.data()?['groupCode'] ?? '',
      walletBalance: member.data()?['walletBalance'] ?? 0,
      admin: group.data()?['admin'] ?? '',
      membershipStatus: GroupMembershipStatus.member,
      pendingJoinRequestsCount: pendingJoinRequestsCount,
      nextEventDate:
          (nextEvent?.data()?['eventTimestamp'] as Timestamp?)?.toDate(),
      eventStatus: participant?.data()?['status'],
    );
  }

  factory GroupViewModel.fromJoinRequest(
    DocumentSnapshot<Map<String, dynamic>> group,
  ) {
    return GroupViewModel(
      groupId: group.id,
      name: group.data()?['name'] ?? 'Unnamed Group',
      description: group.data()?['description'] ?? '',
      groupCode: group.data()?['groupCode'] ?? '',
      walletBalance: 0,
      admin: group.data()?['admin'] ?? '',
      membershipStatus: GroupMembershipStatus.pending,
    );
  }
}
