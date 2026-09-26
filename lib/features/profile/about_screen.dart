import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/spacing.dart';
import '../../services/review/review_service.dart';

const _githubUrl = 'https://github.com/nitheeshdr/AI-Expense-Tracker-App';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Release {
  final String version;
  final String date;
  final List<String> changes;
  const _Release(this.version, this.date, this.changes);
}

const _changelog = [
  _Release('3.2.1', 'Sep 2026', [
    'Restored Meta Audience Network as an AdMob bidding partner for better ad fill and rates, now that the real mediation floor issue is fixed',
  ]),
  _Release('3.2.0', 'Sep 2026', [
    'More native ad placements across Transactions, Merchants, and Budgets that appear as you scroll, instead of just once',
  ]),
  _Release('3.1.1', 'Sep 2026', [
    'Ads load faster and more reliably — rewarded/interstitial ads now try harder in the moment instead of failing instantly, and banner/native ads retry automatically after a failed load',
  ]),
  _Release('3.1.0', 'Sep 2026', [
    'New: watch a short ad for a deeper AI spending report from the dashboard',
    'New: watch a short ad to deep-scan up to a year of SMS for older transactions',
    'CSV export now includes a short ad before sharing',
  ]),
  _Release('3.0.0', 'Sep 2026', [
    'New: Scan receipt — snap or pick a photo and the amount fills in automatically',
    'Receipt scanning runs fully on-device; photos are never uploaded anywhere',
  ]),
  _Release('2.1.7', 'Sep 2026', [
    'Minor release management fixes — no user-facing changes',
  ]),
  _Release('2.1.6', 'Sep 2026', [
    'Added support for push notifications and announcements',
  ]),
  _Release('2.1.5', 'Sep 2026', [
    'Added Meta Audience Network as an AdMob mediation bidding partner for better ad fill and rates',
  ]),
  _Release('2.1.4', 'Sep 2026', [
    'New: two more home-screen widgets — monthly budget progress and a "Net this month" summary',
    'New: a one-tap "Add expense" home-screen widget',
    'Home-screen widgets now properly follow light/dark mode instead of a fixed dark look',
    'New: periodic notifications with your spending — today\'s total, month-to-date, or budget remaining',
    'Crash reporting and anonymous usage analytics added (no transaction data ever leaves your device)',
  ]),
  _Release('2.1.3', 'Sep 2026', [
    'Light theme by default for new installs',
    'Watch a short ad to go completely ad-free for 1 hour',
    'Fixed the system back button exiting the app instead of returning to Home from another tab',
    'AI assistant is now a full nav bar tab; Add moved to the floating "+" button',
    'AI assistant\'s message box no longer overlaps the nav bar',
    'Budgets\' "+" button now matches the floating action button\'s glass style exactly',
    'Redesigned onboarding with the app logo, feature highlights and a premium look',
    'Nav bar and floating buttons share the same glass tint in both themes',
    'Ads that fail to load now retry automatically instead of going silent for the session',
    'Sponsored cards now match the app\'s card style exactly',
  ]),
  _Release('2.1.2', 'Sep 2026', [
    'Real liquid-glass look for the floating nav bar, sheets, dialogs, and status filters',
    'Fixed the app always returning to the last-open screen after being backgrounded — it now reopens on Home',
  ]),
  _Release('2.1.1', 'Sep 2026', [
    'Edge-to-edge display fixed for Android 15+ (Play Console pre-launch check)',
    'R8 optimized resource shrinking enabled for a smaller, faster install',
  ]),
  _Release('2.1.0', 'Sep 2026', [
    'Merchants tab: every merchant you\'ve ever transacted with, searchable, with total sent/received',
    'Per-merchant report: transaction count, total sent, total received, net, and the full transaction history',
    'Mutual Funds investment tracking on the Budgets tab',
    'New blue Material 3 color theme with a frosted-glass floating nav bar',
    'Profile moved to a floating button shown only on Home, to make room for Merchants in the nav bar',
  ]),
  _Release('2.0.0', 'Sep 2026', [
    'Material 3 Expressive redesign: native color scheme, cards, chips, nav bar',
    'Fixed a crash when granting the notification permission on first launch',
    'Fixed a startup delay caused by ad-network initialization blocking the launch screen',
    'In-app updates and a review prompt for engaged users',
  ]),
  _Release('1.1.0', 'Jul 2026', [
    'Biometric app lock (fingerprint / device credential)',
    'Export all transactions as CSV and share anywhere',
    'Smart insights: daily average, month-end forecast vs budget, peak day, no-spend days',
    'Calendar spending heatmap for the month',
    'Pure black & white theme with true AMOLED black dark mode',
    'Live-activity notification with budget progress on the lock screen',
    'Automatic silent SMS catch-up sync on every app open',
  ]),
  _Release('1.0.0', 'Jun 2026', [
    'Automatic bank & UPI SMS tracking with real-time capture',
    'Background sync — transactions added even when the app is closed',
    'Smart SMS parser ignores OTPs, promos & cashback messages',
    'AI assistant (Aria) grounded in your real spending',
    'Budgets, savings goals, subscriptions & autopay detection',
    'Redesigned home with line, bar & donut charts + value labels',
    'Tap "Net this month" for an income vs expense breakdown',
    'Top merchants, financial health score & AI insights',
    'Home-screen widget matching your accent + income/expense',
    'Live ongoing notification with quick Add expense / income',
    'Activity search, category filter & sort (newest/highest)',
    'Material 3 theming: light / dark / system + 6 accent colors',
    'AdMob banner, native, interstitial & rewarded ads',
    'About page with changelog, developer info & app rating',
  ]),
  _Release('0.9.0', 'Jun 2026', [
    'First-run onboarding with currency & budget setup',
    'SMS permission flow & one-tap inbox import',
    'Transactions timeline grouped by day with swipe-to-delete',
    'Local SQLite storage — fully offline-first',
  ]),
  _Release('0.8.0', 'May 2026', [
    'Custom design system & floating navigation',
    'Dashboard, budgets & AI assistant foundations',
  ]),
];

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 40),
        children: [
          Center(
            child: Column(
              children: [
                 Image.asset(
                  'assets/logo/app-logo.png',
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('AI Expense Tracker',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Version 3.2.1 (build 17)',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Chip(
                  avatar: Icon(Icons.lock_open_outlined,
                      size: 16, color: cs.onPrimaryContainer),
                  label: const Text('Open source · MIT'),
                  labelStyle: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700),
                  backgroundColor: cs.primaryContainer,
                  side: BorderSide.none,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Source & licenses
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('View source on GitHub'),
                subtitle: const Text('nitheeshdr/AI-Expense-Tracker-App'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _openUrl(_githubUrl),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Open-source licenses'),
                subtitle: const Text('Third-party packages & licenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'AI Expense Tracker',
                  applicationVersion: '3.2.1',
                  applicationLegalese: '© 2026 Nitheesh Rajendran · Setups Works',
                ),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Rating
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ReviewService.instance.requestReview(),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Rate the app'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ReviewService.instance.openStoreListing(),
                  icon: const Icon(Icons.shop_outlined),
                  label: const Text('Play Store'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Developer
          Text('DEVELOPER',
              style: theme.textTheme.labelMedium?.copyWith(color: cs.primary)),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: const Text('NR'),
              ),
              title: const Text('Nitheesh Rajendran'),
              subtitle: const Text('github.com/nitheeshdr'),
              trailing: Icon(Icons.code, color: cs.onSurfaceVariant),
              onTap: () => _openUrl('https://github.com/nitheeshdr'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Changelog
          Text("WHAT'S NEW",
              style: theme.textTheme.labelMedium?.copyWith(color: cs.primary)),
          const SizedBox(height: AppSpacing.sm),
          for (final r in _changelog) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('v${r.version}',
                              style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        const Spacer(),
                        Text(r.date,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final ch in r.changes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(ch,
                                    style: theme.textTheme.bodyMedium)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
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
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
