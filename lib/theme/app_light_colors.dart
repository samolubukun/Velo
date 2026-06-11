import 'package:flutter/material.dart';

class AppLightColors {
  // Brand (same across both themes)
  static const Color brand = Color(0xFFB0653B); // Burnished Copper
  static const Color brandSoft = Color(0xFFC87D55);
  static const Color brandDim = Color(0xFF8B4620);
  static const Color accent = Color(0xFF10B981); // Cyber Mint
  static const Color accentGlow = Color(0x3310B981);

  // Backgrounds - clean light
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F2F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFF9FAFB);
  static const Color scaffold = Color(0xFFF5F6FA);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  // State
  static const Color success = Color(0xFF10B981); // Mint
  static const Color warning = Color(0xFFF1C40F); // Golden Mustard
  static const Color error = Color(0xFFEF4444); // Crimson Rose
  static const Color info = Color(0xFF3498DB);

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFD1D5DB);

  // Gradients
  static const List<Color> brandGradient = [Color(0xFFC87D55), Color(0xFFB0653B)];
  static const List<Color> accentGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> surfaceGradient = [Color(0xFFFFFFFF), Color(0xFFF0F2F5)];
  static const List<Color> cardGradient = [Color(0xFFFFFFFF), Color(0xFFF9FAFB)];
}
