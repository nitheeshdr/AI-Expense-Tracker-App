import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

enum AppBrightness { dark, light }

/// Builds the app's Material 3 [ThemeData] from a violet seed color.
class AppThemeData {
  AppThemeData._();

  static ThemeData build(Brightness brightness, {int? seed}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(seed ?? AppPalette.violet.toARGB32()),
      brightness: brightness,
    );
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

/// Semantic color bridge. Derives app tokens from the active Material 3
/// [ColorScheme] so existing screen code (`c.accent`, `c.surface`, …) keeps
/// working while rendering true Material 3 tonal colors.
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
  Color get accentSoft => scheme.primaryContainer.withValues(alpha: 0.5);
  Color get onAccent => scheme.onPrimary;
  Color get income => isDark ? AppPalette.mint : AppPalette.mintDeep;
  Color get expense => scheme.error;
  Color get warning => AppPalette.amber;
  Color get info => AppPalette.sky;
  Color get shadow => Colors.black;

  /// Solid accent "gradient" (single color) — the app uses flat fills, not
  /// gradients, so this keeps the API while rendering a solid color.
  Gradient get accentGradient =>
      LinearGradient(colors: [scheme.primary, scheme.primary]);

  Gradient get surfaceGradient =>
      LinearGradient(colors: [surface, surface]);
}

/// Back-compat shim: older code referenced `AppTheme.of(context)`.
class AppTheme {
  static AppColors of(BuildContext context) => AppColors.of(context);
}
