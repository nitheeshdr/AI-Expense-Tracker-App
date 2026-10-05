import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/design/spacing.dart';
import '../../../core/settings/settings.dart';
import '../../../services/ads/ads_manager.dart';
import '../../../services/ads/rewards_service.dart';
import '../app_sheet.dart';

/// Home-screen entry point to the rewards hub.
class RewardsCard extends StatelessWidget {
  const RewardsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: AdsManager.instance.changes,
      builder: (context, _, _) {
        final left = AdsManager.instance.adFreeRemaining;
        return Card(
          child: ListTile(
            leading: Icon(Icons.card_giftcard_rounded, color: cs.primary),
            title: const Text('Rewards'),
            subtitle: Text(left > Duration.zero
                ? 'Ad-free for ${_fmt(left)} more'
                : 'Watch a short ad for ad-free time & extras'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showRewardsSheet(context),
          ),
        );
      },
    );
  }
}

String _fmt(Duration d) {
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes.clamp(1, 59)}m';
}

Future<void> showRewardsSheet(BuildContext context) => showAppSheet<void>(
      context,
      builder: (_) => const _RewardsSheet(),
    );

class _RewardsSheet extends ConsumerWidget {
  const _RewardsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<int>(
      valueListenable: AdsManager.instance.changes,
      builder: (context, _, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(
              title: 'Rewards',
              subtitle: 'Watch a short video to earn a reward'),
          const SizedBox(height: AppSpacing.md),
          const _Label('Go ad-free'),
          _AdFreeTile(hours: 1, ads: 1),
          _AdFreeTile(hours: 6, ads: 2),
          _AdFreeTile(hours: 24, ads: 3),
          const SizedBox(height: AppSpacing.md),
          const _Label('Extras'),
          for (final f in RewardFeature.values)
            _FeatureTile(feature: f, ref: ref),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

class _AdFreeTile extends StatelessWidget {
  final int hours;
  final int ads;
  const _AdFreeTile({required this.hours, required this.ads});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.block_rounded),
        title: Text('$hours hour${hours == 1 ? '' : 's'} ad-free'),
        subtitle: Text('Watch $ads ad${ads == 1 ? '' : 's'}'),
        trailing: const Icon(Icons.play_circle_outline),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final r = await AdsManager.instance.watchAds(ads);
          switch (r) {
            case AdWatchResult.earned:
              await AdsManager.instance.grantAdFree(Duration(hours: hours));
              messenger.showSnackBar(SnackBar(
                  content: Text('Ads are off for $hours hour'
                      '${hours == 1 ? '' : 's'}.')));
            case AdWatchResult.unavailable:
              messenger.showSnackBar(const SnackBar(
                  content: Text('No ad available right now — try again shortly.')));
            case AdWatchResult.dismissed:
              messenger.showSnackBar(const SnackBar(
                  content: Text('Watch every ad to earn the reward.')));
          }
        },
      );
}

class _FeatureTile extends StatelessWidget {
  final RewardFeature feature;
  final WidgetRef ref;
  const _FeatureTile({required this.feature, required this.ref});

  static const _icons = {
    RewardFeature.aiChat: Icons.chat_bubble_outline,
    RewardFeature.scan: Icons.document_scanner_outlined,
    RewardFeature.export: Icons.ios_share,
    RewardFeature.report: Icons.insights_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final f = feature;
    return FutureBuilder<int>(
      future: RewardsService.instance.remaining(f),
      builder: (context, snap) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(_icons[f]),
        title: Text(f == RewardFeature.report
            ? 'Premium AI report'
            : '+${f.perAd} ${f.plural}'),
        subtitle: Text(f == RewardFeature.report
            ? 'Watch an ad to generate one'
            : '${snap.data ?? '…'} left today · watch 1 ad'),
        trailing: const Icon(Icons.play_circle_outline),
        onTap: () async {
          if (f == RewardFeature.report) {
            Navigator.of(context).pop();
            await generatePremiumReport(context, ref);
          } else {
            await RewardsService.instance.earn(context, f, consume: false);
          }
        },
      ),
    );
  }
}

/// Gates on a rewarded ad, then has Aria write a month-in-review report.
Future<void> generatePremiumReport(BuildContext context, WidgetRef ref) async {
  if (!await RewardsService.instance
      .ensureAccess(context, RewardFeature.report)) {
    return;
  }
  if (!context.mounted) return;
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  String report;
  try {
    final settings = ref.read(settingsProvider);
    final key = await ref.read(settingsProvider.notifier).groqKey();
    report = await ref.read(groqServiceProvider).ask(
          question: 'Write a premium monthly financial report: a short '
              'summary, where most money went, how I am tracking against my '
              'budget, 3 specific savings opportunities, and one habit to '
              'change next month.',
          history: const [],
          currency: settings.currency,
          apiKey: key,
        );
  } catch (e) {
    report = "Couldn't generate the report: $e";
  }
  nav.pop();
  if (!context.mounted) return;
  await showAppSheet<void>(
    context,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetHeader(title: 'Your premium report'),
        const SizedBox(height: AppSpacing.md),
        Flexible(child: SingleChildScrollView(child: SelectableText(report))),
      ],
    ),
  );
}
