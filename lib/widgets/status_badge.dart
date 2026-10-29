import 'package:flutter/material.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/theme/theme.dart';

/// The statuses a [StatusBadge] can show. Covers event participation and
/// group membership so both read the same everywhere.
enum StatusKind {
  confirmed,
  waitlisted,
  requested,
  denied,
  penalty,
  pending,
  notRegistered;

  /// Maps a participant `status` string from Firestore to a kind.
  static StatusKind fromParticipantStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return StatusKind.confirmed;
      case 'waitlisted':
        return StatusKind.waitlisted;
      case 'requested':
        return StatusKind.requested;
      case 'denied':
        return StatusKind.denied;
      case 'withdrawn_penalty':
        return StatusKind.penalty;
      default:
        return StatusKind.notRegistered;
    }
  }
}

/// Tinted pill showing a participation or membership status.
///
/// Color, icon and label all come from [kind], so callers never pick status
/// colors by hand.
class StatusBadge extends StatelessWidget {
  final StatusKind kind;

  /// Overrides the default localized label.
  final String? label;

  const StatusBadge({super.key, required this.kind, this.label});

  StatusBadge.fromParticipantStatus(String? status, {super.key, this.label})
    : kind = StatusKind.fromParticipantStatus(status);

  static String labelFor(AppLocalizations l10n, StatusKind kind) {
    switch (kind) {
      case StatusKind.confirmed:
        return l10n.groupItemStatusConfirmed;
      case StatusKind.waitlisted:
        return l10n.groupItemStatusWaitlisted;
      case StatusKind.requested:
        return l10n.eventDetailsStatusRequested;
      case StatusKind.denied:
        return l10n.groupItemStatusDenied;
      case StatusKind.penalty:
        return l10n.eventDetailsStatusWithdrawnPenalty;
      case StatusKind.pending:
        return l10n.groupItemPendingChip;
      case StatusKind.notRegistered:
        return l10n.groupItemStatusNotRegistered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final semantic = context.semantic;

    final (Color bg, Color fg, IconData icon) = switch (kind) {
      StatusKind.confirmed => (
        semantic.successContainer,
        semantic.onSuccessContainer,
        Icons.check_circle,
      ),
      StatusKind.waitlisted => (
        semantic.warningContainer,
        semantic.onWarningContainer,
        Icons.hourglass_top,
      ),
      StatusKind.pending => (
        semantic.warningContainer,
        semantic.onWarningContainer,
        Icons.schedule,
      ),
      StatusKind.requested => (
        semantic.infoContainer,
        semantic.onInfoContainer,
        Icons.schedule,
      ),
      StatusKind.denied || StatusKind.penalty => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.cancel,
      ),
      StatusKind.notRegistered => (
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
        Icons.radio_button_unchecked,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label ?? labelFor(l10n, kind),
            style: context.textStyles.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
