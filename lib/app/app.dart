import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_theme.dart';
import '../core/settings/settings.dart';
import '../services/security/app_lock_service.dart';
import 'router.dart';

/// Root of the app — Material 3 [MaterialApp] driven by the user's theme
/// preference, wrapped in a biometric lock gate when app lock is enabled.
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
      theme: AppThemeData.build(Brightness.light),
      darkTheme: AppThemeData.build(Brightness.dark),
      themeMode: settings.materialThemeMode,
      builder: (context, child) =>
          _LockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Full-screen biometric gate. Covers the UI on cold start and whenever the
/// app returns to the foreground while app lock is enabled.
class _LockGate extends ConsumerStatefulWidget {
  final Widget child;
  const _LockGate({required this.child});

  @override
  ConsumerState<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<_LockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _prompting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        ref.read(settingsProvider).appLockEnabled) {
      setState(() => _locked = true);
    }
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    _prompting = true;
    final ok = await AppLockService.instance.authenticate();
    _prompting = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(settingsProvider).appLockEnabled;

    // Lock once on first frame after settings hydrate.
    if (!_initialized && enabled) {
      _initialized = true;
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }

    if (!enabled || !_locked) return widget.child;

    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Material(
            color: cs.surface,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/logo/app-logo.png',
                        height: 72, width: 72, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                  Text('Locked',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Authenticate to open your expenses',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 72),
                    child: FilledButton.icon(
                      onPressed: _unlock,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
