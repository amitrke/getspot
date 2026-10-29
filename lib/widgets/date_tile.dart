import 'package:flutter/material.dart';
import 'package:getspot/theme/theme.dart';
import 'package:intl/intl.dart';

/// Calendar-style month/day block used at the start of event cards.
class DateTile extends StatelessWidget {
  final DateTime? date;

  const DateTile({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            date != null
                ? DateFormat.MMM(locale).format(date!).toUpperCase()
                : '-',
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            date != null ? DateFormat.d(locale).format(date!) : '',
            style: context.textStyles.headlineSmall?.tabular.copyWith(
              color: colors.onPrimaryContainer,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
