import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/theme/theme.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

/// Shared "register for an event" flow, used by Event Details and the Home
/// upcoming-games cards so both show the same wallet checks and dialogs.
///
/// Looks up the user's group balance and the group's negative-balance limit,
/// shows the matching confirmation (normal, low balance, insufficient, or
/// waitlist), then writes the participant request with status `requested`.
/// The `processEventRegistration` trigger decides the final status.
///
/// [onSubmitting] is called with true while the request is being written and
/// false when it finishes, so callers can show a spinner.
Future<void> startEventRegistration(
  BuildContext context, {
  required String eventId,
  required Map<String, dynamic> eventData,
  ValueChanged<bool>? onSubmitting,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final groupId = eventData['groupId'] as String;
    final fee = (eventData['fee'] as num?)?.toDouble() ?? 0.0;

    final memberDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(user.uid)
        .get();

    if (!memberDoc.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.eventDetailsNotAMember),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final walletBalance =
        (memberDoc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
    final newBalance = walletBalance - fee;

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();
    final negativeBalanceLimit =
        (groupDoc.data()?['negativeBalanceLimit'] as num?)?.toDouble() ?? 0.0;

    final confirmedCount = eventData['confirmedCount'] ?? 0;
    final maxParticipants = eventData['maxParticipants'] ?? 0;
    final isFull = confirmedCount >= maxParticipants;

    if (!context.mounted) return;

    bool? confirmed;
    if (isFull) {
      confirmed = await _showWaitlistDialog(
        context,
        fee: fee,
        currentBalance: walletBalance,
        newBalance: newBalance,
      );
    } else if (newBalance < -negativeBalanceLimit) {
      await _showInsufficientBalanceDialog(
        context,
        fee: fee,
        currentBalance: walletBalance,
        newBalance: newBalance,
        negativeLimit: negativeBalanceLimit,
      );
      return;
    } else if (newBalance < 0) {
      confirmed = await _showNegativeBalanceDialog(
        context,
        eventData: eventData,
        fee: fee,
        currentBalance: walletBalance,
        newBalance: newBalance,
        negativeLimit: negativeBalanceLimit,
      );
    } else {
      confirmed = await _showNormalDialog(
        context,
        eventData: eventData,
        fee: fee,
        currentBalance: walletBalance,
        newBalance: newBalance,
      );
    }

    if (confirmed == true && context.mounted) {
      await _submitRegistration(context, eventId, onSubmitting);
    }
  } catch (e, st) {
    developer.log(
      'Error showing registration dialog',
      name: 'EventRegistration',
      error: e,
      stackTrace: st,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.eventDetailsGenericError(e.toString()),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// Formats a dollar amount with the locale-correct decimal separator,
/// keeping the literal "$" prefix (not itself a translation concern) and
/// putting the sign first: `-$10.00`, not `$-10.00`.
String formatDollars(BuildContext context, double amount) {
  final locale = Localizations.localeOf(context).toString();
  final digits = NumberFormat('0.00', locale).format(amount.abs());
  return amount < 0 ? '-\$$digits' : '\$$digits';
}

String _fmtAmount(BuildContext context, double amount) =>
    formatDollars(context, amount);

Future<void> _showInsufficientBalanceDialog(
  BuildContext context, {
  required double fee,
  required double currentBalance,
  required double newBalance,
  required double negativeLimit,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      final error = Theme.of(dialogContext).colorScheme.error;
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: error),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.eventDetailsInsufficientBalanceTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.eventDetailsCurrentBalanceAmount(
                _fmtAmount(dialogContext, currentBalance),
              ),
            ),
            Text(
              l10n.eventDetailsEventFeeAmount(_fmtAmount(dialogContext, fee)),
            ),
            Text(
              l10n.eventDetailsNewBalanceAmount(
                _fmtAmount(dialogContext, newBalance),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.eventDetailsAllowedNegativeLimit(
                _fmtAmount(dialogContext, negativeLimit),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.eventDetailsInsufficientBalanceMessage,
              style: TextStyle(color: error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonOk),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showNormalDialog(
  BuildContext context, {
  required Map<String, dynamic> eventData,
  required double fee,
  required double currentBalance,
  required double newBalance,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      return AlertDialog(
        title: Text(l10n.eventDetailsRegisterTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventData['name'] ?? l10n.eventDetailsFallbackEventName,
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.eventDetailsEventFeeAmount(_fmtAmount(dialogContext, fee)),
            ),
            const Divider(height: AppSpacing.xl),
            Text(
              l10n.eventDetailsCurrentBalanceAmount(
                _fmtAmount(dialogContext, currentBalance),
              ),
            ),
            Text(
              l10n.eventDetailsNewBalanceAmount(
                _fmtAmount(dialogContext, newBalance),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.eventDetailsConfirmRegistrationButton),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showNegativeBalanceDialog(
  BuildContext context, {
  required Map<String, dynamic> eventData,
  required double fee,
  required double currentBalance,
  required double newBalance,
  required double negativeLimit,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      final semantic = AppSemanticColors.of(dialogContext);
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: semantic.warning),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.eventDetailsLowBalanceWarningTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventData['name'] ?? l10n.eventDetailsFallbackEventName,
              style: Theme.of(dialogContext).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.eventDetailsEventFeeAmount(_fmtAmount(dialogContext, fee)),
            ),
            const Divider(height: AppSpacing.xl),
            Text(
              l10n.eventDetailsCurrentBalanceAmount(
                _fmtAmount(dialogContext, currentBalance),
              ),
            ),
            Text(
              l10n.eventDetailsNewBalanceNegative(
                _fmtAmount(dialogContext, newBalance),
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: semantic.warning,
              ),
            ),
            Text(
              l10n.eventDetailsAllowedLimit(
                _fmtAmount(dialogContext, negativeLimit),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.eventDetailsNegativeBalanceWarning,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: semantic.warning,
              foregroundColor: semantic.onWarning,
            ),
            child: Text(l10n.eventDetailsUnderstandRegisterButton),
          ),
        ],
      );
    },
  );
}

Future<bool?> _showWaitlistDialog(
  BuildContext context, {
  required double fee,
  required double currentBalance,
  required double newBalance,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.hourglass_top,
              color: AppSemanticColors.of(dialogContext).info,
            ),
            const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.eventDetailsWaitlistFeeInfo(_fmtAmount(dialogContext, fee)),
            ),
            const Divider(height: AppSpacing.xl),
            Text(
              l10n.eventDetailsCurrentBalanceAmount(
                _fmtAmount(dialogContext, currentBalance),
              ),
            ),
            Text(
              l10n.eventDetailsNewBalanceAmount(
                _fmtAmount(dialogContext, newBalance),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.eventDetailsAutoConfirmInfo,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.eventDetailsJoinWaitlistButton),
          ),
        ],
      );
    },
  );
}

Future<void> _submitRegistration(
  BuildContext context,
  String eventId,
  ValueChanged<bool>? onSubmitting,
) async {
  final l10n = AppLocalizations.of(context)!;
  final semantic = AppSemanticColors.of(context);
  final errorColor = Theme.of(context).colorScheme.error;
  final messenger = ScaffoldMessenger.of(context);
  onSubmitting?.call(true);

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception(l10n.eventDetailsMustBeLoggedInRegister);
    }

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'displayName': user.displayName ?? l10n.commonNoName,
          'photoURL': user.photoURL,
          'status': 'requested',
          'registeredAt': FieldValue.serverTimestamp(),
        });

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.eventDetailsRegistrationSubmitted),
        backgroundColor: semantic.success,
      ),
    );
  } catch (e, st) {
    developer.log(
      'Error registering for event',
      name: 'EventRegistration',
      error: e,
      stackTrace: st,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.eventDetailsErrorSubmittingRequest(e.toString())),
        backgroundColor: errorColor,
      ),
    );
  } finally {
    onSubmitting?.call(false);
  }
}
