import 'package:flutter/material.dart';

/// Text styles with NO hardcoded color so they inherit from the active theme's
/// DefaultTextStyle (set by Scaffold via colorScheme.onSurface in Material 3).
class AppTextStyles {
  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 36, fontWeight: FontWeight.w700,
    letterSpacing: -1.0, height: 1.1,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700,
    letterSpacing: -0.8, height: 1.15,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w600,
    letterSpacing: -0.5, height: 1.2,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600,
    letterSpacing: -0.4, height: 1.25,
  );
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600,
    letterSpacing: -0.3, height: 1.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );

  static const TextStyle numericLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 40, fontWeight: FontWeight.w700,
    letterSpacing: -1.5, height: 1.0,
  );
  static const TextStyle numericMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700,
    letterSpacing: -1.0, height: 1.0,
  );
  static const TextStyle numericSmall = TextStyle(
    fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, height: 1.0,
  );
}
