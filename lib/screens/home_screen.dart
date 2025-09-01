import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:getspot/models/group_view_model.dart';

import 'package:getspot/screens/member_profile_screen.dart';
import 'package:getspot/widgets/group_list_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _CreateGroupModal(),
    );
  }

  void _openJoinGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _JoinGroupModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log(
      'HomeScreen build method executed. Logging should be working.',
      name: 'HomeScreen',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MemberProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const _GroupList(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _openJoinGroupModal(context),
                child: const Text('Join a Group'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _openCreateGroupModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create a Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupList extends StatefulWidget {
  const _GroupList();

  @override
  State<_GroupList> createState() => _GroupListState();
}

class _GroupListState extends State<_GroupList> {
  Stream<List<GroupViewModel>>? _groupsViewModelStream;

  @override
  void initState() {
    super.initState();
    _setupGroupsStream();
  }

  void _setupGroupsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('User not logged in.', name: 'HomeScreen');
      return;
    }

    final groupMembershipsStream = FirebaseFirestore.instance
        .collection('userGroupMemberships')
        .doc(user.uid)
        .collection('groups')
        .snapshots();

    _groupsViewModelStream = groupMembershipsStream.asyncMap((memberships) async {
      if (memberships.docs.isEmpty) {
        return [];
      }

      final groupIds = memberships.docs.map((doc) => doc.id).toList();

      final groupsFuture = FirebaseFirestore.instance
          .collection('groups')
          .where(FieldPath.documentId, whereIn: groupIds)
          .get();

      final eventsFuture = FirebaseFirestore.instance
          .collection('events')
          .where('groupId', whereIn: groupIds)
          .where('eventTimestamp', isGreaterThan: Timestamp.now())
          .orderBy('eventTimestamp')
          .get();

      final members = await FirebaseFirestore.instance
          .collection('groups')
          .where(FieldPath.documentId, whereIn: groupIds)
          .get()
          .then((snapshot) => snapshot.docs
              .map((doc) => doc.reference.collection('members').doc(user.uid).get())
              .toList())
          .then((futures) => Future.wait(futures));

      final results = await Future.wait([groupsFuture, eventsFuture]);
      final groups = results[0];
      final events = results[1];

      final groupDocs = {for (var doc in groups.docs) doc.id: doc};
      final memberDocs = {
        for (var doc in members)
          if (doc.exists) doc.reference.parent.parent!.id: doc
      };

      final nextEvents = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (var event in events.docs) {
        final groupId = event.data()['groupId'] as String;
        if (!nextEvents.containsKey(groupId)) {
          nextEvents[groupId] = event;
        }
      }

      final participantFutures = <Future<DocumentSnapshot<Map<String, dynamic>>?>>[];
      for (var event in nextEvents.values) {
        participantFutures.add(FirebaseFirestore.instance
            .collection('events')
            .doc(event.id)
            .collection('participants')
            .doc(user.uid)
            .get());
      }

      final participants = await Future.wait(participantFutures);
      final participantDocs = {
        for (var doc in participants)
          if (doc != null && doc.exists) doc.reference.parent.parent!.id: doc
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
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupViewModel>>(
      stream: _groupsViewModelStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final user = FirebaseAuth.instance.currentUser;
          developer.log(
            'Error fetching groups stream for user ${user?.uid}.',
            name: 'HomeScreen',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final viewModels = snapshot.data;

        if (viewModels == null || viewModels.isEmpty) {
          return Center(
            child: Text(
              'You are not a member of any groups yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: viewModels.length,
          itemBuilder: (context, index) {
            return GroupListItem(viewModel: viewModels[index]);
          },
        );
      },
    );
  }
}

class _CreateGroupModal extends StatefulWidget {
  const _CreateGroupModal();

  @override
  State<_CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends State<_CreateGroupModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _limitController = TextEditingController(text: '0');
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submitCreateGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('createGroup');
      final result = await callable.call<Map<String, dynamic>>({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'negativeBalanceLimit': int.parse(_limitController.text),
      });

      final groupCode = result.data['groupCode'] as String?;

      if (mounted && groupCode != null) {
        // Close the create modal first
        Navigator.of(context).pop();
        // Then show the success dialog
        _showSuccessDialog(groupCode);
      }
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
          _isCreating = false;
        });
      }
    }
  }

  void _showSuccessDialog(String groupCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Group Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this code with your members:'),
            const SizedBox(height: 16),
            SelectableText(
              groupCode,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: groupCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group code copied!')),
              );
            },
            child: const Text('Copy Code'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Group',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              decoration: const InputDecoration(
                labelText: 'Negative Balance Limit',
                helperText: 'Max negative balance a member can have.',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return 'Please enter a valid number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                if (_isCreating)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submitCreateGroup,
                    child: const Text('Create'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinGroupModal extends StatefulWidget {
  const _JoinGroupModal();

  @override
  State<_JoinGroupModal> createState() => _JoinGroupModalState();
}

class _JoinGroupModalState extends State<_JoinGroupModal> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  QueryDocumentSnapshot<Map<String, dynamic>>? _foundGroup;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _findGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundGroup = null;
    });

    try {
      // Standardize the input for a case-insensitive search
      final enteredCode = _codeController.text.trim().toUpperCase().replaceAll("-", "");
      final groupQuery = await FirebaseFirestore.instance
          .collection('groups')
          .where('groupCodeSearch', isEqualTo: enteredCode)
          .limit(1)
          .get();

      if (groupQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No group found with that code.';
        });
      } else {
        setState(() {
          _foundGroup = groupQuery.docs.first;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendJoinRequest() async {
    if (_foundGroup == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to send a request.');
      }

      final groupRef = _foundGroup!.reference;
      final requestRef = groupRef.collection('joinRequests').doc(user.uid);

      await requestRef.set({
        'uid': user.uid,
        'displayName': user.displayName ?? 'No Name',
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // Explicitly set status
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your request to join has been sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join a Group',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          if (_foundGroup == null)
            _buildSearchForm()
          else
            _buildGroupDetails(),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Enter Group Code'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a code.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _findGroup,
                  child: const Text('Find Group'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDetails() {
    final groupData = _foundGroup!.data();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupData['name'],
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(groupData['description']),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _foundGroup = null;
                  _codeController.clear();
                });
              },
              child: const Text('Back'),
            ),
            const SizedBox(width: 8),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _sendJoinRequest,
                child: const Text('Request to Join'),
              ),
          ],
        ),
      ],
    );
  }
}