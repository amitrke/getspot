import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

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
  QueryDocumentSnapshot<Map<String, dynamic>>? _foundGroup;

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
    });

    try {
      developer.log(
        'Looking up group with code: ${widget.groupCode}',
        name: 'JoinGroupScreen',
      );

      // Standardize the input for a case-insensitive search
      final standardizedCode = widget.groupCode.trim().toUpperCase().replaceAll("-", "");
      final groupQuery = await FirebaseFirestore.instance
          .collection('groups')
          .where('groupCodeSearch', isEqualTo: standardizedCode)
          .limit(1)
          .get();

      if (groupQuery.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No group found with code: ${widget.groupCode}';
        });
        developer.log('No group found with code: ${widget.groupCode}', name: 'JoinGroupScreen');
      } else {
        setState(() {
          _foundGroup = groupQuery.docs.first;
        });
        developer.log(
          'Found group: ${groupQuery.docs.first.data()['name']}',
          name: 'JoinGroupScreen',
        );
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
      final groupData = _foundGroup!.data();
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
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendJoinRequest,
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
                  : const Text(
                      'Request to Join',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
