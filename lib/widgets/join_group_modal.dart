import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  // Populated from the findGroupByCode callable, so only contains the safe
  // preview fields (groupId, name, description, groupCode) — never admin,
  // negativeBalanceLimit, etc. See _goToGroup for the full-document fetch
  // used once membership is confirmed.
  Map<String, dynamic>? _foundGroup;
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
      // Groups aren't directly listable/queryable by non-members (Firestore
      // Security Rules deny `list` on /groups to prevent enumerating every
      // group's admin uid, negativeBalanceLimit, etc.), so the code lookup
      // goes through a callable that runs with Admin SDK privileges and
      // returns only the safe preview fields.
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('findGroupByCode');
      final result = await callable.call({'code': _codeController.text.trim()});
      final foundGroup = Map<String, dynamic>.from(result.data as Map);
      final groupId = foundGroup['groupId'] as String;

      final isAlreadyMember = await _checkMembership(groupId);
      setState(() {
        _foundGroup = foundGroup;
        _isAlreadyMember = isAlreadyMember;
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _errorMessage =
            e.code == 'not-found' ? 'No group found with that code.' : 'An error occurred. Please try again.';
      });
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

  Future<void> _goToGroup() async {
    if (_foundGroup == null) return;
    final groupId = _foundGroup!['groupId'] as String;

    setState(() {
      _isLoading = true;
    });

    try {
      // _foundGroup only has the safe preview fields from findGroupByCode.
      // Now that membership is confirmed, fetch the full document (allowed
      // for any authenticated user via `get`) for GroupDetailsScreen.
      final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      if (!mounted) return;
      if (!groupDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'This group no longer exists.';
        });
        return;
      }

      final groupData = {...groupDoc.data()!, 'groupId': groupId};
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GroupDetailsScreen(group: groupData),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the group. Please try again.')),
        );
      }
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

      final groupId = _foundGroup!['groupId'] as String;
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
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
    final groupData = _foundGroup!;
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
