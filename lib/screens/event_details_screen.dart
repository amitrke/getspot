import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final bool isGroupAdmin;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.isGroupAdmin = false,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isRegistering = false;
  bool _isWithdrawing = false;
  bool _isCancelling = false;
  bool _isUpdatingCapacity = false;

  bool get _isAdmin => widget.isGroupAdmin;

  @override
  void initState() {
    super.initState();
    // No longer need to fetch admin status - it's passed as a parameter
  }

  Future<void> _registerForEvent() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to register.');
      }

      final participantRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('participants')
          .doc(user.uid);

      await participantRef.set({
        'uid': user.uid,
        'displayName': user.displayName ?? 'No Name',
        'photoURL': user.photoURL, // Add this line
        'status': 'requested',
        'registeredAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your registration request has been submitted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Error registering for event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _withdrawFromEvent() async {
    setState(() {
      _isWithdrawing = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('withdrawFromEvent');
      final result = await callable.call({'eventId': widget.eventId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? 'Withdrawal successful.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e, st) {
      developer.log(
        'Error withdrawing from event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An unknown error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Generic error withdrawing from event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }
  }

  Future<void> _cancelEvent() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('cancelEvent');
      final result = await callable.call({'eventId': widget.eventId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? 'Event cancelled successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e, st) {
      developer.log(
        'Error cancelling event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An unknown error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Generic error cancelling event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Future<void> _updateEventCapacity(int newCapacity) async {
    setState(() {
      _isUpdatingCapacity = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('updateEventCapacity');
      final result = await callable.call({
        'eventId': widget.eventId,
        'newMaxParticipants': newCapacity,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? 'Capacity updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e, st) {
      developer.log(
        'Error updating event capacity',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An unknown error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Generic error updating event capacity',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingCapacity = false;
        });
      }
    }
  }

  void _showUpdateCapacityDialog(Map<String, dynamic> eventData) {
    final currentCapacity = eventData['maxParticipants'] ?? 0;
    final confirmedCount = eventData['confirmedCount'] ?? 0;
    final waitlistCount = eventData['waitlistCount'] ?? 0;
    final capacityController = TextEditingController(text: currentCapacity.toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Update Event Capacity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current capacity: $currentCapacity'),
              Text('Confirmed participants: $confirmedCount'),
              Text('Waitlisted participants: $waitlistCount'),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Capacity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Cannot reduce below $confirmedCount (current confirmed count)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () {
                final newCapacity = int.tryParse(capacityController.text);
                if (newCapacity == null || newCapacity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a valid positive number.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                _showConfirmCapacityChangeDialog(
                  currentCapacity,
                  newCapacity,
                  confirmedCount,
                  waitlistCount,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmCapacityChangeDialog(
    int oldCapacity,
    int newCapacity,
    int confirmedCount,
    int waitlistCount,
  ) {
    final isIncreasing = newCapacity > oldCapacity;
    final change = (newCapacity - oldCapacity).abs();

    String message;
    if (isIncreasing) {
      final canPromote = math.min(change, waitlistCount);
      if (canPromote > 0) {
        message = 'Increasing capacity by $change spots.\n\n'
            '$canPromote user(s) will be automatically promoted from the waitlist.\n\n'
            'Continue?';
      } else {
        message = 'Increasing capacity by $change spots.\n\n'
            'No waitlisted users to promote.\n\n'
            'Continue?';
      }
    } else {
      message = 'Decreasing capacity by $change spots (from $oldCapacity to $newCapacity).\n\n'
          'This will not affect current confirmed participants.\n\n'
          'Continue?';
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Capacity Change'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _updateEventCapacity(newCapacity);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text(
              'Are you sure you want to cancel this event? This action is irreversible and will refund all registered participants.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm Cancellation'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelEvent();
              },
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawConfirmationDialog(Map<String, dynamic> eventData) {
    final deadlineTimestamp = eventData['commitmentDeadline'] as Timestamp?;
    bool isAfterDeadline = false;
    if (deadlineTimestamp != null) {
      isAfterDeadline = DateTime.now().isAfter(deadlineTimestamp.toDate());
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: Text(isAfterDeadline
              ? 'The commitment deadline has passed. If you withdraw now, your fee may be forfeited unless someone from the waitlist takes your spot. Are you sure you want to withdraw?'
              : 'Are you sure you want to withdraw from this event?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Withdraw'),
              onPressed: () {
                Navigator.of(context).pop();
                _withdrawFromEvent();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading event details.'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Event not found.'));
            }

            final event = snapshot.data!.data()!;
            final eventTimestamp = event['eventTimestamp'] as Timestamp?;
            final deadlineTimestamp = event['commitmentDeadline'] as Timestamp?;
            final isCancelled = event['status'] == 'cancelled';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCancelled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'Event Cancelled',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isCancelled) const SizedBox(height: 16),
                  Text(
                    event['name'] ?? 'Unnamed Event',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: event['location'] ?? 'No location set',
                  ),
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    label: 'Time',
                    value: eventTimestamp != null
                        ? DateFormat.yMMMd()
                            .add_jm()
                            .format(eventTimestamp.toDate())
                        : 'No date set',
                  ),
                  _buildDetailRow(
                    icon: Icons.attach_money,
                    label: 'Fee',
                    value: '${event['fee'] ?? 0} credits',
                  ),
                  _buildDetailRow(
                    icon: Icons.timer,
                    label: 'Commitment Deadline',
                    value: deadlineTimestamp != null
                        ? DateFormat.yMMMd()
                            .add_jm()
                            .format(deadlineTimestamp.toDate())
                        : 'No deadline set',
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  if (_isAdmin && !isCancelled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Event Capacity Management',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ElevatedButton.icon(
                            onPressed: _isUpdatingCapacity
                                ? null
                                : () => _showUpdateCapacityDialog(event),
                            icon: _isUpdatingCapacity
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.edit, size: 18),
                            label: const Text('Update Capacity'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildParticipantList(
                          title:
                              'Confirmed (${event['confirmedCount'] ?? 0}/${event['maxParticipants'] ?? 'N/A'})',
                          status: 'confirmed',
                        ),
                        const SizedBox(height: 16),
                        _buildParticipantList(
                          title: 'Waitlist (${event['waitlistCount'] ?? 0})',
                          status: 'waitlisted',
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(event),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticipantList({required String title, required String status}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('participants')
              .where('status', isEqualTo: status)
              .orderBy('registeredAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text('Error loading participants.');
            }
            final participants = snapshot.data?.docs ?? [];
            if (participants.isEmpty) {
              return const Text('No participants in this list yet.');
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index].data();
                final photoUrl = participant['photoURL'] as String?;
                final displayName = participant['displayName'] ?? 'No Name';
                final uid = participant['uid'] as String?;

                return Semantics(
                  label: 'participant_item_${uid ?? index}',
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(displayName.isNotEmpty ? displayName[0] : '?')
                          : null,
                    ),
                    title: Text(displayName),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(Map<String, dynamic> eventData) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final isCancelled = eventData['status'] == 'cancelled';

    List<Widget> buttons = [];

    if (_isAdmin && !isCancelled) {
      buttons.add(
        Semantics(
          label: 'cancel_event_button',
          child: ElevatedButton(
            onPressed: _isCancelling ? null : _showCancelConfirmationDialog,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: _isCancelling
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Cancel Event'),
          ),
        ),
      );
    }

    if (isCancelled) {
      buttons.add(
        const ElevatedButton(
          onPressed: null,
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.grey),
          ),
          child: Text('Event Cancelled'),
        ),
      );
    } else {
      buttons.add(
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('participants')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final registrationData = snapshot.data;
            final status = registrationData?.data()?['status'] as String?;

            Widget button;
            if (status == 'confirmed' || status == 'waitlisted') {
              button = Semantics(
                label: 'withdraw_button',
                child: ElevatedButton(
                  onPressed: _isWithdrawing
                      ? null
                      : () => _showWithdrawConfirmationDialog(eventData),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: _isWithdrawing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Withdraw'),
                ),
              );
            } else if (status == null || status == 'withdrawn') {
              button = Semantics(
                label: 'register_button',
                child: ElevatedButton(
                  onPressed: _isRegistering ? null : _registerForEvent,
                  child: _isRegistering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register'),
                ),
              );
            } else { // Handles withdrawn_penalty, requested, etc.
              button = ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: Text('Your status: ${status[0].toUpperCase()}${status.substring(1)}'),
              );
            }
            return button;
          },
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons
            .map((b) => Padding(padding: const EdgeInsets.only(top: 8.0), child: b))
            .toList(),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
