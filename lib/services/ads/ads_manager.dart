import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router.dart';
import 'ad_config.dart';

/// Owns the AdMob lifecycle: SDK init, preloading + showing interstitial and
/// rewarded ads, and frequency-capping interstitials so the UX stays clean.
/// Banner and native ads are created per-widget (see the ad widgets) since
/// they're tied to layout.
class AdsManager {
  AdsManager._();
  static final AdsManager instance = AdsManager._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  int _actionCount = 0;
  DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);

  static const _kAdFreeUntil = 'ad_free_until';
  DateTime? _adFreeUntil;

  /// True while the user's earned "watch a rewarded ad, go ad-free" window
  /// is active. Interstitial, banner and native ads all check this before
  /// showing.
  bool get isAdFreeActive =>
      _adFreeUntil != null && DateTime.now().isBefore(_adFreeUntil!);

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(_kAdFreeUntil);
    if (untilMs != null) {
      _adFreeUntil = DateTime.fromMillisecondsSinceEpoch(untilMs);
    }
    _loadInterstitial();
    _loadRewarded();
  }

  /// Retries a failed ad load after a short delay instead of leaving that ad
  /// slot permanently empty for the rest of the session — a single load
  /// failure (e.g. a transient network hiccup or no-fill) shouldn't stop all
  /// future requests for that ad type. Meta Audience Network is no longer in
  /// the mediation stack (it enforced its own ~30s minimum reload interval
  /// and rejected faster retries outright), so AdMob Network alone can be
  /// retried quickly again.
  void _retryLoad(VoidCallback load) {
    Future.delayed(const Duration(seconds: 8), load);
  }

  // ---------------- Interstitial ----------------
  bool _interstitialLoading = false;

  void _loadInterstitial() {
    if (_interstitialLoading || _interstitial != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
              _offerAdFreeSoon();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _interstitialLoading = false;
          _interstitial = null;
          debugPrint('Interstitial failed: ${err.message}');
          _retryLoad(_loadInterstitial);
        },
      ),
    );
  }

  /// Mirrors [ensureRewardedReady] for the interstitial slot — waits a short
  /// beat for a load in flight to land instead of skipping the ad just
  /// because nothing happened to be preloaded yet. Safe to await here since
  /// callers only reach this after their own action already completed (e.g.
  /// the add-expense sheet has already popped), so a couple of seconds of
  /// latency isn't user-visible.
  Future<bool> _ensureInterstitialReady(
      {Duration timeout = const Duration(seconds: 4)}) async {
    if (_interstitial != null) return true;
    _loadInterstitial();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_interstitial != null) return true;
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return _interstitial != null;
  }

  /// Call after a meaningful completed action (e.g. saving a transaction).
  /// Shows an interstitial only every N actions and respecting a min time gap.
  /// Skipped entirely during an earned ad-free window.
  Future<void> registerActionAndMaybeShow() async {
    if (isAdFreeActive) return;
    _actionCount++;
    final dueByCount =
        _actionCount % AdConfig.interstitialEveryNActions == 0;
    final dueByTime =
        DateTime.now().difference(_lastInterstitial) >
            AdConfig.interstitialMinGap;
    if (!dueByCount || !dueByTime) return;
    if (!await _ensureInterstitialReady()) return;
    _lastInterstitial = DateTime.now();
    await _interstitial!.show();
  }

  /// Offers the user a rewarded ad in exchange for an hour with no ads,
  /// once the interstitial that just closed has fully settled off-screen —
  /// stacking a dialog the instant a full-screen ad dismisses reads as one
  /// jarring flash rather than two distinct moments.
  void _offerAdFreeSoon() {
    Future.delayed(const Duration(milliseconds: 500), _showAdFreeOffer);
  }

  void _showAdFreeOffer() {
    if (isAdFreeActive || !isRewardedReady) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    showLiquidGlassDialog<void>(
      context: context,
      builder: (dialogContext) => LiquidGlassAlertDialog(
        icon: Icon(Icons.play_circle_fill_rounded,
            size: 40, color: Theme.of(dialogContext).colorScheme.primary),
        title: const Text('Go ad-free for 1 hour'),
        content: const Text(
            'Watch a short video and every ad — banners, interstitials, '
            'all of it — stays off for the next hour.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No thanks'),
          ),
          LiquidGlassButton(
            label: 'Watch ad',
            height: 40,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final earned = await showRewarded();
              if (earned) await _activateAdFree();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _activateAdFree() async {
    _adFreeUntil = DateTime.now().add(const Duration(hours: 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAdFreeUntil, _adFreeUntil!.millisecondsSinceEpoch);
  }

  // ---------------- Rewarded ----------------
  bool _rewardedLoading = false;

  void _loadRewarded() {
    if (_rewardedLoading || _rewarded != null) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          _rewarded = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewarded = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _rewarded = null;
              _loadRewarded();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _rewardedLoading = false;
          _rewarded = null;
          debugPrint('Rewarded failed: ${err.message}');
          _retryLoad(_loadRewarded);
        },
      ),
    );
  }

  bool get isRewardedReady => _rewarded != null;

  /// Returns true immediately if a rewarded ad is already loaded. Otherwise
  /// actively kicks off (or piggybacks on) a load and waits up to [timeout]
  /// for it to land, instead of failing instantly just because nothing
  /// happened to be preloaded at the exact moment the user tapped a
  /// rewarded-ad button — most loads that succeed at all land within a few
  /// seconds, so this turns "not ready right now" into "not ready even
  /// after trying," which is a much smaller share of taps.
  Future<bool> ensureRewardedReady(
      {Duration timeout = const Duration(seconds: 8)}) async {
    if (isRewardedReady) return true;
    _loadRewarded();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (isRewardedReady) return true;
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return isRewardedReady;
  }

  /// Shows a rewarded ad. Resolves true if the user earned the reward.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    var earned = false;
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return earned;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
