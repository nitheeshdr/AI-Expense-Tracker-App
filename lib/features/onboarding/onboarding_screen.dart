import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/spacing.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/formatters.dart';
import '../sms_import/sms_import_controller.dart';

/// First-run onboarding: pick currency + monthly budget, then grant SMS access
/// so transactions import automatically.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _currency = 'INR';
  double _budget = 30000;

  static const _currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED'];
  static const List<double> _budgets = [15000, 30000, 50000, 75000, 100000];

  Future<void> _saveSetup() async {
    await ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(currency: _currency, monthlyBudget: _budget),
        );
  }

  Future<void> _finish() async {
    await _saveSetup();
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(onboarded: true));
    if (mounted) context.go('/home');
  }

  Future<void> _grantAndImport() async {
    await _saveSetup();
    await ref.read(smsImportProvider.notifier).importInbox();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(smsImportProvider);
    final busy = state.phase == SmsImportPhase.requesting ||
        state.phase == SmsImportPhase.importing;

    ref.listen(smsImportProvider, (prev, next) {
      if (next.phase == SmsImportPhase.done) _finish();
    });

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Soft premium glow behind the hero — deliberately subtle, not a
          // hard-edged shape.
          Positioned(
            top: -140,
            right: -100,
            child: _Glow(color: cs.primary, size: 320),
          ),
          Positioned(
            top: 60,
            left: -120,
            child: _Glow(color: cs.tertiary, size: 260),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, AppSpacing.xxl),
              children: [
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.18),
                          blurRadius: 28,
                          spreadRadius: -4,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      child: Image.asset(
                        'assets/logo/app-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'AI Expense Tracker',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track smarter. Spend wiser.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FeaturePill(
                        icon: Icons.lock_outline, label: 'On-device'),
                    const SizedBox(width: AppSpacing.sm),
                    _FeaturePill(
                        icon: Icons.auto_awesome, label: 'AI insights'),
                    const SizedBox(width: AppSpacing.sm),
                    _FeaturePill(
                        icon: Icons.bolt_outlined, label: 'Auto-import'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                _SectionCard(
                  cs: cs,
                  children: [
                    Text('CURRENCY',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final code in _currencies)
                          _SelectPill(
                            // Some symbols (AED) are just the code itself
                            // with a trailing space — showing "$symbol $code"
                            // unconditionally would duplicate it.
                            label: (Money.symbols[code] ?? '').trim() == code
                                ? code
                                : '${Money.symbols[code] ?? ''} $code',
                            selected: _currency == code,
                            cs: cs,
                            onTap: () => setState(() => _currency = code),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                _SectionCard(
                  cs: cs,
                  children: [
                    Text('MONTHLY BUDGET',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final b in _budgets)
                          _SelectPill(
                            label: Money.format(b,
                                code: _currency, compact: true),
                            selected: _budget == b,
                            cs: cs,
                            onTap: () => setState(() => _budget = b),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                if (state.message != null && state.phase != SmsImportPhase.done)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(state.message!,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ),

                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.32),
                        blurRadius: 20,
                        spreadRadius: -4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: busy ? null : _grantAndImport,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.sms_outlined),
                    label: Text(busy ? 'Reading SMS…' : 'Grant SMS access & start'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: busy ? null : _finish,
                    child: const Text('Skip SMS — set up manually'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Your data never leaves your device',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Built with ',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        Icon(Icons.favorite, size: 14, color: cs.error),
                        Text(' by',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Image.asset(
                      theme.brightness == Brightness.dark
                          ? 'asset/white.png'
                          : 'asset/black.png',
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.16), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final ColorScheme cs;
  final List<Widget> children;
  const _SectionCard({required this.cs, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _SelectPill extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _SelectPill({
    required this.label,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? cs.primary : cs.surface,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : cs.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
