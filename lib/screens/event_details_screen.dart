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

  Future<void> _showRegistrationConfirmationDialog(Map<String, dynamic> eventData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch user's wallet balance from the group
      final groupId = eventData['groupId'] as String;
      final fee = (eventData['fee'] as num?)?.toDouble() ?? 0.0;

      final memberDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(user.uid)
          .get();

      if (!memberDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You are not a member of this group.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      final walletBalance = (memberDoc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = walletBalance - fee;

      // Fetch group's negative balance limit
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      final negativeBalanceLimit = (groupDoc.data()?['negativeBalanceLimit'] as num?)?.toDouble() ?? 0.0;

      // Check if event is full
      final confirmedCount = eventData['confirmedCount'] ?? 0;
      final maxParticipants = eventData['maxParticipants'] ?? 0;
      final isFull = confirmedCount >= maxParticipants;

      if (!mounted) return;

      // Show appropriate dialog
      if (isFull) {
        _showWaitlistConfirmationDialog(
          eventData: eventData,
          fee: fee,
          currentBalance: walletBalance,
          newBalance: newBalance,
        );
      } else if (newBalance < -negativeBalanceLimit) {
        // Insufficient balance
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Insufficient Balance'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Balance: \$${walletBalance.toStringAsFixed(2)}'),
                  Text('Event Fee: \$${fee.toStringAsFixed(2)}'),
                  Text('New Balance: \$${newBalance.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  Text('Allowed Negative Limit: \$${negativeBalanceLimit.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  const Text(
                    'You do not have sufficient balance to register for this event. Please contact your group admin to add funds.',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else if (newBalance < 0) {
        // Balance will be negative but within limit
        _showNegativeBalanceConfirmationDialog(
          eventData: eventData,
          fee: fee,
          currentBalance: walletBalance,
          newBalance: newBalance,
          negativeLimit: negativeBalanceLimit,
        );
      } else {
        // Normal registration
        _showNormalRegistrationDialog(
          eventData: eventData,
          fee: fee,
          currentBalance: walletBalance,
          newBalance: newBalance,
        );
      }
    } catch (e, st) {
      developer.log(
        'Error showing registration dialog',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showNormalRegistrationDialog({
    required Map<String, dynamic> eventData,
    required double fee,
    required double currentBalance,
    required double newBalance,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Register for Event?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventData['name'] ?? 'Event',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text('Event Fee: \$${fee.toStringAsFixed(2)}'),
              const Divider(height: 24),
              Text('Current Balance: \$${currentBalance.toStringAsFixed(2)}'),
              Text(
                'New Balance: \$${newBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registerForEvent();
              },
              child: const Text('Confirm Registration'),
            ),
          ],
        );
      },
    );
  }

  void _showNegativeBalanceConfirmationDialog({
    required Map<String, dynamic> eventData,
    required double fee,
    required double currentBalance,
    required double newBalance,
    required double negativeLimit,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Low Balance Warning'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventData['name'] ?? 'Event',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text('Event Fee: \$${fee.toStringAsFixed(2)}'),
              const Divider(height: 24),
              Text('Current Balance: \$${currentBalance.toStringAsFixed(2)}'),
              Text(
                'New Balance: \$${newBalance.toStringAsFixed(2)} (negative)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              Text('Allowed Limit: \$${negativeLimit.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text(
                'You\'ll have a negative balance after registration. Please coordinate payment with your group admin.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registerForEvent();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('I Understand, Register'),
            ),
          ],
        );
      },
    );
  }

  void _showWaitlistConfirmationDialog({
    required Map<String, dynamic> eventData,
    required double fee,
    required double currentBalance,
    required double newBalance,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.list, color: Colors.blue),
              SizedBox(width: 8),
              Text('Join Waitlist?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This event is full. You\'ll be added to the waitlist.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Fee: \$${fee.toStringAsFixed(2)} (charged now, refunded if not confirmed)'),
              const Divider(height: 24),
              Text('Current Balance: \$${currentBalance.toStringAsFixed(2)}'),
              Text(
                'New Balance: \$${newBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'You\'ll be automatically confirmed if a spot opens.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registerForEvent();
              },
              child: const Text('Join Waitlist'),
            ),
          ],
        );
      },
    );
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
        'photoURL': user.photoURL,
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
    final fee = (eventData['fee'] as num?)?.toDouble() ?? 0.0;
    bool isAfterDeadline = false;

    if (deadlineTimestamp != null) {
      isAfterDeadline = DateTime.now().isAfter(deadlineTimestamp.toDate());
    }

    String refundInfo;
    Color refundColor;
    IconData refundIcon;

    if (isAfterDeadline) {
      refundInfo = 'Refund: May be forfeited (depends on waitlist)';
      refundColor = Colors.orange;
      refundIcon = Icons.warning;
    } else {
      refundInfo = 'Refund: \$${fee.toStringAsFixed(2)} (full refund)';
      refundColor = Colors.green;
      refundIcon = Icons.check_circle;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventData['name'] ?? 'Event',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text('Event Fee: \$${fee.toStringAsFixed(2)}'),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(refundIcon, color: refundColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      refundInfo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: refundColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (deadlineTimestamp != null) ...[
                Text(
                  'Commitment Deadline: ${DateFormat.yMMMd().add_jm().format(deadlineTimestamp.toDate())}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                isAfterDeadline
                    ? 'The commitment deadline has passed. If you withdraw now, your fee will only be refunded if someone from the waitlist takes your spot.'
                    : 'You are withdrawing before the commitment deadline. You will receive a full refund of your fee.',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAfterDeadline ? Colors.orange : Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _withdrawFromEvent();
              },
              child: const Text('Confirm Withdrawal'),
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
                  const SizedBox(height: 12),
                  _buildCompactDetailRow(
                    icon: Icons.location_on,
                    value: event['location'] ?? 'No location set',
                  ),
                  _buildCompactDetailRow(
                    icon: Icons.calendar_today,
                    value: eventTimestamp != null
                        ? DateFormat.yMMMd()
                            .add_jm()
                            .format(eventTimestamp.toDate())
                        : 'No date set',
                  ),
                  _buildCompactDetailRow(
                    icon: Icons.attach_money,
                    value: '${event['fee'] ?? 0} credits',
                  ),
                  _buildCompactDetailRow(
                    icon: Icons.timer,
                    value: deadlineTimestamp != null
                        ? DateFormat.yMMMd()
                            .add_jm()
                            .format(deadlineTimestamp.toDate())
                        : 'No deadline',
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildParticipantList(
                          title:
                              'Confirmed (${event['confirmedCount'] ?? 0}/${event['maxParticipants'] ?? 'N/A'})',
                          status: 'confirmed',
                          showUpdateButton: _isAdmin && !isCancelled,
                          onUpdatePressed: () => _showUpdateCapacityDialog(event),
                          isUpdating: _isUpdatingCapacity,
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

  Widget _buildParticipantList({
    required String title,
    required String status,
    bool showUpdateButton = false,
    VoidCallback? onUpdatePressed,
    bool isUpdating = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (showUpdateButton)
              ElevatedButton.icon(
                onPressed: isUpdating ? null : onUpdatePressed,
                icon: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
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
                  onPressed: _isRegistering ? null : () => _showRegistrationConfirmationDialog(eventData),
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

  Widget _buildCompactDetailRow({
    required IconData icon,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
