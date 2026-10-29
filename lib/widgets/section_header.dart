import 'package:flutter/material.dart';
import 'package:getspot/theme/theme.dart';

/// Title row for a section of a screen, with optional trailing actions.
class SectionHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.padding = const EdgeInsets.only(
      top: AppSpacing.sm,
      bottom: AppSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.textStyles.titleMedium)),
          ...actions,
        ],
      ),
    );
  }
}
