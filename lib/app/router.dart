import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/spacing.dart';
import '../core/settings/settings.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/home_shell.dart';

/// App routes. First run shows the SMS-permission onboarding; afterwards the
/// app opens straight on the home shell showing real (SMS-imported) data.
final routerProvider = Provider<GoRouter>((ref) {
  final onboarded = ref.read(settingsProvider).onboarded;
  return GoRouter(
    initialLocation: onboarded ? '/home' : '/onboarding',
    routes: [
      _fade('/onboarding', const OnboardingScreen()),
      _fade('/home', const HomeShell()),
    ],
    // Any unexpected location (e.g. a stray widget deep link) → home, never a
    // "page not found" screen.
    errorBuilder: (context, state) => const HomeShell(),
    redirect: (context, state) {
      const known = {'/home', '/onboarding'};
      if (!known.contains(state.matchedLocation)) {
        return ref.read(settingsProvider).onboarded ? '/home' : '/onboarding';
      }
      return null;
    },
  );
});

GoRoute _fade(String path, Widget child) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondary, c) =>
          FadeTransition(opacity: animation, child: c),
    ),
  );
}

const double kScreenPad = AppSpacing.screenH;
