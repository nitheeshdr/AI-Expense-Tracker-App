import 'dart:ui';

/// Raw color palette. Semantic mapping lives in [AppTheme].
/// All values are hand-tuned for a premium, fintech dark-first aesthetic.
class AppPalette {
  AppPalette._();

  // Brand / accent
  static const Color violet = Color(0xFF7C6BFF);
  static const Color violetDeep = Color(0xFF5B49E8);
  static const Color iris = Color(0xFF9D8BFF);
  static const Color mint = Color(0xFF34E0B0);
  static const Color mintDeep = Color(0xFF12B98C);
  static const Color coral = Color(0xFFFF6B7D);
  static const Color amber = Color(0xFFFFB23E);
  static const Color sky = Color(0xFF4DB6FF);

  // Dark surfaces
  static const Color ink900 = Color(0xFF0A0A0F);
  static const Color ink850 = Color(0xFF0E0E16);
  static const Color ink800 = Color(0xFF13131D);
  static const Color ink700 = Color(0xFF1A1A28);
  static const Color ink600 = Color(0xFF242436);
  static const Color ink500 = Color(0xFF2F2F45);

  // Light surfaces
  static const Color paper0 = Color(0xFFFBFBFD);
  static const Color paper50 = Color(0xFFF3F3F8);
  static const Color paper100 = Color(0xFFEAEAF2);
  static const Color paper200 = Color(0xFFDEDEEA);

  // Neutral text
  static const Color white = Color(0xFFFFFFFF);
  static const Color slate100 = Color(0xFFEDEDF5);
  static const Color slate300 = Color(0xFFB9B9CC);
  static const Color slate400 = Color(0xFF8E8EA8);
  static const Color slate500 = Color(0xFF6C6C85);
  static const Color slate700 = Color(0xFF3A3A4D);
  static const Color slate900 = Color(0xFF14141C);

  static const Color transparent = Color(0x00000000);
}
