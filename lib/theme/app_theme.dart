import 'package:flutter/material.dart';
import 'package:getspot/theme/app_semantic_colors.dart';
import 'package:getspot/theme/app_tokens.dart';

/// Builds the app's light and dark [ThemeData] from the design tokens.
///
/// Component themes live here so screens can use stock Material widgets
/// (Card, FilledButton, TextField, Chip…) without per-call styling.
/// See docs/DESIGN_SYSTEM.md.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme, AppSemanticColors.light);
  static ThemeData get dark => _build(_darkScheme, AppSemanticColors.dark);

  static final ColorScheme _lightScheme =
      ColorScheme.fromSeed(
        seedColor: AppPalette.courtGreen,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: AppPalette.courtGreen,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFBDEFD5),
        onPrimaryContainer: const Color(0xFF002116),
        secondary: AppPalette.slate,
        onSecondary: Colors.white,
        tertiary: const Color(0xFF9C3F12),
        tertiaryContainer: const Color(0xFFFFDBCC),
        onTertiaryContainer: const Color(0xFF370E00),
        surface: AppPalette.surfaceLight,
        onSurface: AppPalette.onSurfaceLight,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF1F4EF),
        surfaceContainer: const Color(0xFFECEFEA),
        surfaceContainerHigh: const Color(0xFFE6E9E4),
        surfaceContainerHighest: const Color(0xFFE0E4DE),
        outlineVariant: AppPalette.outlineVariantLight,
      );

  static final ColorScheme _darkScheme =
      ColorScheme.fromSeed(
        seedColor: AppPalette.courtGreen,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: AppPalette.courtGreenLight,
        onPrimary: const Color(0xFF003825),
        primaryContainer: const Color(0xFF00513A),
        onPrimaryContainer: const Color(0xFFA6F2CC),
        tertiary: const Color(0xFFFFB596),
        surface: AppPalette.surfaceDark,
        onSurface: AppPalette.onSurfaceDark,
        surfaceContainerLowest: const Color(0xFF0A0F0C),
        surfaceContainerLow: const Color(0xFF161D19),
        surfaceContainer: const Color(0xFF1A211D),
        surfaceContainerHigh: const Color(0xFF252B28),
        surfaceContainerHighest: const Color(0xFF2F3632),
        outlineVariant: AppPalette.outlineVariantDark,
      );

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
    );
    // ThemeData.textTheme only carries colors; Theme.of merges font sizes in
    // later. Merge the geometry now so component themes (app bar, dialogs,
    // list tiles) get real sizes too.
    final geometry = Typography.material2021(
      platform: base.platform,
    ).englishLike;
    final text = _textTheme(geometry.merge(base.textTheme));

    final buttonShape = RoundedRectangleBorder(
      borderRadius: AppRadius.circular(AppRadius.md),
    );
    const buttonMinSize = Size(64, AppSizes.buttonHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

    OutlineInputBorder inputBorder([Color? color, double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
          borderSide: color == null
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.brightness == Brightness.light
            ? scheme.surfaceContainerLowest
            : scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      // Legacy ElevatedButtons render like primary FilledButtons so unmigrated
      // screens still match the system.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: semantic.accent,
        foregroundColor: semantic.onAccent,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.lg),
        ),
        extendedTextStyle: text.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: inputBorder(),
        enabledBorder: inputBorder(),
        disabledBorder: inputBorder(),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.sm),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

/// Text style helpers for values that need tabular digits (money, counts).
extension AppTextStyles on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// Shorthands for reading the theme inside build methods.
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppSemanticColors get semantic => AppSemanticColors.of(this);
}
