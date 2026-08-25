import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:getspot/l10n/app_localizations.dart';

/// A widget that displays the app logo from an SVG asset.
///
/// This logo is a vector graphic, so it is scalable and efficient.
class AppLogo extends StatelessWidget {
  final double size;

  /// Creates a logo widget with a given [size].
  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/logo.svg',
        semanticsLabel: AppLocalizations.of(context)!.appLogoSemanticLabel,
      ),
    );
  }
}