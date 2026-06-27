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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.account_balance_wallet_outlined,
                  size: 42, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Set up your tracker',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose your currency and monthly budget, then let the app read your '
              'bank & UPI SMS to track spending automatically — all on-device.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text('CURRENCY',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final code in _currencies)
                  ChoiceChip(
                    label: Text('${Money.symbols[code] ?? ''} $code'),
                    selected: _currency == code,
                    onSelected: (_) => setState(() => _currency = code),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('MONTHLY BUDGET',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final b in _budgets)
                  ChoiceChip(
                    label: Text(Money.format(b, code: _currency, compact: true)),
                    selected: _budget == b,
                    onSelected: (_) => setState(() => _budget = b),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

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

            FilledButton.icon(
              onPressed: busy ? null : _grantAndImport,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2))
                  : const Icon(Icons.sms_outlined),
              label: Text(busy ? 'Reading SMS…' : 'Grant SMS access & start'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: busy ? null : _finish,
              child: const Text('Skip SMS — set up manually'),
            ),
          ],
        ),
      ),
    );
  }
}
