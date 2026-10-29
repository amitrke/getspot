import 'package:flutter/material.dart';

/// Colors with app-specific meaning that `ColorScheme` doesn't cover:
/// success/warning/info feedback, money (credit/debit), the orange accent and
/// the wallet hero gradient. Each has light and dark values.
///
/// Read with `AppSemanticColors.of(context)` or `context.semantic`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.credit,
    required this.debit,
    required this.accent,
    required this.onAccent,
    required this.heroStart,
    required this.heroEnd,
    required this.onHero,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Positive money amounts (top-ups, refunds).
  final Color credit;

  /// Negative money amounts (event fees, penalties).
  final Color debit;

  /// Shuttle orange — use sparingly for the single most important action.
  final Color accent;
  final Color onAccent;

  /// Wallet balance hero gradient.
  final Color heroStart;
  final Color heroEnd;
  final Color onHero;

  static const light = AppSemanticColors(
    success: Color(0xFF1E7B3A),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFD5F3DC),
    onSuccessContainer: Color(0xFF0A3A18),
    warning: Color(0xFFA6510A),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFE6C4),
    onWarningContainer: Color(0xFF4A2600),
    info: Color(0xFF1D5FA8),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFFD8E6FB),
    onInfoContainer: Color(0xFF0B2A55),
    credit: Color(0xFF1E7B3A),
    debit: Color(0xFFBA1A1A),
    accent: Color(0xFFFF6523),
    onAccent: Color(0xFF240B00),
    heroStart: Color(0xFF1F6F50),
    heroEnd: Color(0xFF0F4632),
    onHero: Color(0xFFFFFFFF),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF7DD992),
    onSuccess: Color(0xFF00391A),
    successContainer: Color(0xFF15492A),
    onSuccessContainer: Color(0xFFC8F5D2),
    warning: Color(0xFFF5B86A),
    onWarning: Color(0xFF462A00),
    warningContainer: Color(0xFF5A3A06),
    onWarningContainer: Color(0xFFFFE3BF),
    info: Color(0xFF9CC3F5),
    onInfo: Color(0xFF0A2E57),
    infoContainer: Color(0xFF173E6B),
    onInfoContainer: Color(0xFFD6E6FD),
    credit: Color(0xFF7DD992),
    debit: Color(0xFFFFB4AB),
    accent: Color(0xFFFF7A40),
    onAccent: Color(0xFF240B00),
    heroStart: Color(0xFF1B5E44),
    heroEnd: Color(0xFF0C3022),
    onHero: Color(0xFFFFFFFF),
  );

  static AppSemanticColors of(BuildContext context) =>
      Theme.of(context).extension<AppSemanticColors>() ?? light;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? credit,
    Color? debit,
    Color? accent,
    Color? onAccent,
    Color? heroStart,
    Color? heroEnd,
    Color? onHero,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      credit: credit ?? this.credit,
      debit: debit ?? this.debit,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      onHero: onHero ?? this.onHero,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      info: l(info, other.info),
      onInfo: l(onInfo, other.onInfo),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      credit: l(credit, other.credit),
      debit: l(debit, other.debit),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      heroStart: l(heroStart, other.heroStart),
      heroEnd: l(heroEnd, other.heroEnd),
      onHero: l(onHero, other.onHero),
    );
  }
}
