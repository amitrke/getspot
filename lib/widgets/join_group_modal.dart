import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/group_details_screen.dart';

class JoinGroupModal extends StatefulWidget {
  const JoinGroupModal({super.key});

  @override
  State<JoinGroupModal> createState() => _JoinGroupModalState();
}

class _JoinGroupModalState extends State<JoinGroupModal> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  QueryDocumentSnapshot<Map<String, dynamic>>? _foundGroup;
  bool _isAlreadyMember = false;

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
      _isAlreadyMember = false;
    });

    try {
      // Standardize the input for a case-insensitive search
      final enteredCode =
          _codeController.text.trim().toUpperCase().replaceAll("-", "");
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
        final foundGroup = groupQuery.docs.first;
        final isAlreadyMember = await _checkMembership(foundGroup.id);
        setState(() {
          _foundGroup = foundGroup;
          _isAlreadyMember = isAlreadyMember;
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

  /// Checks the denormalized membership index rather than the group's
  /// `members` subcollection directly — the `members` security rule requires
  /// the caller to already be a member just to `get` any doc in it
  /// (including their own), which would surface as permission-denied instead
  /// of a clean "not found" for the exact non-member case we need to detect.
  Future<bool> _checkMembership(String groupId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final membershipDoc = await FirebaseFirestore.instance
        .collection('userGroupMemberships')
        .doc(user.uid)
        .collection('groups')
        .doc(groupId)
        .get();

    return membershipDoc.exists;
  }

  void _goToGroup() {
    if (_foundGroup == null) return;

    final groupData = {..._foundGroup!.data(), 'groupId': _foundGroup!.id};
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: groupData),
      ),
    );
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
        'status': 'pending',
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your request to join has been sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
          if (_foundGroup == null) _buildSearchForm() else _buildGroupDetails(),
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
        if (_isAlreadyMember) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('You\'re already a member of this group.'),
              ),
            ],
          ),
        ],
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
                onPressed: _isAlreadyMember ? _goToGroup : _sendJoinRequest,
                child: Text(_isAlreadyMember ? 'Go to Group' : 'Request to Join'),
              ),
          ],
        ),
      ],
    );
  }
}
