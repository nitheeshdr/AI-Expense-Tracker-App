import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/app_theme.dart';
import '../utils/haptics.dart';

/// Theme preference: follow the system, or force light/dark.
enum AppThemeMode { system, light, dark }

/// Selectable accent (seed) colors for the Material 3 scheme.
class AccentColors {
  AccentColors._();
  static const List<int> options = [
    0xFF7C6BFF, // violet (default)
    0xFF2F7CF6, // blue
    0xFF12B98C, // green
    0xFFEC5C8E, // pink
    0xFFFF8A4C, // orange
    0xFF8B5CF6, // purple
  ];
}

/// Immutable snapshot of user preferences.
@immutable
class AppSettings {
  final AppThemeMode themeMode;
  final int accentColor;
  final String currency;
  final String userName;
  final bool onboarded;
  final bool hapticsEnabled;
  final bool animationsEnabled;
  final bool hideBalances;
  final double monthlyBudget;

  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.accentColor = 0xFF7C6BFF,
    this.currency = 'INR',
    this.userName = 'there',
    this.onboarded = false,
    this.hapticsEnabled = true,
    this.animationsEnabled = true,
    this.hideBalances = false,
    this.monthlyBudget = 45000,
  });

  /// Back-compat helper used where a binary dark/light is needed.
  AppBrightness get brightness =>
      themeMode == AppThemeMode.light ? AppBrightness.light : AppBrightness.dark;

  ThemeMode get materialThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  AppSettings copyWith({
    AppThemeMode? themeMode,
    int? accentColor,
    String? currency,
    String? userName,
    bool? onboarded,
    bool? hapticsEnabled,
    bool? animationsEnabled,
    bool? hideBalances,
    double? monthlyBudget,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        accentColor: accentColor ?? this.accentColor,
        currency: currency ?? this.currency,
        userName: userName ?? this.userName,
        onboarded: onboarded ?? this.onboarded,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        animationsEnabled: animationsEnabled ?? this.animationsEnabled,
        hideBalances: hideBalances ?? this.hideBalances,
        monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      );
}

/// Persists [AppSettings] to SharedPreferences and the Groq key to secure
/// storage. Exposed as a Riverpod Notifier.
class SettingsController extends Notifier<AppSettings> {
  static const _kThemeMode = 'themeMode';
  static const _kAccent = 'accentColor';
  static const _kCurrency = 'currency';
  static const _kUserName = 'userName';
  static const _kOnboarded = 'onboarded';
  static const _kHaptics = 'haptics';
  static const _kAnimations = 'animations';
  static const _kHideBalances = 'hideBalances';
  static const _kBudget = 'monthlyBudget';
  static const _kGroqKey = 'groq_api_key';

  final _secure = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  @override
  AppSettings build() => const AppSettings();

  Future<void> load() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final modeName = prefs.getString(_kThemeMode) ?? 'dark';
    final loaded = AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => AppThemeMode.dark,
      ),
      accentColor: prefs.getInt(_kAccent) ?? 0xFF7C6BFF,
      currency: prefs.getString(_kCurrency) ?? 'INR',
      userName: prefs.getString(_kUserName) ?? 'there',
      onboarded: prefs.getBool(_kOnboarded) ?? false,
      hapticsEnabled: prefs.getBool(_kHaptics) ?? true,
      animationsEnabled: prefs.getBool(_kAnimations) ?? true,
      hideBalances: prefs.getBool(_kHideBalances) ?? false,
      monthlyBudget: prefs.getDouble(_kBudget) ?? 45000,
    );
    Haptics.enabled = loaded.hapticsEnabled;
    state = loaded;
  }

  Future<void> _persist(AppSettings s) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, s.themeMode.name);
    await prefs.setInt(_kAccent, s.accentColor);
    await prefs.setString(_kCurrency, s.currency);
    await prefs.setString(_kUserName, s.userName);
    await prefs.setBool(_kOnboarded, s.onboarded);
    await prefs.setBool(_kHaptics, s.hapticsEnabled);
    await prefs.setBool(_kAnimations, s.animationsEnabled);
    await prefs.setBool(_kHideBalances, s.hideBalances);
    await prefs.setDouble(_kBudget, s.monthlyBudget);
    Haptics.enabled = s.hapticsEnabled;
  }

  Future<void> update(AppSettings Function(AppSettings) fn) async {
    final next = fn(state);
    state = next;
    await _persist(next);
  }

  void setThemeMode(AppThemeMode mode) => update((s) => s.copyWith(themeMode: mode));
  void setAccent(int color) => update((s) => s.copyWith(accentColor: color));

  // --- Groq API key (secure storage) ---
  Future<String?> groqKey() => _secure.read(key: _kGroqKey);
  Future<void> setGroqKey(String key) =>
      _secure.write(key: _kGroqKey, value: key);
  Future<void> clearGroqKey() => _secure.delete(key: _kGroqKey);
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
