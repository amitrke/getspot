import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:getspot/models/group_view_model.dart';
import 'dart:developer' as developer;
import 'package:rxdart/rxdart.dart';

class GroupService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GroupService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<GroupViewModel>> getGroupViewModelsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    final membershipsStream = _firestore
        .collection('userGroupMemberships')
        .doc(user.uid)
        .collection('groups')
        .snapshots();

    final pendingRequestsStream = _firestore
        .collectionGroup('joinRequests')
        .where('uid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return CombineLatestStream.combine2(
      membershipsStream,
      pendingRequestsStream,
      (
        QuerySnapshot<Map<String, dynamic>> memberships,
        QuerySnapshot<Map<String, dynamic>> pendingRequests,
      ) {
        return {'memberships': memberships, 'pendingRequests': pendingRequests};
      },
    ).asyncMap((data) async {
      final memberships =
          data['memberships'] as QuerySnapshot<Map<String, dynamic>>;
      final pendingRequests =
          data['pendingRequests'] as QuerySnapshot<Map<String, dynamic>>;
      return await _combineGroupStreams(memberships, pendingRequests);
    });
  }

  Future<List<GroupViewModel>> _combineGroupStreams(
    QuerySnapshot<Map<String, dynamic>> memberships,
    QuerySnapshot<Map<String, dynamic>> pendingRequests,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final membershipGroupIds = memberships.docs.map((doc) => doc.id).toSet();

    final validPendingRequests = pendingRequests.docs
        .where((doc) {
          final groupId = doc.reference.parent.parent?.id;
          return groupId != null && !membershipGroupIds.contains(groupId);
        })
        .map((doc) => doc.reference.parent.parent!)
        .toList();

    final groupIds = membershipGroupIds.toList();
    final pendingGroupIds = validPendingRequests.map((ref) => ref.id).toList();
    final allGroupIds = [...groupIds, ...pendingGroupIds];

    if (allGroupIds.isEmpty) {
      return [];
    }

    try {
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where(FieldPath.documentId, whereIn: allGroupIds)
          .get();
      final groupDocs = {for (var doc in groupsSnapshot.docs) doc.id: doc};

      final memberViewModels =
          await _fetchMemberViewModels(user.uid, memberships.docs, groupDocs);

      final pendingViewModels = pendingGroupIds
          .map((groupId) {
            final groupDoc = groupDocs[groupId];
            if (groupDoc != null) {
              return GroupViewModel.fromJoinRequest(groupDoc);
            }
            return null;
          })
          .whereType<GroupViewModel>()
          .toList();

      return [...memberViewModels, ...pendingViewModels];
    } catch (e, s) {
      developer.log(
        'Error fetching group view models',
        name: 'GroupService',
        error: e,
        stackTrace: s,
      );
      throw Exception('Error fetching group data: $e');
    }
  }

  Future<List<GroupViewModel>> _fetchMemberViewModels(
    String userId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> memberships,
    Map<String, DocumentSnapshot<Map<String, dynamic>>> groupDocs,
  ) async {
    if (memberships.isEmpty) return [];

    final groupIds = memberships.map((doc) => doc.id).toList();

    // Fetch pending requests count for all groups where the user is a member
    final pendingCountsFutures = groupIds.map((groupId) {
      final groupDoc = groupDocs[groupId];
      // Check if the current user is the admin for this group
      if (groupDoc != null && groupDoc.data()?['admin'] == userId) {
        return getPendingJoinRequestsCountStream(groupId).first;
      }
      // If not admin, return a future with 0
      return Future.value(0);
    }).toList();

    final eventsFuture = _firestore
        .collection('events')
        .where('groupId', whereIn: groupIds)
        .where('status', isEqualTo: 'active')
        .where('eventTimestamp', isGreaterThan: Timestamp.now())
        .orderBy('eventTimestamp')
        .get();

    final membersFutures = groupIds.map((groupId) => _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .get());

    // Await all futures together
    final results = await Future.wait([
      eventsFuture,
      Future.wait(membersFutures),
      Future.wait(pendingCountsFutures),
    ]);

    final eventsSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final membersSnapshots = results[1] as List<DocumentSnapshot<Map<String, dynamic>>>;
    final pendingCounts = results[2] as List<int>;

    final memberDocs = {
      for (var doc in membersSnapshots)
        if (doc.exists) doc.reference.parent.parent!.id: doc
    };

    final nextEvents = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (var event in eventsSnapshot.docs) {
      final groupId = event.data()['groupId'] as String;
      if (!nextEvents.containsKey(groupId)) {
        nextEvents[groupId] = event;
      }
    }

    final participantFutures = nextEvents.values.map((event) => _firestore
        .collection('events')
        .doc(event.id)
        .collection('participants')
        .doc(userId)
        .get());

    final participants = await Future.wait(participantFutures);
    final participantDocs = {
      for (var doc in participants)
        if (doc.exists) doc.reference.parent.parent!.id: doc
    };

    final viewModels = <GroupViewModel>[];
    for (int i = 0; i < memberships.length; i++) {
      final membership = memberships[i];
      final groupId = membership.id;
      final group = groupDocs[groupId];
      final member = memberDocs[groupId];
      if (group != null && member != null) {
        final nextEvent = nextEvents[groupId];
        final participant =
            nextEvent != null ? participantDocs[nextEvent.id] : null;
        viewModels.add(
          GroupViewModel.fromGroupMembership(
            membership,
            group,
            member,
            nextEvent,
            participant,
            pendingJoinRequestsCount: pendingCounts[i],
          ),
        );
      }
    }
    return viewModels;
  }

  Stream<int> getPendingJoinRequestsCountStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
