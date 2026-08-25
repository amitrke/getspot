import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/screens/create_event_screen.dart';
import 'package:getspot/screens/event_details_screen.dart';
import 'package:getspot/providers/participant_provider.dart';
import 'package:getspot/services/group_cache_service.dart';
import 'package:getspot/services/user_cache_service.dart';
import 'package:getspot/services/event_cache_service.dart';
import 'package:getspot/services/announcement_cache_service.dart';
import 'package:getspot/services/analytics_service.dart';
import 'package:intl/intl.dart';
import 'package:getspot/screens/group_members_screen.dart';
import 'package:getspot/screens/wallet_screen.dart';
import 'package:share_plus/share_plus.dart';
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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _handleRefresh() async {
    developer.log('Pull-to-refresh triggered on Group Details Screen', name: 'GroupDetailsScreen');

    final groupId = widget.group['groupId'];

    // Invalidate caches for this specific group
    GroupCacheService().invalidate(groupId);
    EventCacheService().invalidate(groupId);
    AnnouncementCacheService().invalidate(groupId);
    // Clear user cache to refresh member display names and photos
    UserCacheService().clear();

    // Wait a bit to allow the stream to pick up fresh data
    await Future.delayed(const Duration(milliseconds: 500));

    developer.log('All caches invalidated for group $groupId', name: 'GroupDetailsScreen');
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
        _tabController!.addListener(() {
          // Rebuild to show/hide FAB when tab changes
          setState(() {});
        });
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

  void _copyGroupCode() {
    final l10n = AppLocalizations.of(context)!;
    final code = widget.group['groupCode'] as String?;
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupDetailsCodeUnavailableSnackbar)),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.groupDetailsCodeCopiedSnackbar(code))),
    );
  }

  Future<void> _shareGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final code = widget.group['groupCode'] as String?;
    final name = widget.group['name'] as String?;
    final description = widget.group['description'] as String?;

    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupDetailsCodeUnavailableSnackbar)),
      );
      return;
    }

    // Create the deep link URL
    final deepLink = 'https://app.getspot.org/join/$code';

    // Build share message
    final StringBuffer messageBuffer = StringBuffer();
    messageBuffer.writeln(l10n.groupDetailsShareInviteText);
    messageBuffer.writeln();
    if (name != null && name.isNotEmpty) {
      messageBuffer.writeln(l10n.groupDetailsShareGroupLabel(name));
    }
    if (description != null && description.isNotEmpty) {
      messageBuffer.writeln(description);
    }
    messageBuffer.writeln();
    messageBuffer.writeln(l10n.groupDetailsShareTapToJoin(deepLink));
    messageBuffer.writeln();
    messageBuffer.writeln(l10n.groupDetailsShareUseCode(code));
    final String message = messageBuffer.toString();

    try {
      // Get the share button position for iPad popover
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: l10n.groupDetailsShareSubject(name ?? l10n.groupDetailsShareFallbackName),
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      developer.log('Group shared successfully', name: 'GroupDetailsScreen');
    } catch (e) {
      developer.log('Error sharing group', name: 'GroupDetailsScreen', error: e);
      if (!mounted) return;

      if (kIsWeb) {
        // The Web Share API isn't available in every browser (e.g. Firefox,
        // or non-HTTPS/localhost contexts), so fall back to copying the
        // invite text instead of just showing an error.
        await Clipboard.setData(ClipboardData(text: message));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.groupDetailsSharingNotSupported),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.groupDetailsErrorSharing(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final groupName = widget.group['name'] ?? l10n.groupDetailsFallbackGroupNameGeneric;
    final groupId = widget.group['groupId'] as String?;
    final user = FirebaseAuth.instance.currentUser;
    if (groupId == null || user == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.groupDetailsLeaveConfirmTitle(groupName)),
            content: Text(l10n.groupDetailsLeaveConfirmContent),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.groupDetailsLeaveButton)),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('manageGroupMember');
      await callable.call({
        'groupId': groupId,
        'targetUserId': user.uid,
        'action': 'leave',
      });

      developer.log('Left group successfully', name: 'GroupDetailsScreen');
      GroupCacheService().invalidate(groupId);
      await AnalyticsService().logLeaveGroup();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupDetailsLeftGroupSnackbar(groupName))),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      developer.log('Error leaving group', name: 'GroupDetailsScreen', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? l10n.groupDetailsCouldNotLeave),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      developer.log('Error leaving group', name: 'GroupDetailsScreen', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.groupDetailsErrorLeaving(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Building GroupDetailsScreen.', name: 'GroupDetailsScreen');
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group['name'] ?? l10n.groupDetailsFallbackTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.groupDetailsShareTooltip,
            onPressed: _shareGroup,
          ),
          if (!_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'leave') _leaveGroup();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'leave',
                  child: Text(l10n.groupDetailsLeaveGroupMenuItem),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _isAdmin
              ? [
                  Tab(icon: const Icon(Icons.event), text: l10n.groupDetailsEventsTab),
                  Tab(icon: const Icon(Icons.announcement), text: l10n.groupDetailsAnnouncementsTab),
                  Tab(icon: const Icon(Icons.person_add), text: l10n.groupDetailsAdminTab),
                ]
              : [
                  Tab(icon: const Icon(Icons.event), text: l10n.groupDetailsEventsTab),
                  Tab(icon: const Icon(Icons.announcement), text: l10n.groupDetailsAnnouncementsTab),
                ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   widget.group['name'] ?? 'Unnamed Group',
              //   style: Theme.of(context).textTheme.headlineSmall,
              // ),
              const SizedBox(height: 8),
              Text(
                widget.group['description'] ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              if ((widget.group['groupCode'] as String?)?.isNotEmpty ?? false)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.groupDetailsCodeLabel(widget.group['groupCode']),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: l10n.groupDetailsCopyCodeTooltip,
                        onPressed: _copyGroupCode,
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  l10n.groupDetailsCodeUnavailableText,
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
                      label: Text(l10n.groupDetailsMembersButton),
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
                    label: Text(l10n.groupDetailsMyWalletButton),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _handleRefresh,
                  child: TabBarView(
                    controller: _tabController,
                    children: _isAdmin
                        ? [
                            _EventList(
                              groupId: widget.group['groupId'],
                              isAdmin: _isAdmin,
                            ),
                            _AnnouncementsTab(
                              groupId: widget.group['groupId'],
                              isAdmin: _isAdmin,
                            ),
                            _AdminManagementTab(groupId: widget.group['groupId']),
                          ]
                        : [
                            _EventList(
                              groupId: widget.group['groupId'],
                              isAdmin: _isAdmin,
                            ),
                            _AnnouncementsTab(
                              groupId: widget.group['groupId'],
                              isAdmin: _isAdmin,
                            ),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isAdmin && (_tabController?.index == 0)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateEventScreen(groupId: widget.group['groupId']),
                  ),
                );
              },
              label: Text(l10n.groupDetailsCreateEventButton),
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
        throw Exception(AppLocalizations.of(context)!.groupDetailsMustBeLoggedInAnnouncement);
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('announcements')
          .add({
            'content': _announcementController.text.trim(),
            'authorId': user.uid,
            'authorName': user.displayName ?? AppLocalizations.of(context)!.groupDetailsAdminAuthorFallback,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Invalidate announcement cache to ensure fresh data
      // (Real-time stream will update, but invalidation ensures consistency)
      AnnouncementCacheService().invalidate(widget.groupId);

      _announcementController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.groupDetailsErrorPostingAnnouncement(e.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside the TextField
        FocusScope.of(context).unfocus();
      },
      child: Column(
        children: [
          if (widget.isAdmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _announcementController,
                      decoration: InputDecoration(
                        labelText: l10n.groupDetailsNewAnnouncementLabel,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        // Dismiss keyboard when user presses "Done" on keyboard
                        FocusScope.of(context).unfocus();
                        _postAnnouncement();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isPosting
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            // Dismiss keyboard before posting
                            FocusScope.of(context).unfocus();
                            _postAnnouncement();
                          },
                        ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<CachedAnnouncement>>(
              stream: AnnouncementCacheService().getAnnouncementsStream(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(l10n.groupDetailsErrorLoadingAnnouncements),
                  );
                }
                final announcements = snapshot.data ?? [];
                if (announcements.isEmpty) {
                  return Center(child: Text(l10n.groupDetailsNoAnnouncementsYet));
                }
                final locale = Localizations.localeOf(context).toString();
                return ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    final createdAt = announcement.createdAt;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 0,
                      ),
                      child: ListTile(
                        title: Text(announcement.content),
                        subtitle: Text(
                          l10n.groupDetailsPostedBy(
                            announcement.authorName ?? l10n.groupDetailsAdminAuthorFallback,
                            createdAt != null ? DateFormat.yMMMd(locale).format(createdAt) : '',
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventList extends StatefulWidget {
  final String groupId;
  final bool isAdmin;

  const _EventList({required this.groupId, required this.isAdmin});

  @override
  State<_EventList> createState() => _EventListState();
}

class _EventListState extends State<_EventList> {
  ParticipantProvider? _participantProvider;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _participantProvider = ParticipantProvider(userId: user.uid);
    }
  }

  @override
  void dispose() {
    _participantProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eventCache = EventCacheService();

    return StreamBuilder<List<CachedEvent>>(
      stream: eventCache.getEventsStream(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          developer.log(
            'Error loading events',
            name: 'EventList',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return Center(child: Text(l10n.groupDetailsErrorLoadingEvents));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(child: Text(l10n.groupItemNoUpcomingEvents));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                l10n.groupDetailsUpcomingEventsHeader,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Semantics(
                    label: 'event_item_$index',
                    child: _EventListItem(
                      key: ValueKey(event.id),
                      eventId: event.id,
                      eventData: event.toMap(),
                      isAdmin: widget.isAdmin,
                      participantProvider: _participantProvider,
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

class _EventListItem extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final bool isAdmin;
  final ParticipantProvider? participantProvider;

  const _EventListItem({
    super.key,
    required this.eventId,
    required this.eventData,
    required this.isAdmin,
    this.participantProvider,
  });

  @override
  State<_EventListItem> createState() => _EventListItemState();
}

class _EventListItemState extends State<_EventListItem> {
  @override
  void initState() {
    super.initState();
    // Subscribe to participant updates for this event
    widget.participantProvider?.subscribeToEvent(widget.eventId);
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

  String _statusLabel(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'confirmed':
        return l10n.groupItemStatusConfirmed;
      case 'waitlisted':
        return l10n.groupItemStatusWaitlisted;
      case 'denied':
        return l10n.groupItemStatusDenied;
      default:
        return l10n.groupItemStatusNotRegistered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final eventData = widget.eventData;
    final eventTimestamp = eventData['eventTimestamp'] as Timestamp?;
    final formattedDate = eventTimestamp != null
        ? DateFormat.yMMMEd(locale).add_jm().format(eventTimestamp.toDate())
        : l10n.groupDetailsNoDate;

    return Card(
      child: ListTile(
        title: Text(eventData['name'] ?? l10n.groupDetailsUnnamedEvent),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(eventData['location'] ?? l10n.groupDetailsNoLocation),
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
            widget.participantProvider != null
                ? ListenableBuilder(
                    listenable: widget.participantProvider!,
                    builder: (context, child) {
                      final participantData = widget.participantProvider!
                          .getParticipantStatus(widget.eventId);
                      final status = participantData?['status'] as String?;

                      if (participantData == null) {
                        return Row(
                          children: [
                            const Icon(Icons.help_outline,
                                color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Text(l10n.groupItemStatusNotRegistered),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          _getStatusIcon(status),
                          const SizedBox(width: 4),
                          Text(_statusLabel(l10n, status)),
                        ],
                      );
                    },
                  )
                : Row(
                    children: [
                      const Icon(Icons.help_outline, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(l10n.groupItemStatusNotRegistered),
                    ],
                  ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(
                eventId: widget.eventId,
                isGroupAdmin: widget.isAdmin,
              ),
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
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      children: [
        _JoinRequestsList(
          groupId: groupId,
          status: 'pending',
          title: l10n.groupDetailsPendingRequestsTitle,
        ),
        const SizedBox(height: 24),
        _JoinRequestsList(
          groupId: groupId,
          status: 'denied',
          title: l10n.groupDetailsDeniedRequestsTitle,
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
            content: Text(e.message ?? AppLocalizations.of(context)!.createGroupUnknownError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.createGroupUnexpectedError),
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.groupDetailsErrorLoadingList(widget.title),
            ),
          );
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Card(
            child: ListTile(
              title: Text(widget.title),
              subtitle: Text(l10n.groupDetailsNoRequests),
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
                    title: Text(requestData['displayName'] ?? l10n.commonNoName),
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
    final l10n = AppLocalizations.of(context)!;
    if (widget.status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _processRequest(requestedUserId, 'approve'),
            child: Text(l10n.groupDetailsApproveButton),
          ),
          TextButton(
            onPressed: () => _processRequest(requestedUserId, 'deny'),
            child: Text(l10n.groupDetailsDenyButton),
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
        child: Text(l10n.profileDeleteButton),
      );
    }
  }
}
