import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/services/event_cache_service.dart';
import 'package:getspot/services/transaction_cache_service.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final bool isGroupAdmin;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.isGroupAdmin = false,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isRegistering = false;
  bool _isWithdrawing = false;
  bool _isCancelling = false;
  bool _isUpdatingCapacity = false;

  bool get _isAdmin => widget.isGroupAdmin;

  @override
  void initState() {
    super.initState();
    // No longer need to fetch admin status - it's passed as a parameter
  }

  // Formats a dollar amount with the locale-correct decimal separator,
  // keeping the literal "$" prefix (not itself a translation concern).
  String _fmtAmount(double amount) {
    final locale = Localizations.localeOf(context).toString();
    return '\$${NumberFormat('0.00', locale).format(amount)}';
  }

  Future<void> _showRegistrationConfirmationDialog(Map<String, dynamic> eventData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch user's wallet balance from the group
      final groupId = eventData['groupId'] as String;
      final fee = (eventData['fee'] as num?)?.toDouble() ?? 0.0;

      final memberDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(user.uid)
          .get();

      if (!memberDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.eventDetailsNotAMember),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      final walletBalance = (memberDoc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = walletBalance - fee;

      // Fetch group's negative balance limit
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();

      final negativeBalanceLimit = (groupDoc.data()?['negativeBalanceLimit'] as num?)?.toDouble() ?? 0.0;

      // Check if event is full
      final confirmedCount = eventData['confirmedCount'] ?? 0;
      final maxParticipants = eventData['maxParticipants'] ?? 0;
      final isFull = confirmedCount >= maxParticipants;

      if (!mounted) return;

      // Show appropriate dialog
      if (isFull) {
        _showWaitlistConfirmationDialog(
          eventData: eventData,
          fee: fee,
          currentBalance: walletBalance,
          newBalance: newBalance,
        );
      } else if (newBalance < -negativeBalanceLimit) {
        // Insufficient balance
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.eventDetailsInsufficientBalanceTitle),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.eventDetailsCurrentBalanceAmount(_fmtAmount(walletBalance))),
                  Text(l10n.eventDetailsEventFeeAmount(_fmtAmount(fee))),
                  Text(l10n.eventDetailsNewBalanceAmount(_fmtAmount(newBalance))),
                  const SizedBox(height: 16),
                  Text(l10n.eventDetailsAllowedNegativeLimit(_fmtAmount(negativeBalanceLimit))),
                  const SizedBox(height: 16),
                  Text(
                    l10n.eventDetailsInsufficientBalanceMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonOk),
                ),
              ],
            );
          },
        );
      } else if (newBalance < 0) {
        // Balance will be negative but within limit
        _showNegativeBalanceConfirmationDialog(
          eventData: eventData,
          fee: fee,
          currentBalance: walletBalance,
          newBalance: newBalance,
          negativeLimit: negativeBalanceLimit,
        );
      } else {
        // Normal registration
        _showNormalRegistrationDialog(
          eventData: eventData,
          fee: fee,
          currentBalance: walletBalance,
          newBalance: newBalance,
        );
      }
    } catch (e, st) {
      developer.log(
        'Error showing registration dialog',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.eventDetailsGenericError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showNormalRegistrationDialog({
    required Map<String, dynamic> eventData,
    required double fee,
    required double currentBalance,
    required double newBalance,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.eventDetailsRegisterTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventData['name'] ?? l10n.eventDetailsFallbackEventName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(l10n.eventDetailsEventFeeAmount(_fmtAmount(fee))),
              const Divider(height: 24),
              Text(l10n.eventDetailsCurrentBalanceAmount(_fmtAmount(currentBalance))),
              Text(
                l10n.eventDetailsNewBalanceAmount(_fmtAmount(newBalance)),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registerForEvent();
              },
              child: Text(l10n.eventDetailsConfirmRegistrationButton),
            ),
          ],
        );
      },
    );
  }

  void _showNegativeBalanceConfirmationDialog({
    required Map<String, dynamic> eventData,
    required double fee,
    required double currentBalance,
    required double newBalance,
    required double negativeLimit,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text(l10n.eventDetailsLowBalanceWarningTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventData['name'] ?? l10n.eventDetailsFallbackEventName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(l10n.eventDetailsEventFeeAmount(_fmtAmount(fee))),
              const Divider(height: 24),
              Text(l10n.eventDetailsCurrentBalanceAmount(_fmtAmount(currentBalance))),
              Text(
                l10n.eventDetailsNewBalanceNegative(_fmtAmount(newBalance)),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              Text(l10n.eventDetailsAllowedLimit(_fmtAmount(negativeLimit))),
              const SizedBox(height: 16),
              Text(
                l10n.eventDetailsNegativeBalanceWarning,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registerForEvent();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(l10n.eventDetailsUnderstandRegisterButton),
            ),
          ],
        );
      },
    );
  }

  void _showWaitlistConfirmationDialog({
    required Map<String, dynamic> eventData,
    required double fee,
    required double currentBalance,
    required double newBalance,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.list, color: Colors.blue),
              const SizedBox(width: 8),
              Text(l10n.eventDetailsJoinWaitlistTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.eventDetailsEventFullMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(l10n.eventDetailsWaitlistFeeInfo(_fmtAmount(fee))),
              const Divider(height: 24),
              Text(l10n.eventDetailsCurrentBalanceAmount(_fmtAmount(currentBalance))),
              Text(
                l10n.eventDetailsNewBalanceAmount(_fmtAmount(newBalance)),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.eventDetailsAutoConfirmInfo,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registerForEvent();
              },
              child: Text(l10n.eventDetailsJoinWaitlistButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerForEvent() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(AppLocalizations.of(context)!.eventDetailsMustBeLoggedInRegister);
      }

      final participantRef = FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('participants')
          .doc(user.uid);

      await participantRef.set({
        'uid': user.uid,
        'displayName': user.displayName ?? AppLocalizations.of(context)!.commonNoName,
        'photoURL': user.photoURL,
        'status': 'requested',
        'registeredAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.eventDetailsRegistrationSubmitted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Error registering for event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.eventDetailsErrorSubmittingRequest(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _withdrawFromEvent() async {
    setState(() {
      _isWithdrawing = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('withdrawFromEvent');
      final result = await callable.call({'eventId': widget.eventId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? AppLocalizations.of(context)!.eventDetailsWithdrawalSuccessful),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e, st) {
      developer.log(
        'Error withdrawing from event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? AppLocalizations.of(context)!.createGroupUnknownError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Generic error withdrawing from event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
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
          _isWithdrawing = false;
        });
      }
    }
  }

  Future<void> _cancelEvent(String groupId) async {
    setState(() {
      _isCancelling = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('cancelEvent');
      final result = await callable.call({'eventId': widget.eventId});

      // Invalidate event cache for this group
      EventCacheService().invalidate(groupId);
      // Invalidate transaction cache for the entire group (refunds created for all participants)
      TransactionCacheService().invalidateGroup(groupId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? AppLocalizations.of(context)!.eventDetailsCancelledSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e, st) {
      developer.log(
        'Error cancelling event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? AppLocalizations.of(context)!.createGroupUnknownError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Generic error cancelling event',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
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
          _isCancelling = false;
        });
      }
    }
  }

  Future<void> _updateEventCapacity(int newCapacity) async {
    setState(() {
      _isUpdatingCapacity = true;
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-east4');
      final callable = functions.httpsCallable('updateEventCapacity');
      final result = await callable.call({
        'eventId': widget.eventId,
        'newMaxParticipants': newCapacity,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? AppLocalizations.of(context)!.eventDetailsCapacityUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e, st) {
      developer.log(
        'Error updating event capacity',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? AppLocalizations.of(context)!.createGroupUnknownError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Generic error updating event capacity',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
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
          _isUpdatingCapacity = false;
        });
      }
    }
  }

  void _showUpdateCapacityDialog(Map<String, dynamic> eventData) {
    final currentCapacity = eventData['maxParticipants'] ?? 0;
    final confirmedCount = eventData['confirmedCount'] ?? 0;
    final waitlistCount = eventData['waitlistCount'] ?? 0;
    final capacityController = TextEditingController(text: currentCapacity.toString());

    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.eventDetailsUpdateCapacityTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.eventDetailsCurrentCapacity(currentCapacity)),
              Text(l10n.eventDetailsConfirmedParticipants(confirmedCount)),
              Text(l10n.eventDetailsWaitlistedParticipants(waitlistCount)),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.eventDetailsNewCapacityLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.eventDetailsCannotReduceBelow(confirmedCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.commonCancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(l10n.eventDetailsUpdateButton),
              onPressed: () {
                final newCapacity = int.tryParse(capacityController.text);
                if (newCapacity == null || newCapacity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.eventDetailsValidPositiveNumber),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                _showConfirmCapacityChangeDialog(
                  currentCapacity,
                  newCapacity,
                  confirmedCount,
                  waitlistCount,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmCapacityChangeDialog(
    int oldCapacity,
    int newCapacity,
    int confirmedCount,
    int waitlistCount,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isIncreasing = newCapacity > oldCapacity;
    final change = (newCapacity - oldCapacity).abs();

    String message;
    if (isIncreasing) {
      final canPromote = math.min(change, waitlistCount);
      if (canPromote > 0) {
        message = l10n.eventDetailsIncreaseCapacityWithPromote(change, canPromote);
      } else {
        message = l10n.eventDetailsIncreaseCapacityNoPromote(change);
      }
    } else {
      message = l10n.eventDetailsDecreaseCapacity(change, oldCapacity, newCapacity);
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.eventDetailsConfirmCapacityChangeTitle),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.commonCancel),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(l10n.commonConfirm),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _updateEventCapacity(newCapacity);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmationDialog(String groupId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.eventDetailsConfirmCancellationTitle),
          content: Text(l10n.eventDetailsCancelConfirmMessage),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.eventDetailsNevermindButton),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.eventDetailsConfirmCancellationButton),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelEvent(groupId);
              },
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawConfirmationDialog(Map<String, dynamic> eventData) {
    final deadlineTimestamp = eventData['commitmentDeadline'] as Timestamp?;
    final fee = (eventData['fee'] as num?)?.toDouble() ?? 0.0;
    bool isAfterDeadline = false;

    if (deadlineTimestamp != null) {
      isAfterDeadline = DateTime.now().isAfter(deadlineTimestamp.toDate());
    }

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    String refundInfo;
    Color refundColor;
    IconData refundIcon;

    if (isAfterDeadline) {
      refundInfo = l10n.eventDetailsRefundMayBeForfeited;
      refundColor = Colors.orange;
      refundIcon = Icons.warning;
    } else {
      refundInfo = l10n.eventDetailsRefundFullAmount(_fmtAmount(fee));
      refundColor = Colors.green;
      refundIcon = Icons.check_circle;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.eventDetailsConfirmWithdrawalTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eventData['name'] ?? l10n.eventDetailsFallbackEventName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(l10n.eventDetailsEventFeeAmount(_fmtAmount(fee))),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(refundIcon, color: refundColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      refundInfo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: refundColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (deadlineTimestamp != null) ...[
                Text(
                  l10n.eventDetailsCommitmentDeadlineLabel(
                    DateFormat.yMMMd(locale).add_jm().format(deadlineTimestamp.toDate()),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                isAfterDeadline
                    ? l10n.eventDetailsDeadlinePassedMessage
                    : l10n.eventDetailsBeforeDeadlineMessage,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.commonCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAfterDeadline ? Colors.orange : Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _withdrawFromEvent();
              },
              child: Text(l10n.eventDetailsConfirmWithdrawalButton),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventDetailsAppBarTitle),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(l10n.eventDetailsErrorLoading));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text(l10n.eventDetailsNotFound));
            }

            final locale = Localizations.localeOf(context).toString();
            final event = snapshot.data!.data()!;
            final eventTimestamp = event['eventTimestamp'] as Timestamp?;
            final deadlineTimestamp = event['commitmentDeadline'] as Timestamp?;
            final isCancelled = event['status'] == 'cancelled';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCancelled)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        l10n.eventDetailsCancelledBanner,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isCancelled) const SizedBox(height: 16),
                  Text(
                    event['name'] ?? l10n.groupDetailsUnnamedEvent,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildCompactDetailRow(
                    icon: Icons.location_on,
                    value: event['location'] ?? l10n.eventDetailsNoLocationSet,
                  ),
                  _buildCompactDetailRow(
                    icon: Icons.calendar_today,
                    value: eventTimestamp != null
                        ? DateFormat.yMMMd(locale)
                            .add_jm()
                            .format(eventTimestamp.toDate())
                        : l10n.eventDetailsNoDateSet,
                  ),
                  _buildCompactDetailRow(
                    icon: Icons.attach_money,
                    value: l10n.eventDetailsFeeCredits('${event['fee'] ?? 0}'),
                  ),
                  _buildCompactDetailRow(
                    icon: Icons.timer,
                    value: deadlineTimestamp != null
                        ? DateFormat.yMMMd(locale)
                            .add_jm()
                            .format(deadlineTimestamp.toDate())
                        : l10n.eventDetailsNoDeadline,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildParticipantList(
                          title: l10n.eventDetailsConfirmedHeader(
                            '${event['confirmedCount'] ?? 0}',
                            '${event['maxParticipants'] ?? 'N/A'}',
                          ),
                          status: 'confirmed',
                          showUpdateButton: _isAdmin && !isCancelled,
                          onUpdatePressed: () => _showUpdateCapacityDialog(event),
                          isUpdating: _isUpdatingCapacity,
                        ),
                        const SizedBox(height: 16),
                        _buildParticipantList(
                          title: l10n.eventDetailsWaitlistHeader('${event['waitlistCount'] ?? 0}'),
                          status: 'waitlisted',
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(event),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyParticipantList(String status, String title) async {
    try {
      // Fetch participants from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('participants')
          .where('status', isEqualTo: status)
          .orderBy('registeredAt', descending: false)
          .get();

      final participants = snapshot.docs;

      if (participants.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.eventDetailsNoParticipantsToCopy),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Format the list
      final buffer = StringBuffer();
      buffer.writeln(title);
      buffer.writeln('=' * title.length);
      buffer.writeln();

      final noNameFallback = mounted ? AppLocalizations.of(context)!.commonNoName : 'No Name';
      for (int i = 0; i < participants.length; i++) {
        final participant = participants[i].data();
        final displayName = participant['displayName'] ?? noNameFallback;
        buffer.writeln('${i + 1}. $displayName');
      }

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.eventDetailsCopiedParticipants(participants.length)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      developer.log(
        'Error copying participant list',
        name: 'EventDetailsScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.eventDetailsErrorCopyingList(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildParticipantList({
    required String title,
    required String status,
    bool showUpdateButton = false,
    VoidCallback? onUpdatePressed,
    bool isUpdating = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (_isAdmin) ...[
              IconButton(
                onPressed: () => _copyParticipantList(status, title),
                icon: const Icon(Icons.copy, size: 20),
                tooltip: l10n.eventDetailsCopyListTooltip,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (showUpdateButton)
              ElevatedButton.icon(
                onPressed: isUpdating ? null : onUpdatePressed,
                icon: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.eventDetailsUpdateButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('participants')
              .where('status', isEqualTo: status)
              .orderBy('registeredAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text(l10n.eventDetailsErrorLoadingParticipants);
            }
            final participants = snapshot.data?.docs ?? [];
            if (participants.isEmpty) {
              return Text(l10n.eventDetailsNoParticipantsYet);
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index].data();
                final photoUrl = participant['photoURL'] as String?;
                final displayName = participant['displayName'] ?? l10n.commonNoName;
                final uid = participant['uid'] as String?;

                return Semantics(
                  label: 'participant_item_${uid ?? index}',
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(displayName.isNotEmpty ? displayName[0] : '?')
                          : null,
                    ),
                    title: Text(displayName),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _participantStatusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'requested':
        return l10n.eventDetailsStatusRequested;
      case 'withdrawn_penalty':
        return l10n.eventDetailsStatusWithdrawnPenalty;
      default:
        return status.isNotEmpty ? '${status[0].toUpperCase()}${status.substring(1)}' : status;
    }
  }

  Widget _buildActionButton(Map<String, dynamic> eventData) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final isCancelled = eventData['status'] == 'cancelled';

    List<Widget> buttons = [];

    if (_isAdmin && !isCancelled) {
      final groupId = eventData['groupId'] as String;
      buttons.add(
        Semantics(
          label: 'cancel_event_button',
          child: ElevatedButton(
            onPressed: _isCancelling ? null : () => _showCancelConfirmationDialog(groupId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: _isCancelling
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(l10n.eventDetailsCancelEventButton),
          ),
        ),
      );
    }

    if (isCancelled) {
      buttons.add(
        ElevatedButton(
          onPressed: null,
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.grey),
          ),
          child: Text(l10n.eventDetailsCancelledBanner),
        ),
      );
    } else {
      buttons.add(
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('participants')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final registrationData = snapshot.data;
            final status = registrationData?.data()?['status'] as String?;

            Widget button;
            if (status == 'confirmed' || status == 'waitlisted') {
              button = Semantics(
                label: 'withdraw_button',
                child: ElevatedButton(
                  onPressed: _isWithdrawing
                      ? null
                      : () => _showWithdrawConfirmationDialog(eventData),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: _isWithdrawing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.eventDetailsWithdrawButton),
                ),
              );
            } else if (status == null || status == 'withdrawn') {
              button = Semantics(
                label: 'register_button',
                child: ElevatedButton(
                  onPressed: _isRegistering ? null : () => _showRegistrationConfirmationDialog(eventData),
                  child: _isRegistering
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.eventDetailsRegisterButton),
                ),
              );
            } else { // Handles withdrawn_penalty, requested, etc.
              button = ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: Text(l10n.eventDetailsYourStatus(_participantStatusLabel(l10n, status))),
              );
            }
            return button;
          },
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons
            .map((b) => Padding(padding: const EdgeInsets.only(top: 8.0), child: b))
            .toList(),
      ),
    );
  }

  Widget _buildCompactDetailRow({
    required IconData icon,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
