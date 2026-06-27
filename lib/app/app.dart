import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_theme.dart';
import '../core/settings/settings.dart';
import 'router.dart';

/// Root of the app — Material 3 [MaterialApp] driven by the user's theme
/// preference.
class AiExpenseApp extends ConsumerWidget {
  const AiExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'AI Expense Tracker',
      theme: AppThemeData.build(Brightness.light, seed: settings.accentColor),
      darkTheme: AppThemeData.build(Brightness.dark, seed: settings.accentColor),
      themeMode: settings.materialThemeMode,
    );
  }
}
