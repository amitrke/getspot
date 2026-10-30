import 'package:flutter/material.dart';
import 'package:getspot/theme/theme.dart';

/// Caps [child] at [maxWidth] and centers it horizontally, so screens don't
/// stretch edge to edge on tablets, desktop and web. On phones it's a no-op.
class ConstrainedContent extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ConstrainedContent({
    super.key,
    this.maxWidth = AppContentWidth.reading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
