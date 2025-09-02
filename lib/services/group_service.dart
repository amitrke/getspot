import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:getspot/models/group_view_model.dart';
import 'dart:developer' as developer;

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

    return _firestore
        .collection('userGroupMemberships')
        .doc(user.uid)
        .collection('groups')
        .snapshots()
        .asyncMap((memberships) async {
      if (memberships.docs.isEmpty) {
        return [];
      }

      final groupIds = memberships.docs.map((doc) => doc.id).toList();

      try {
        final groupsFuture = _firestore
            .collection('groups')
            .where(FieldPath.documentId, whereIn: groupIds)
            .get();

        final eventsFuture = _firestore
            .collection('events')
            .where('groupId', whereIn: groupIds)
            .where('eventTimestamp', isGreaterThan: Timestamp.now())
            .orderBy('eventTimestamp')
            .get();

        final membersFutures = groupIds.map((groupId) => _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(user.uid)
            .get());

        final results = await Future.wait([
          groupsFuture,
          eventsFuture,
          Future.wait(membersFutures),
        ]);

        final groupsSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
        final eventsSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
        final membersSnapshots = results[2] as List<DocumentSnapshot<Map<String, dynamic>>>;

        final groupDocs = {for (var doc in groupsSnapshot.docs) doc.id: doc};
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
            .doc(user.uid)
            .get());

        final participants = await Future.wait(participantFutures);
        final participantDocs = {
          for (var doc in participants)
            if (doc.exists) doc.reference.parent.parent!.id: doc
        };

        final viewModels = <GroupViewModel>[];
        for (var membership in memberships.docs) {
          final groupId = membership.id;
          final group = groupDocs[groupId];
          final member = memberDocs[groupId];
          if (group != null && member != null) {
            final nextEvent = nextEvents[groupId];
            final participant = nextEvent != null ? participantDocs[nextEvent.id] : null;
            viewModels.add(GroupViewModel.fromGroupMembership(
                membership, group, member, nextEvent, participant));
          }
        }
        return viewModels;
      } catch (e, s) {
        developer.log(
          'Error fetching group view models',
          name: 'GroupService',
          error: e,
          stackTrace: s,
        );
        // Re-throw the error to be caught by the StreamBuilder
        throw Exception('Error fetching group data: $e');
      }
    });
  }
}
