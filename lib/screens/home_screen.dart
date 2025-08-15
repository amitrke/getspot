import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getspot/services/auth_service.dart';

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
      body: Center(
        // TODO: Replace with a list of user's groups
        child: Text(
          'You are not a member of any groups yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
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
      final functions = FirebaseFunctions.instance;
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
