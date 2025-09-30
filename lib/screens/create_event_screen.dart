import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

enum CommitmentDeadlineOption {
  oneDay,
  twoDays,
  threeDays,
  fourDays,
  fiveDays,
  custom,
}

class CreateEventScreen extends StatefulWidget {
  final String groupId;

  const CreateEventScreen({super.key, required this.groupId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _feeController = TextEditingController(text: '0');
  final _maxParticipantsController = TextEditingController();

  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;
  bool _isLoading = false;
  CommitmentDeadlineOption _deadlineOption = CommitmentDeadlineOption.twoDays;

  @override
  void initState() {
    super.initState();
    _prefillFromPreviousEvent();
  }

  Future<void> _prefillFromPreviousEvent() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('groupId', isEqualTo: widget.groupId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final lastEvent = querySnapshot.docs.first.data();
        if (mounted) {
          setState(() {
            _nameController.text = lastEvent['name'] ?? '';
            _locationController.text = lastEvent['location'] ?? '';
            _feeController.text = (lastEvent['fee'] ?? 0).toString();
          });
        }
      }
    } catch (e, st) {
      developer.log(
        'Error prefilling event data',
        name: 'CreateEventScreen',
        error: e,
        stackTrace: st,
      );
      // Don't show a snackbar, just fail gracefully
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _feeController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isEvent}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      if (isEvent) {
        _eventDate = date;
        _eventTime = time;
        _applyRelativeDeadline();
      } else {
        _deadlineDate = date;
        _deadlineTime = time;
      }
    });
  }

  void _applyRelativeDeadline() {
    final days = _daysBeforeForOption(_deadlineOption);
    if (days == null) {
      return;
    }
    if (_eventDate == null || _eventTime == null) {
      _deadlineDate = null;
      _deadlineTime = null;
      return;
    }

    final eventDateTime = DateTime(
      _eventDate!.year,
      _eventDate!.month,
      _eventDate!.day,
      _eventTime!.hour,
      _eventTime!.minute,
    );
    final deadlineDateTime = eventDateTime.subtract(Duration(days: days));
    _deadlineDate = DateTime(
      deadlineDateTime.year,
      deadlineDateTime.month,
      deadlineDateTime.day,
    );
    _deadlineTime = TimeOfDay.fromDateTime(deadlineDateTime);
  }

  int? _daysBeforeForOption(CommitmentDeadlineOption option) {
    switch (option) {
      case CommitmentDeadlineOption.oneDay:
        return 1;
      case CommitmentDeadlineOption.twoDays:
        return 2;
      case CommitmentDeadlineOption.threeDays:
        return 3;
      case CommitmentDeadlineOption.fourDays:
        return 4;
      case CommitmentDeadlineOption.fiveDays:
        return 5;
      case CommitmentDeadlineOption.custom:
        return null;
    }
  }

  String _labelForOption(CommitmentDeadlineOption option) {
    switch (option) {
      case CommitmentDeadlineOption.oneDay:
        return '1 day before the event';
      case CommitmentDeadlineOption.twoDays:
        return '2 days before the event';
      case CommitmentDeadlineOption.threeDays:
        return '3 days before the event';
      case CommitmentDeadlineOption.fourDays:
        return '4 days before the event';
      case CommitmentDeadlineOption.fiveDays:
        return '5 days before the event';
      case CommitmentDeadlineOption.custom:
        return 'Custom date & time';
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_eventDate == null ||
        _eventTime == null ||
        _deadlineDate == null ||
        _deadlineTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all dates and times.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to create an event.');
      }

      final eventTimestamp = DateTime(
        _eventDate!.year,
        _eventDate!.month,
        _eventDate!.day,
        _eventTime!.hour,
        _eventTime!.minute,
      );

      final deadlineTimestamp = DateTime(
        _deadlineDate!.year,
        _deadlineDate!.month,
        _deadlineDate!.day,
        _deadlineTime!.hour,
        _deadlineTime!.minute,
      );

      await FirebaseFirestore.instance.collection('events').add({
        'name': _nameController.text,
        'groupId': widget.groupId,
        'admin': user.uid,
        'location': _locationController.text,
        'eventTimestamp': Timestamp.fromDate(eventTimestamp),
        'commitmentDeadline': Timestamp.fromDate(deadlineTimestamp),
        'fee': int.parse(_feeController.text),
        'maxParticipants': int.parse(_maxParticipantsController.text),
        'confirmedCount': 0,
        'waitlistCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'isCleanedUp': false,
        'status': 'active', // Add default status
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      developer.log(
        'Error creating event',
        name: 'CreateEventScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: ${e.toString()}'),
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
      appBar: AppBar(title: const Text('Create New Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDateTimePicker(
                label: 'Event Date & Time',
                date: _eventDate,
                time: _eventTime,
                onTap: () => _pickDateTime(isEvent: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CommitmentDeadlineOption>(
                value: _deadlineOption,
                decoration: const InputDecoration(
                  labelText: 'Commitment Deadline (relative)',
                  border: OutlineInputBorder(),
                ),
                items: CommitmentDeadlineOption.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(_labelForOption(option)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _deadlineOption = value;
                    if (value != CommitmentDeadlineOption.custom) {
                      _applyRelativeDeadline();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_deadlineOption == CommitmentDeadlineOption.custom)
                _buildDateTimePicker(
                  label: 'Commitment Deadline',
                  date: _deadlineDate,
                  time: _deadlineTime,
                  onTap: () => _pickDateTime(isEvent: false),
                )
              else
                _buildDeadlineSummary(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feeController,
                decoration: const InputDecoration(
                  labelText: 'Fee',
                  helperText: 'Cost of the event in virtual currency.',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Please enter a valid number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Max Participants',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Please enter a valid number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _createEvent,
                  child: const Text('Create Event'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineSummary() {
    final theme = Theme.of(context);
    final deadlineSet = _deadlineDate != null && _deadlineTime != null;
    final formatted = deadlineSet
        ? '${DateFormat.yMMMd().format(_deadlineDate!)} at ${_deadlineTime!.format(context)}'
        : 'Select event date & time to calculate the deadline.';

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Commitment Deadline',
        border: OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _labelForOption(_deadlineOption),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(formatted),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    DateTime? date,
    TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    final formattedDate = date != null ? DateFormat.yMMMd().format(date) : '';
    final formattedTime = time != null ? time.format(context) : '';
    final value = date != null ? '$formattedDate at $formattedTime' : '';

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(value.isEmpty ? 'Select a date and time' : value),
      ),
    );
  }
}
