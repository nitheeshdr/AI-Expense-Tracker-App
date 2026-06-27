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
                  theme.brightness == Brightness.dark
                      ? 'asset/white.png'
                      : 'asset/black.png',
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('AI Expense Tracker',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Version 1.0.0 (build 1)',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_open_outlined,
                          size: 14, color: cs.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text('Open source · MIT',
                          style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
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
                  applicationVersion: '1.0.0',
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
              subtitle: const Text('Design, setup & engineering'),
              trailing: Icon(Icons.code, color: cs.onSurfaceVariant),
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
