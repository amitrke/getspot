import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Provider for managing participant data across multiple events
///
/// This provider eliminates duplicate real-time listeners by sharing
/// participant status data across all event list items. Instead of
/// creating N listeners for N events, we create listeners on-demand
/// and share the data.
///
/// Usage:
/// ```dart
/// final provider = ParticipantProvider(userId: user.uid);
/// provider.subscribeToEvent(eventId);
///
/// // In widget:
/// ListenableBuilder(
///   listenable: provider,
///   builder: (context, child) {
///     final status = provider.getParticipantStatus(eventId);
///     // Build UI using status
///   },
/// )
/// ```
class ParticipantProvider extends ChangeNotifier {
  final String userId;
  final FirebaseFirestore _firestore;

  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _subscriptions = {};
  final Map<String, Map<String, dynamic>?> _participantData = {};

  ParticipantProvider({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get participant status for a specific event
  ///
  /// Returns the participant document data if it exists, null otherwise.
  /// Common fields: status, registeredAt, denialReason, paymentStatus
  Map<String, dynamic>? getParticipantStatus(String eventId) {
    return _participantData[eventId];
  }

  /// Subscribe to participant updates for an event
  ///
  /// Creates a real-time listener if one doesn't already exist.
  /// Multiple calls with the same eventId will reuse the existing listener.
  void subscribeToEvent(String eventId) {
    if (_subscriptions.containsKey(eventId)) {
      developer.log(
        'Already subscribed to event: $eventId',
        name: 'ParticipantProvider',
      );
      return; // Already subscribed
    }

    developer.log(
      'Subscribing to participant data for event: $eventId',
      name: 'ParticipantProvider',
    );

    final stream = _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(userId)
        .snapshots();

    _subscriptions[eventId] = stream.listen(
      (snapshot) {
        if (snapshot.exists) {
          _participantData[eventId] = snapshot.data();
        } else {
          _participantData[eventId] = null;
        }
        notifyListeners();
      },
      onError: (error) {
        developer.log(
          'Error listening to participant data for event: $eventId',
          name: 'ParticipantProvider',
          error: error,
        );
      },
    );
  }

  /// Unsubscribe from an event's participant updates
  ///
  /// Cancels the listener and removes cached data for the event.
  void unsubscribeFromEvent(String eventId) {
    developer.log(
      'Unsubscribing from event: $eventId',
      name: 'ParticipantProvider',
    );

    _subscriptions[eventId]?.cancel();
    _subscriptions.remove(eventId);
    _participantData.remove(eventId);
  }

  /// Unsubscribe from all events
  ///
  /// Useful when navigating away from the event list screen.
  void unsubscribeAll() {
    developer.log(
      'Unsubscribing from all events (${_subscriptions.length} subscriptions)',
      name: 'ParticipantProvider',
    );

    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _participantData.clear();
  }

  /// Get the number of active subscriptions (for debugging)
  int get activeSubscriptions => _subscriptions.length;

  @override
  void dispose() {
    developer.log(
      'Disposing ParticipantProvider, cancelling ${_subscriptions.length} subscriptions',
      name: 'ParticipantProvider',
    );

    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _participantData.clear();
    super.dispose();
  }
}
