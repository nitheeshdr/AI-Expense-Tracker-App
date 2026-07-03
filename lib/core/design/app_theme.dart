import 'package:flutter/material.dart';

import 'typography.dart';

enum AppBrightness { dark, light }

/// Builds the app's Material 3 [ThemeData] as a pure monochrome (black &
/// white) system. Dark mode uses true #000000 surfaces for AMOLED displays;
/// light mode is pure white with black ink.
class AppThemeData {
  AppThemeData._();

  /// Hand-built monochrome scheme. No hues anywhere — only black, white and
  /// gray steps, so the app reads as a clean two-tone product and dark mode
  /// saves power on AMOLED panels.
  static ColorScheme _monoScheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    final ink = dark ? white : black;
    final paper = dark ? black : white;

    Color gray(int v) => Color(0xFF000000 | (v << 16) | (v << 8) | v);

    return ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: paper,
      primaryContainer: dark ? gray(0x24) : gray(0xE8),
      onPrimaryContainer: ink,
      secondary: dark ? gray(0xD4) : gray(0x2A),
      onSecondary: paper,
      secondaryContainer: dark ? gray(0x1C) : gray(0xEF),
      onSecondaryContainer: ink,
      tertiary: dark ? gray(0xA8) : gray(0x55),
      onTertiary: paper,
      tertiaryContainer: dark ? gray(0x17) : gray(0xF3),
      onTertiaryContainer: ink,
      error: ink,
      onError: paper,
      errorContainer: dark ? gray(0x24) : gray(0xE8),
      onErrorContainer: ink,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: dark ? gray(0xB8) : gray(0x4A),
      surfaceContainerLowest: paper,
      surfaceContainerLow: dark ? gray(0x0E) : gray(0xF7),
      surfaceContainer: dark ? gray(0x14) : gray(0xF2),
      surfaceContainerHigh: dark ? gray(0x1A) : gray(0xEC),
      surfaceContainerHighest: dark ? gray(0x22) : gray(0xE5),
      outline: dark ? gray(0x55) : gray(0x9E),
      outlineVariant: dark ? gray(0x2E) : gray(0xDD),
      shadow: black,
      scrim: black,
      inverseSurface: ink,
      onInverseSurface: paper,
      inversePrimary: paper,
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData build(Brightness brightness, {int? seed}) {
    final scheme = _monoScheme(brightness);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: AppType.fontFamily,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}

/// Semantic color bridge. Fully monochrome: every token maps to black/white
/// or a gray step derived from the active scheme, so existing screen code
/// (`c.accent`, `c.income`, …) renders two-tone without edits.
class AppColors {
  final ColorScheme scheme;
  const AppColors(this.scheme);

  static AppColors of(BuildContext context) =>
      AppColors(Theme.of(context).colorScheme);

  bool get isDark => scheme.brightness == Brightness.dark;

  Color get background => scheme.surface;
  Color get backgroundAlt => scheme.surfaceContainerLowest;
  Color get surface => scheme.surfaceContainerLow;
  Color get surfaceElevated => scheme.surfaceContainerHigh;
  Color get surfaceGlass => scheme.surfaceContainer.withValues(alpha: 0.7);
  Color get hairline => scheme.outlineVariant.withValues(alpha: 0.6);
  Color get textPrimary => scheme.onSurface;
  Color get textSecondary => scheme.onSurfaceVariant;
  Color get textTertiary => scheme.onSurfaceVariant.withValues(alpha: 0.65);
  Color get accent => scheme.primary;
  Color get accentDeep => scheme.primary;
  Color get accentSoft => scheme.onSurface.withValues(alpha: 0.08);
  Color get onAccent => scheme.onPrimary;
  // Monochrome semantics: direction is conveyed by +/− signs and arrow icons,
  // not hue. Income is full ink; expense slightly softened.
  Color get income => scheme.onSurface;
  Color get expense => scheme.onSurfaceVariant;
  Color get warning => scheme.onSurfaceVariant;
  Color get info => scheme.onSurfaceVariant;
  Color get shadow => Colors.black;

  /// Grayscale ladder for charts/legends where series need distinct steps.
  Color monoShade(int index) {
    const steps = [1.0, 0.78, 0.60, 0.45, 0.32, 0.22, 0.15];
    final a = steps[index % steps.length];
    return scheme.onSurface.withValues(alpha: a);
  }

  Gradient get accentGradient =>
      LinearGradient(colors: [scheme.primary, scheme.primary]);

  Gradient get surfaceGradient =>
      LinearGradient(colors: [surface, surface]);
}

/// Back-compat shim: older code referenced `AppTheme.of(context)`.
class AppTheme {
  static AppColors of(BuildContext context) => AppColors.of(context);
}
