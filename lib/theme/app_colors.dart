import 'package:flutter/material.dart';

/// Immutable set of surface/text/border colors for one brightness mode.
class AppColorSet {
  final Color scaffold;
  final Color surface;
  final Color surfaceAlt;
  final Color card;
  final Color cardElevated;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnBrand;
  final Color border;
  final Color borderLight;
  final List<Color> surfaceGradient;
  final List<Color> cardGradient;

  const AppColorSet({
    required this.scaffold,
    required this.surface,
    required this.surfaceAlt,
    required this.card,
    required this.cardElevated,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnBrand,
    required this.border,
    required this.borderLight,
    required this.surfaceGradient,
    required this.cardGradient,
  });
}

class AppColors {
  // ── Brand / State / Finance (same in both themes) ──────────────────
  static const Color brand         = Color(0xFFC87D55); // Burnished Copper
  static const Color brandSoft     = Color(0xFFDCA37C);
  static const Color brandDim      = Color(0xFFB0653B);
  static const Color accent        = Color(0xFF10B981); // Cyber Mint
  static const Color accentGlow    = Color(0x3310B981);

  static const Color success       = Color(0xFF10B981); // Mint
  static const Color warning       = Color(0xFFF1C40F); // Golden Mustard
  static const Color error         = Color(0xFFEF4444); // Crimson Rose
  static const Color info          = Color(0xFF3498DB);

  static const List<Color> brandGradient  = [Color(0xFFC87D55), Color(0xFFB0653B)];
  static const List<Color> accentGradient = [Color(0xFF10B981), Color(0xFF059669)];

  // ── Legacy dark statics (kept so AppTheme.dark & const widgets compile) ──
  static const Color scaffold     = Color(0xFF08080C); // Deep Obsidian
  static const Color surface      = Color(0xFF12121A); // Glassmorphic Slate
  static const Color surfaceAlt   = Color(0xFF191924);
  static const Color card         = Color(0xFF12121A);
  static const Color cardElevated = Color(0xFF1D1D2C);
  static const Color background   = Color(0xFF08080C);
  static const Color textPrimary  = Color(0xFFF5F5FA);
  static const Color textSecondary= Color(0xFF8E8E9A);
  static const Color textTertiary = Color(0xFF5E5E6E);
  static const Color textOnBrand  = Color(0xFF08080C);
  static const Color border       = Color(0xFF242432);
  static const Color borderLight  = Color(0xFF2E2E3E);
  static const List<Color> surfaceGradient = [Color(0xFF12121A), Color(0xFF191924)];
  static const List<Color> cardGradient    = [Color(0xFF12121A), Color(0xFF1D1D2C)];

  // ── Context-aware lookup ─────────────────────────────────────────────
  static AppColorSet of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  static const _dark = AppColorSet(
    scaffold:      Color(0xFF08080C),
    surface:       Color(0xFF12121A),
    surfaceAlt:    Color(0xFF191924),
    card:          Color(0xFF12121A),
    cardElevated:  Color(0xFF1D1D2C),
    background:    Color(0xFF08080C),
    textPrimary:   Color(0xFFF5F5FA),
    textSecondary: Color(0xFF8E8E9A),
    textTertiary:  Color(0xFF5E5E6E),
    textOnBrand:   Color(0xFF08080C),
    border:        Color(0xFF242432),
    borderLight:   Color(0xFF2E2E3E),
    surfaceGradient: [Color(0xFF12121A), Color(0xFF191924)],
    cardGradient:    [Color(0xFF12121A), Color(0xFF1D1D2C)],
  );

  static const _light = AppColorSet(
    scaffold:      Color(0xFFF5F6FA),
    surface:       Color(0xFFFFFFFF),
    surfaceAlt:    Color(0xFFF0F2F5),
    card:          Color(0xFFFFFFFF),
    cardElevated:  Color(0xFFF9FAFB),
    background:    Color(0xFFF5F6FA),
    textPrimary:   Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textTertiary:  Color(0xFF9CA3AF),
    textOnBrand:   Color(0xFFFFFFFF),
    border:        Color(0xFFE5E7EB),
    borderLight:   Color(0xFFD1D5DB),
    surfaceGradient: [Color(0xFFFFFFFF), Color(0xFFF0F2F5)],
    cardGradient:    [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
  );
}
