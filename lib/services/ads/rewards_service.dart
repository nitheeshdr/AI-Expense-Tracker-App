import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_manager.dart';

/// Features that have a small free daily allowance and can be topped up by
/// watching a rewarded ad.
enum RewardFeature {
  aiChat('AI messages', 'AI message', freePerDay: 5, perAd: 5),
  scan('receipt scans', 'receipt scan', freePerDay: 3, perAd: 3),
  export('CSV exports', 'CSV export', freePerDay: 2, perAd: 2),
  report('premium AI reports', 'premium AI report', freePerDay: 0, perAd: 1);

  final String plural;
  final String singular;
  final int freePerDay;
  final int perAd;
  const RewardFeature(this.plural, this.singular,
      {required this.freePerDay, required this.perAd});
}

/// Tracks the daily free allowance and ad-earned credits for [RewardFeature]s.
///
/// Fails open whenever ads aren't running (SDK not initialised, e.g. consent
/// not given) or no rewarded ad can be shown, so a user is never locked out of
/// a feature just because of ad fill.
class RewardsService {
  RewardsService._();
  static final RewardsService instance = RewardsService._();

  static const _kDay = 'rw_day';
  String _k(String kind, RewardFeature f) => 'rw_${kind}_${f.name}';

  Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    if (prefs.getString(_kDay) != today) {
      // New day: free allowances reset. Earned credits carry over.
      for (final f in RewardFeature.values) {
        await prefs.remove(_k('used', f));
      }
      await prefs.setString(_kDay, today);
    }
    return prefs;
  }

  /// Uses left today (free allowance + earned credits).
  Future<int> remaining(RewardFeature f) async {
    final prefs = await _prefs();
    final freeLeft = (f.freePerDay - (prefs.getInt(_k('used', f)) ?? 0))
        .clamp(0, f.freePerDay);
    return freeLeft + (prefs.getInt(_k('credits', f)) ?? 0);
  }

  /// Earned (ad-bought) credits only.
  Future<int> credits(RewardFeature f) async =>
      (await _prefs()).getInt(_k('credits', f)) ?? 0;

  Future<void> grant(RewardFeature f, int n) async {
    final prefs = await _prefs();
    await prefs.setInt(_k('credits', f), (prefs.getInt(_k('credits', f)) ?? 0) + n);
    AdsManager.instance.changes.value++;
  }

  Future<void> _consume(RewardFeature f) async {
    final prefs = await _prefs();
    final used = prefs.getInt(_k('used', f)) ?? 0;
    if (used < f.freePerDay) {
      await prefs.setInt(_k('used', f), used + 1);
    } else {
      final c = prefs.getInt(_k('credits', f)) ?? 0;
      if (c > 0) await prefs.setInt(_k('credits', f), c - 1);
    }
    AdsManager.instance.changes.value++;
  }

  /// Call right before doing the feature. Returns true if it may proceed
  /// (one use is consumed); otherwise offers a rewarded ad to unlock more.
  Future<bool> ensureAccess(BuildContext context, RewardFeature f) async {
    if (!AdsManager.instance.isInitialized) return true;
    if (await remaining(f) > 0) {
      await _consume(f);
      return true;
    }
    if (!context.mounted) return false;
    final watch = await showLiquidGlassDialog<bool>(
      context: context,
      builder: (ctx) => LiquidGlassAlertDialog(
        icon: Icon(Icons.play_circle_fill_rounded,
            size: 40, color: Theme.of(ctx).colorScheme.primary),
        title: Text(f.freePerDay == 0
            ? 'Unlock a ${f.singular}'
            : 'Out of free ${f.plural}'),
        content: Text(f.freePerDay == 0
            ? 'Watch a short video to unlock one ${f.singular}.'
            : "You've used today's ${f.freePerDay} free ${f.plural}. "
                'Watch a short video to get ${f.perAd} more.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          LiquidGlassButton(
            label: 'Watch ad',
            height: 40,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (watch != true || !context.mounted) return false;
    return earn(context, f);
  }

  /// Watches one rewarded ad for [f]'s credits, then uses one. Used by the
  /// out-of-allowance dialog; the rewards hub grants without using one.
  Future<bool> earn(BuildContext context, RewardFeature f,
      {bool consume = true}) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await AdsManager.instance.watchAds(1);
    switch (result) {
      case AdWatchResult.earned:
        await grant(f, f.perAd);
        if (consume) await _consume(f);
        return true;
      case AdWatchResult.unavailable:
        messenger?.showSnackBar(const SnackBar(
            content: Text('No ad available right now — this one is on us.')));
        return consume;
      case AdWatchResult.dismissed:
        messenger?.showSnackBar(const SnackBar(
            content: Text('Watch the full ad to earn the reward.')));
        return false;
    }
  }
}
