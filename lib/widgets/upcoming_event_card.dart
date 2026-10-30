import 'package:flutter/material.dart';
import 'package:getspot/helpers/event_registration.dart';
import 'package:getspot/l10n/app_localizations.dart';
import 'package:getspot/providers/participant_provider.dart';
import 'package:getspot/screens/event_details_screen.dart';
import 'package:getspot/services/upcoming_events_service.dart';
import 'package:getspot/theme/theme.dart';
import 'package:getspot/widgets/date_tile.dart';
import 'package:getspot/widgets/status_badge.dart';
import 'package:intl/intl.dart';

/// Home card for an upcoming event: date, time, place, group, capacity, the
/// user's status, and a one-tap Register / Join waitlist action when they
/// aren't signed up yet. Tapping the card opens Event Details.
class UpcomingEventCard extends StatefulWidget {
  final UpcomingEvent event;
  final ParticipantProvider? participantProvider;

  const UpcomingEventCard({
    super.key,
    required this.event,
    this.participantProvider,
  });

  @override
  State<UpcomingEventCard> createState() => _UpcomingEventCardState();
}

class _UpcomingEventCardState extends State<UpcomingEventCard> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    widget.participantProvider?.subscribeToEvent(widget.event.id);
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          eventId: widget.event.id,
          isGroupAdmin: widget.event.isGroupAdmin,
        ),
      ),
    );
  }

  void _register() {
    startEventRegistration(
      context,
      eventId: widget.event.id,
      eventData: widget.event.data,
      onSubmitting: (submitting) {
        if (mounted) setState(() => _submitting = submitting);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final event = widget.event;
    final date = event.eventDate;

    final meta = [
      if (date != null) DateFormat.E(locale).add_jm().format(date),
      if (event.location?.isNotEmpty ?? false) event.location!,
      if (event.groupName.isNotEmpty) event.groupName,
    ].join(' · ');

    final capacity = event.maxParticipants > 0
        ? (event.confirmedCount / event.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: InkWell(
        onTap: _openDetails,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateTile(date: date),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name ?? l10n.groupDetailsUnnamedEvent,
                      style: context.textStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      meta,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.maxParticipants > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: capacity,
                              minHeight: 6,
                              borderRadius: AppRadius.circular(3),
                              backgroundColor: colors.surfaceContainerHigh,
                              color: event.isFull
                                  ? context.semantic.warning
                                  : colors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            event.isFull
                                ? l10n.homeEventFull(event.waitlistCount)
                                : l10n.homeSpotsTaken(
                                    event.confirmedCount,
                                    event.maxParticipants,
                                  ),
                            style: context.textStyles.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _buildStatusRow(context, l10n, locale),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    final provider = widget.participantProvider;
    if (provider == null) {
      return const StatusBadge(kind: StatusKind.notRegistered);
    }
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final status =
            provider.getParticipantStatus(widget.event.id)?['status']
                as String?;
        final canRegister = status == null || status == 'withdrawn';
        return Row(
          children: [
            StatusBadge.fromParticipantStatus(status),
            const Spacer(),
            if (canRegister) _buildRegisterButton(l10n, locale),
          ],
        );
      },
    );
  }

  Widget _buildRegisterButton(AppLocalizations l10n, String locale) {
    final event = widget.event;
    final fee = '\$${NumberFormat('0.##', locale).format(event.fee)}';
    final label = event.isFull
        ? '${l10n.eventDetailsJoinWaitlistButton} · $fee'
        : '${l10n.eventDetailsRegisterButton} · $fee';
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
    final child = _submitting
        ? const SizedBox.square(
            dimension: AppSizes.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);
    final onPressed = _submitting ? null : _register;

    return event.isFull
        ? FilledButton.tonal(onPressed: onPressed, style: style, child: child)
        : FilledButton(onPressed: onPressed, style: style, child: child);
  }
}
