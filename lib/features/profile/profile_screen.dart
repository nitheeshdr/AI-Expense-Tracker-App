import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/design/spacing.dart';
import '../../core/settings/settings.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ads/banner_ad_widget.dart';
import '../../core/widgets/app_sheet.dart';
import '../../features/sms_import/sms_import_sheet.dart';
import 'about_screen.dart';
import 'groq_key_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final keyAsync = ref.watch(groqKeyProvider);
    final hasKey = (keyAsync.value ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 110),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    child: const Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.userName == 'there' ? 'You' : s.userName,
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text('Base currency · ${s.currency}',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                        hasKey ? Icons.auto_awesome : Icons.power_off_outlined,
                        size: 16),
                    label: Text(hasKey ? 'AI on' : 'AI off'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const BannerAdCard(),
          const SizedBox(height: AppSpacing.sm),

          _GroupLabel('Data'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.sms_outlined),
                title: const Text('Import from SMS'),
                subtitle: const Text('Auto-detect bank & UPI transactions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showSmsImportSheet(context, ref),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),

          _GroupLabel('AI'),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.key_outlined),
                title: const Text('Groq API key'),
                subtitle: Text(hasKey
                    ? 'Connected — assistant unlocked'
                    : 'Add a key for conversational AI'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showGroqKeySheet(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.card_giftcard_outlined),
                title: const Text('Unlock a premium AI report'),
                subtitle: const Text('Watch a short ad to generate one'),
                trailing: const Icon(Icons.play_circle_outline),
                onTap: () => _unlockWithRewarded(context, ref),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),

          _GroupLabel('Appearance'),
          Card(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(Icons.brightness_6_outlined),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('Theme')),
                    SegmentedButton<AppThemeMode>(
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                            value: AppThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18)),
                        ButtonSegment(
                            value: AppThemeMode.light, icon: Icon(Icons.light_mode, size: 18)),
                        ButtonSegment(
                            value: AppThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18)),
                      ],
                      selected: {s.themeMode},
                      onSelectionChanged: (sel) => ctrl.setThemeMode(sel.first),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.palette_outlined),
                    const SizedBox(width: 16),
                    const Text('Accent'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        children: [
                          for (final col in AccentColors.options)
                            GestureDetector(
                              onTap: () => ctrl.setAccent(col),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Color(col),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: s.accentColor == col
                                        ? cs.onSurface
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: s.accentColor == col
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.currency_exchange_outlined),
                title: const Text('Currency'),
                subtitle: Text('${Money.symbols[s.currency] ?? ''} ${s.currency}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickCurrency(context, ref),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),

          _GroupLabel('Privacy'),
          Card(
            child: Column(children: [
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off_outlined),
                title: const Text('Hide balances'),
                value: s.hideBalances,
                onChanged: (v) =>
                    ctrl.update((x) => x.copyWith(hideBalances: v)),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.vibration_outlined),
                title: const Text('Haptics'),
                value: s.hapticsEnabled,
                onChanged: (v) =>
                    ctrl.update((x) => x.copyWith(hapticsEnabled: v)),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),

          _GroupLabel('About'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About & changelog'),
              subtitle: const Text('Version 1.0.0 · Nitheesh Rajendran'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unlockWithRewarded(BuildContext context, WidgetRef ref) async {
    final ads = ref.read(adsManagerProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (!ads.isRewardedReady) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Ad not ready yet — try again shortly.')));
      return;
    }
    final earned = await ads.showRewarded();
    messenger.showSnackBar(SnackBar(
      content: Text(earned
          ? 'Premium report unlocked — check the Aria tab.'
          : 'Reward not earned. Watch the full ad to unlock.'),
    ));
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) {
    const codes = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'JPY'];
    return showAppSheet<void>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(title: 'Base currency'),
          for (final code in codes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(Money.symbols[code] ?? code)),
              title: Text(code),
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .update((x) => x.copyWith(currency: code));
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.xs, bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Text(text.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 0.8,
          )),
    );
  }
}
