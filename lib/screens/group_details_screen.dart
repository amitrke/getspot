import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/screens/create_event_screen.dart';
import 'package:getspot/screens/event_details_screen.dart';
import 'package:intl/intl.dart';
import 'package:getspot/screens/group_members_screen.dart';
import 'package:getspot/screens/wallet_screen.dart';
import 'dart:developer' as developer;

class GroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isAdmin = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    final user = FirebaseAuth.instance.currentUser;
    developer.log(
      'Checking admin status. Current User UID: ${user?.uid}, Group Admin UID: ${widget.group['admin']}',
      name: 'GroupDetailsScreen',
    );
    if (user != null && widget.group['admin'] == user.uid) {
      developer.log('Admin status CONFIRMED.', name: 'GroupDetailsScreen');
      setState(() {
        _isAdmin = true;
        _tabController = TabController(length: 3, vsync: this);
      });
    } else {
      developer.log('Admin status DENIED.', name: 'GroupDetailsScreen');
      setState(() {
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
    developer.log('Building GroupDetailsScreen.', name: 'GroupDetailsScreen');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group['name'] ?? 'Group Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _isAdmin
              ? const [
                  Tab(icon: Icon(Icons.event), text: 'Events'),
                  Tab(icon: Icon(Icons.announcement), text: 'Announcements'),
                  Tab(icon: Icon(Icons.person_add), text: 'Admin'),
                ]
              : const [
                  Tab(icon: Icon(Icons.event), text: 'Events'),
                  Tab(icon: Icon(Icons.announcement), text: 'Announcements'),
                ],
        ),
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
            const SizedBox(height: 8),
            Text(
              'Group Code: ${widget.group['groupCode'] ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Divider(),
            Row(
              children: [
                if (_isAdmin) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupMembersScreen(
                            groupId: widget.group['groupId'],
                            adminUid: widget.group['admin'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.group),
                    label: const Text('Members'),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WalletScreen(
                            groupId: widget.group['groupId'],
                            userId: user.uid,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.wallet),
                  label: const Text('My Wallet'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _isAdmin
                    ? [
                        _EventList(groupId: widget.group['groupId']),
                        _AnnouncementsTab(
                          groupId: widget.group['groupId'],
                          isAdmin: _isAdmin,
                        ),
                        _AdminManagementTab(groupId: widget.group['groupId']),
                      ]
                    : [
                        _EventList(groupId: widget.group['groupId']),
                        _AnnouncementsTab(
                          groupId: widget.group['groupId'],
                          isAdmin: _isAdmin,
                        ),
                      ],
              ),
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

class _AnnouncementsTab extends StatefulWidget {
  final String groupId;
  final bool isAdmin;

  const _AnnouncementsTab({required this.groupId, required this.isAdmin});

  @override
  __AnnouncementsTabState createState() => __AnnouncementsTabState();
}

class __AnnouncementsTabState extends State<_AnnouncementsTab> {
  final _announcementController = TextEditingController();
  bool _isPosting = false;

  Future<void> _postAnnouncement() async {
    if (_announcementController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to post an announcement.');
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('announcements')
          .add({
            'content': _announcementController.text.trim(),
            'authorId': user.uid,
            'authorName': user.displayName ?? 'Admin',
            'createdAt': FieldValue.serverTimestamp(),
          });

      _announcementController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting announcement: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isAdmin)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _announcementController,
                    decoration: const InputDecoration(
                      labelText: 'New Announcement',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                _isPosting
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _postAnnouncement,
                      ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .doc(widget.groupId)
                .collection('announcements')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error loading announcements.'),
                );
              }
              final announcements = snapshot.data?.docs ?? [];
              if (announcements.isEmpty) {
                return const Center(child: Text('No announcements yet.'));
              }
              return ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index].data();
                  final createdAt = (announcement['createdAt'] as Timestamp?)
                      ?.toDate();
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 0,
                    ),
                    child: ListTile(
                      title: Text(announcement['content'] ?? ''),
                      subtitle: Text(
                        'Posted by ${announcement['authorName'] ?? 'Admin'} on ${createdAt != null ? DateFormat.yMMMd().format(createdAt) : ''}',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
          .where('status', isEqualTo: 'active')
          .where('eventTimestamp', isGreaterThanOrEqualTo: Timestamp.now())
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
                  return _EventListItem(key: ValueKey(event.id), event: event);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EventListItem extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> event;

  const _EventListItem({super.key, required this.event});

  @override
  State<_EventListItem> createState() => _EventListItemState();
}

class _EventListItemState extends State<_EventListItem> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _participantStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _participantStream = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .collection('participants')
          .doc(user.uid)
          .snapshots();
    }
  }

  Widget _getStatusIcon(String? status) {
    switch (status) {
      case 'confirmed':
        return const Icon(Icons.check_circle, color: Colors.green, size: 16);
      case 'waitlisted':
        return const Icon(Icons.pending, color: Colors.orange, size: 16);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventData = widget.event.data();
    final eventTimestamp = eventData['eventTimestamp'] as Timestamp?;
    final formattedDate = eventTimestamp != null
        ? DateFormat.yMMMEd().add_jm().format(eventTimestamp.toDate())
        : 'No date';

    return Card(
      child: ListTile(
        title: Text(eventData['name'] ?? 'Unnamed Event'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(eventData['location'] ?? 'No location'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(formattedDate),
              ],
            ),
            const SizedBox(height: 4),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _participantStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text('Not Registered'),
                    ],
                  );
                }
                final status = snapshot.data!.data()?['status'] as String?;
                return Row(
                  children: [
                    _getStatusIcon(status),
                    const SizedBox(width: 4),
                    Text(
                      status != null
                          ? '${status[0].toUpperCase()}${status.substring(1)}'
                          : 'Not Registered',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  EventDetailsScreen(eventId: widget.event.id),
            ),
          );
        },
      ),
    );
  }
}

class _AdminManagementTab extends StatelessWidget {
  final String groupId;
  const _AdminManagementTab({required this.groupId});

  @override
  Widget build(BuildContext context) {
    developer.log(
      'Building _AdminManagementTab with groupId: "$groupId"',
      name: 'GroupDetailsScreen',
    );
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

  const _JoinRequestsList({
    required this.groupId,
    required this.status,
    required this.title,
  });

  @override
  State<_JoinRequestsList> createState() => _JoinRequestsListState();
}

class _JoinRequestsListState extends State<_JoinRequestsList> {
  // Use a map to track loading state for individual items
  final Map<String, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    developer.log(
      'Initializing _JoinRequestsListState for status "${widget.status}"',
      name: 'GroupDetailsScreen',
    );
  }

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
    final query = FirebaseFirestore.instance
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
          developer.log(
            'Error fetching join requests for status "${widget.status}"',
            name: 'GroupDetailsScreen',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return Center(
            child: Text(
              'Error loading ${widget.title}.\nCheck console for details.',
            ),
          );
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
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('Delete'),
      );
    }
  }
}
