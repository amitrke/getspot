import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'group_details_screen.dart';

/// Screen for joining a group with a pre-filled group code (used for deep linking)
class JoinGroupScreen extends StatefulWidget {
  final String groupCode;

  const JoinGroupScreen({super.key, required this.groupCode});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  // Populated from the findGroupByCode callable, so only contains the safe
  // preview fields (groupId, name, description, groupCode) — never admin,
  // negativeBalanceLimit, etc. See _goToGroup for the full-document fetch
  // used once membership is confirmed.
  Map<String, dynamic>? _foundGroup;
  bool _isAlreadyMember = false;
  String? _existingRequestStatus;

  @override
  void initState() {
    super.initState();
    _findGroup();
  }

  Future<void> _findGroup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundGroup = null;
      _isAlreadyMember = false;
      _existingRequestStatus = null;
    });

    try {
      developer.log(
        'Looking up group with code: ${widget.groupCode}',
        name: 'JoinGroupScreen',
      );

      // Groups aren't directly listable/queryable by non-members (Firestore
      // Security Rules deny `list` on /groups to prevent enumerating every
      // group's admin uid, negativeBalanceLimit, etc.), so the code lookup
      // goes through a callable that runs with Admin SDK privileges and
      // returns only the safe preview fields.
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('findGroupByCode');
      final result = await callable.call({'code': widget.groupCode});
      final foundGroup = Map<String, dynamic>.from(result.data as Map);
      final groupId = foundGroup['groupId'] as String;

      final isAlreadyMember = await _checkMembership(groupId);
      final existingRequestStatus = isAlreadyMember
          ? null
          : await _checkExistingRequest(groupId);
      setState(() {
        _foundGroup = foundGroup;
        _isAlreadyMember = isAlreadyMember;
        _existingRequestStatus = existingRequestStatus;
      });
      developer.log(
        'Found group: ${foundGroup['name']} '
        '(alreadyMember: $isAlreadyMember, existingRequestStatus: $existingRequestStatus)',
        name: 'JoinGroupScreen',
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        setState(() {
          _errorMessage = 'No group found with code: ${widget.groupCode}';
        });
        developer.log('No group found with code: ${widget.groupCode}', name: 'JoinGroupScreen');
      } else {
        developer.log('Error finding group', name: 'JoinGroupScreen', error: e);
        setState(() {
          _errorMessage = 'An error occurred while looking up the group. Please try again.';
        });
      }
    } catch (e) {
      developer.log('Error finding group', name: 'JoinGroupScreen', error: e);
      setState(() {
        _errorMessage = 'An error occurred while looking up the group. Please try again.';
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

  /// Returns the `status` of the user's existing join request for this group
  /// (e.g. `'pending'`, `'denied'`), or null if none exists. Firestore
  /// Security Rules only allow a user to `create` a join request, not
  /// `update` one — writing over an existing request throws
  /// permission-denied, so we must check for one up front and steer the UI
  /// accordingly rather than let that write fail.
  Future<String?> _checkExistingRequest(String groupId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final requestDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .doc(user.uid)
        .get();

    if (!requestDoc.exists) return null;
    return requestDoc.data()?['status'] as String? ?? 'pending';
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GroupDetailsScreen(group: groupData),
        ),
      );
    } catch (e) {
      developer.log('Error loading group', name: 'JoinGroupScreen', error: e);
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

      developer.log('Join request sent successfully', name: 'JoinGroupScreen');

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
      developer.log('Error sending join request', name: 'JoinGroupScreen', error: e);
      if (mounted) {
        // Security Rules only allow creating a join request, not overwriting
        // one — a permission-denied here almost always means a request from
        // this user already exists (e.g. a race with another tab, or this
        // screen's own pre-check was stale). Re-check and show a friendly
        // message instead of the raw Firestore error.
        final isPermissionDenied = e is FirebaseException && e.code == 'permission-denied';
        final status = isPermissionDenied
            ? await _checkExistingRequest(_foundGroup!['groupId'] as String)
            : null;
        if (mounted) {
          setState(() {
            _existingRequestStatus = status;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status != null
                    ? 'You already have a request to join this group ($status).'
                    : e.toString(),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (_foundGroup != null) {
      final groupData = _foundGroup!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.groups,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You\'ve been invited to join:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            groupData['name'] ?? 'Unnamed Group',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (groupData['description'] != null && groupData['description'].toString().isNotEmpty) ...[
            Text(
              'About this group:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              groupData['description'],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Group Code: ${widget.groupCode}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
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
          ] else if (_existingRequestStatus == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.hourglass_top, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Your request to join this group is pending approval.'),
                ),
              ],
            ),
          ] else if (_existingRequestStatus != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Your previous request was $_existingRequestStatus. Contact the group admin for help.'),
                ),
              ],
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_isAlreadyMember
                      ? _goToGroup
                      : (_existingRequestStatus != null ? null : _sendJoinRequest)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isAlreadyMember
                          ? 'Go to Group'
                          : (_existingRequestStatus == 'pending'
                              ? 'Request Pending'
                              : (_existingRequestStatus != null ? 'Request $_existingRequestStatus' : 'Request to Join')),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      );
    }

    return const Center(child: Text('Something went wrong.'));
  }
}
