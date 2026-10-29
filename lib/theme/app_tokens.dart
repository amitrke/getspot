import 'package:flutter/material.dart';

/// Raw brand palette ("Court & Shuttle").
///
/// Screens should not use these directly — read colors from
/// `Theme.of(context).colorScheme` or [AppSemanticColors] instead, so light
/// and dark mode both work. These exist so the theme has one source of truth.
abstract final class AppPalette {
  // Brand
  static const Color courtGreen = Color(0xFF1F6F50);
  static const Color courtGreenDark = Color(0xFF134A36);
  static const Color courtGreenLight = Color(0xFF84D8B0);
  static const Color shuttleOrange = Color(0xFFFF6523);
  static const Color slate = Color(0xFF4C6971);

  // Light neutrals
  static const Color surfaceLight = Color(0xFFF7F8F5);
  static const Color onSurfaceLight = Color(0xFF181D1A);
  static const Color outlineVariantLight = Color(0xFFDCE2DC);

  // Dark neutrals
  static const Color surfaceDark = Color(0xFF0F1512);
  static const Color onSurfaceDark = Color(0xFFDEE4DF);
  static const Color outlineVariantDark = Color(0xFF2E3833);
}

/// 4-pt spacing scale. Use for paddings, margins and gaps.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard horizontal page gutter.
  static const EdgeInsets page = EdgeInsets.all(lg);
}

/// Corner radius scale.
abstract final class AppRadius {
  /// Chips, badges' inner elements, small inputs.
  static const double sm = 8;

  /// Buttons, inputs, snackbars, date tiles.
  static const double md = 12;

  /// Cards and list containers.
  static const double lg = 16;

  /// Dialogs, bottom sheets, hero surfaces.
  static const double xl = 24;

  /// Pills (status badges).
  static const double full = 999;

  static BorderRadius circular(double r) =>
      BorderRadius.all(Radius.circular(r));
}

/// Window-width breakpoints (Material 3 window size classes).
abstract final class AppBreakpoints {
  /// Below this: phones in portrait.
  static const double compact = 600;

  /// Below this: small tablets, phones in landscape.
  static const double medium = 840;

  /// Below this: large tablets, small laptops. Above: desktop.
  static const double expanded = 1200;
}

/// Maximum widths for page content on wide windows. Wrap screen bodies in
/// `ConstrainedContent` with one of these.
abstract final class AppContentWidth {
  /// Forms and sign-in flows.
  static const double form = 560;

  /// Lists, details and most screens.
  static const double reading = 720;

  /// Dashboards or multi-column layouts.
  static const double wide = 1040;
}

/// Minimum interactive sizes (Material/WCAG touch targets).
abstract final class AppSizes {
  static const double buttonHeight = 48;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double avatar = 40;
}
