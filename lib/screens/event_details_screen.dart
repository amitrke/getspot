import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isRegistering = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _buildRegistrationButton(),
              ],
            ),
          );
        },
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
                return ListTile(
                  leading: CircleAvatar(
                    child: Text((index + 1).toString()),
                  ),
                  title: Text(participant['displayName'] ?? 'No Name'),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRegistrationButton() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
        if (status != null) {
          button = ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: Text('Your status: ${status[0].toUpperCase()}${status.substring(1)}'),
          );
        } else {
          button = ElevatedButton(
            onPressed: _isRegistering ? null : _registerForEvent,
            child: _isRegistering
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Register'),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: button,
        );
      },
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