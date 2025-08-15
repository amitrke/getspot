import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _CreateGroupModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navigate to Profile Screen
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
                onPressed: () {
                  // TODO: Implement Join a Group
                },
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
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>? _groupsStream;

  @override
  void initState() {
    super.initState();
    _setupGroupsStream();
  }

  void _setupGroupsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle user not logged in case
      return;
    }

    final groupsStream = FirebaseFirestore.instance
        .collectionGroup('members')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((membersSnapshot) async {
      final groupFutures = membersSnapshot.docs.map((memberDoc) {
        // For each membership, get the parent group document
        return memberDoc.reference.parent.parent!.get();
      }).toList();

      final groupDocs = await Future.wait(groupFutures);

      // Filter out any groups that might not exist for some reason
      return groupDocs
          .where((doc) => doc.exists)
          .map((doc) =>
              doc as QueryDocumentSnapshot<Map<String, dynamic>>)
          .toList();
    });

    setState(() {
      _groupsStream = groupsStream;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _groupsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final groups = snapshot.data;

        if (groups == null || groups.isEmpty) {
          return Center(
            child: Text(
              'You are not a member of any groups yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index].data();
            return _GroupListItem(group: group);
          },
        );
      },
    );
  }
}

class _GroupListItem extends StatelessWidget {
  const _GroupListItem({required this.group});

  final Map<String, dynamic> group;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(group['name'] ?? 'Unnamed Group'),
        subtitle: Text(group['description'] ?? ''),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to Group Details Screen
        },
      ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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