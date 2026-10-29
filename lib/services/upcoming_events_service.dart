import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:getspot/models/group_view_model.dart';
import 'package:rxdart/rxdart.dart';

/// An upcoming event in one of the user's groups, as shown on Home.
class UpcomingEvent {
  final String id;
  final Map<String, dynamic> data;
  final String groupName;
  final bool isGroupAdmin;

  const UpcomingEvent({
    required this.id,
    required this.data,
    required this.groupName,
    required this.isGroupAdmin,
  });

  String? get name => data['name'] as String?;
  String? get location => data['location'] as String?;
  DateTime? get eventDate => (data['eventTimestamp'] as Timestamp?)?.toDate();
  num get fee => (data['fee'] as num?) ?? 0;
  int get confirmedCount => (data['confirmedCount'] as num?)?.toInt() ?? 0;
  int get maxParticipants => (data['maxParticipants'] as num?)?.toInt() ?? 0;
  int get waitlistCount => (data['waitlistCount'] as num?)?.toInt() ?? 0;
  bool get isFull => maxParticipants > 0 && confirmedCount >= maxParticipants;
}

/// Streams the next upcoming events across all groups the user belongs to,
/// for the Home "Your next games" list.
///
/// Uses the same query shape as GroupService's next-event lookup
/// (groupId in, status == active, eventTimestamp > now, ordered by time), so
/// it is served by the existing events composite index. Firestore caps
/// `whereIn` at 30 values, so larger group lists are queried in chunks and
/// merged client-side.
class UpcomingEventsService {
  static const int _whereInLimit = 30;

  final FirebaseFirestore _firestore;

  UpcomingEventsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<UpcomingEvent>> getUpcomingEventsStream(
    List<GroupViewModel> groups, {
    required String userId,
    int limit = 5,
  }) {
    final memberGroups = {
      for (final g in groups)
        if (g.membershipStatus == GroupMembershipStatus.member) g.groupId: g,
    };
    if (memberGroups.isEmpty) return Stream.value(const []);

    final groupIds = memberGroups.keys.toList();
    final now = Timestamp.now();
    final queries = <Stream<QuerySnapshot<Map<String, dynamic>>>>[
      for (var i = 0; i < groupIds.length; i += _whereInLimit)
        _firestore
            .collection('events')
            .where(
              'groupId',
              whereIn: groupIds.sublist(
                i,
                math.min(i + _whereInLimit, groupIds.length),
              ),
            )
            .where('status', isEqualTo: 'active')
            .where('eventTimestamp', isGreaterThan: now)
            .orderBy('eventTimestamp')
            .limit(limit)
            .snapshots(),
    ];

    return Rx.combineLatestList(queries).map((snapshots) {
      // The query's lower bound is fixed when the stream starts, so drop
      // events that have started since then.
      final cutoff = DateTime.now();
      final events = <UpcomingEvent>[];
      for (final doc in snapshots.expand((s) => s.docs)) {
        final group = memberGroups[doc.data()['groupId']];
        final event = UpcomingEvent(
          id: doc.id,
          data: doc.data(),
          groupName: group?.name ?? '',
          isGroupAdmin: group?.admin == userId,
        );
        final date = event.eventDate;
        if (date == null || date.isAfter(cutoff)) events.add(event);
      }
      final far = DateTime(9999);
      events.sort((a, b) => (a.eventDate ?? far).compareTo(b.eventDate ?? far));
      return events.take(limit).toList();
    });
  }
}
