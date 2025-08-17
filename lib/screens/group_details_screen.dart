import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/screens/create_event_screen.dart';
import 'package:getspot/screens/event_details_screen.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class GroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isAdmin = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.group['admin'] == user.uid) {
      setState(() {
        _isAdmin = true;
        _tabController = TabController(length: 2, vsync: this);
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group['name'] ?? 'Group Details'),
        bottom: _isAdmin
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.event), text: 'Events'),
                  Tab(
                      icon: Icon(Icons.person_add),
                      text: 'Admin'), // Changed tab name
                ],
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group['name'] ?? 'Unnamed Group',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.group['description'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Divider(),
            // Show TabBarView for Admin, or just the EventList for members
            Expanded(
              child: _isAdmin
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _EventList(groupId: widget.group['groupId']),
                        _AdminManagementTab(
                            groupId: widget.group['groupId']), // New widget
                      ],
                    )
                  : _EventList(groupId: widget.group['groupId']),
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateEventScreen(groupId: widget.group['groupId']),
                  ),
                );
              },
              label: const Text('Create Event'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _EventList extends StatelessWidget {
  final String groupId;

  const _EventList({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('groupId', isEqualTo: groupId)
          .orderBy('eventTimestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          developer.log(
            'Error loading events',
            name: 'EventList',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return const Center(child: Text('Error loading events.'));
        }

        final events = snapshot.data?.docs ?? [];

        if (events.isEmpty) {
          return const Center(child: Text('No upcoming events.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Upcoming Events',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final eventData = event.data();
                  final eventTimestamp =
                      eventData['eventTimestamp'] as Timestamp?;
                  final formattedDate = eventTimestamp != null
                      ? DateFormat.yMMMd()
                          .add_jm()
                          .format(eventTimestamp.toDate())
                      : 'No date';

                  return Card(
                    child: ListTile(
                      title: Text(eventData['name'] ?? 'Unnamed Event'),
                      subtitle:
                          Text('${eventData['location']}\n$formattedDate'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                EventDetailsScreen(eventId: event.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminManagementTab extends StatelessWidget {
  final String groupId;
  const _AdminManagementTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _JoinRequestsList(
          groupId: groupId,
          status: 'pending',
          title: 'Pending Requests',
        ),
        const SizedBox(height: 24),
        _JoinRequestsList(
          groupId: groupId,
          status: 'denied',
          title: 'Denied Requests',
        ),
      ],
    );
  }
}

class _JoinRequestsList extends StatefulWidget {
  final String groupId;
  final String status;
  final String title;

  const _JoinRequestsList(
      {required this.groupId, required this.status, required this.title});

  @override
  State<_JoinRequestsList> createState() => _JoinRequestsListState();
}

class _JoinRequestsListState extends State<_JoinRequestsList> {
  // Use a map to track loading state for individual items
  final Map<String, bool> _loadingStates = {};

  Future<void> _processRequest(String requestedUserId, String action) async {
    setState(() {
      _loadingStates[requestedUserId] = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('manageJoinRequest');
      await callable.call({
        'groupId': widget.groupId,
        'requestedUserId': requestedUserId,
        'action': action,
      });
      // No need to show a success message, the list will update automatically
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An unknown error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
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
          _loadingStates[requestedUserId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firestore query now filters by the 'status' field.
    // For the initial implementation, we assume pending requests have no status field.
    final query = widget.status == 'pending'
        ? FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('joinRequests')
            .where('status', isNull: true)
        : FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('joinRequests')
            .where('status', isEqualTo: widget.status);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading ${widget.title}.'));
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Card(
            child: ListTile(
              title: Text(widget.title),
              subtitle: const Text('No requests.'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListView.builder(
              shrinkWrap: true, // Important for nested lists
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling for the inner list
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final requestData = request.data();
                final isLoading = _loadingStates[request.id] ?? false;

                return Card(
                  child: ListTile(
                    title: Text(requestData['displayName'] ?? 'No Name'),
                    trailing: isLoading
                        ? const CircularProgressIndicator()
                        : _buildActionButtons(request.id),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(String requestedUserId) {
    if (widget.status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _processRequest(requestedUserId, 'approve'),
            child: const Text('Approve'),
          ),
          TextButton(
            onPressed: () => _processRequest(requestedUserId, 'deny'),
            child: const Text('Deny'),
          ),
        ],
      );
    } else {
      // Denied status
      return TextButton(
        onPressed: () => _processRequest(requestedUserId, 'delete'),
        style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error),
        child: const Text('Delete'),
      );
    }
  }
}

