import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/router.dart';
import 'ad_config.dart';

enum AdWatchResult { earned, dismissed, unavailable }

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

  /// Gathers consent through Google's User Messaging Platform before any ad
  /// request. The form is only shown when required (EEA/UK/CH users); for
  /// everyone else this resolves without UI. Errors are non-fatal — the
  /// stored consent state from a previous session still decides `canRequestAds`.
  Future<void> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((err) {
            if (err != null) debugPrint('Consent form: ${err.message}');
          });
        } catch (e) {
          debugPrint('Consent form failed: $e');
        }
        if (!done.isCompleted) done.complete();
      },
      (err) {
        debugPrint('Consent info update failed: ${err.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
  }

  /// True when the user's region requires a way to revisit their consent
  /// choice (drives the "Privacy settings" entry in Profile).
  Future<bool> isPrivacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((err) {
      if (err != null) debugPrint('Privacy options: ${err.message}');
    });
  }

  Future<void> init() async {
    if (_initialized) return;
    await _gatherConsent();
    if (!await ConsentInformation.instance.canRequestAds()) return;
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(_kAdFreeUntil);
    if (untilMs != null) {
      _adFreeUntil = DateTime.fromMillisecondsSinceEpoch(untilMs);
    }
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds init failed: $e');
      return;
    }
    _initialized = true;
    // Wake banner/native slots that were built while the SDK was still
    // starting up — they used to give up silently and stay empty.
    ready.value = true;
    _loadInterstitial();
    _loadRewarded();
    _loadRewardedInterstitial();
  }

  /// Flips to true once the SDK is initialized and ads may be requested.
  /// Banner/native widgets wait on this instead of checking once at build.
  final ValueNotifier<bool> ready = ValueNotifier(false);

  /// Bumped each time the app returns to the foreground so empty banner and
  /// native slots try again (e.g. after connectivity comes back).
  final ValueNotifier<int> resumeTick = ValueNotifier(0);

  /// Whether a failed load is worth retrying. Only INVALID_REQUEST (1) is a
  /// config problem that retrying can't fix; no-fill (3), network (2) and
  /// internal (0) errors are transient.
  static bool isRetryable(LoadAdError err) => err.code != 1;

  /// [retryDelay] plus up to 25% jitter so slots don't all retry in lockstep.
  static Duration retryDelayJittered(int attempt) {
    final base = retryDelay(attempt);
    return base + Duration(milliseconds: _rng.nextInt(base.inMilliseconds ~/ 4));
  }

  static final _rng = Random();

  /// Delay before retry [attempt] (0-based) of a failed ad load: 30s, 60s,
  /// 2m ... capped at 5 minutes. Every retry counts as an ad request, so
  /// rapid retries after a no-fill just stack up unmatched requests and drag
  /// the AdMob match rate down.
  static Duration retryDelay(int attempt) {
    final secs = 30 * (1 << attempt.clamp(0, 5));
    return Duration(seconds: secs > 300 ? 300 : secs);
  }

  /// Give up on a full-screen slot after this many failed loads in a row;
  /// the next foreground resume starts a fresh round.
  static const _maxFullScreenAttempts = 5;

  /// Preloaded full-screen ads expire after ~1 hour; reload before then so a
  /// stale ad is never what the user is handed.
  static const _adTtl = Duration(minutes: 50);

  static const _resumeCooldown = Duration(minutes: 3);
  DateTime _lastResumeRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  int _interstitialAttempts = 0;
  int _rewardedAttempts = 0;
  DateTime _interstitialLoadedAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _rewardedLoadedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;

  /// Call when the app returns to the foreground: reloads any empty or
  /// expired full-screen ad slot.
  void refreshIfNeeded() {
    if (!_initialized) return;
    final now = DateTime.now();
    // Resume also fires after every full-screen ad / permission dialog, and
    // all visited tabs stay mounted — so each resume used to re-request every
    // empty banner/native slot at once. Throttle it.
    if (now.difference(_lastResumeRefresh) < _resumeCooldown) return;
    _lastResumeRefresh = now;
    resumeTick.value++;
    if (_interstitial == null ||
        now.difference(_interstitialLoadedAt) > _adTtl) {
      _interstitial?.dispose();
      _interstitial = null;
      _interstitialAttempts = 0;
      _loadInterstitial();
    }
    if (_rewarded == null || now.difference(_rewardedLoadedAt) > _adTtl) {
      _rewarded?.dispose();
      _rewarded = null;
      _rewardedAttempts = 0;
      _loadRewarded();
    }
  }

  // ---------------- Interstitial ----------------
  void _loadInterstitial() {
    if (_interstitialLoading || _interstitial != null) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitialAttempts = 0;
          _interstitialLoadedAt = DateTime.now();
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
          debugPrint('Interstitial failed: ${err.code} ${err.message}');
          if (isRetryable(err) &&
              _interstitialAttempts < _maxFullScreenAttempts) {
            Future.delayed(
                retryDelayJittered(_interstitialAttempts++), _loadInterstitial);
          }
        },
      ),
    );
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
    if (dueByCount && dueByTime && _interstitial != null) {
      _lastInterstitial = DateTime.now();
      await _interstitial!.show();
    }
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
              if (earned) await grantAdFree(const Duration(hours: 1));
            },
          ),
        ],
      ),
    );
  }

  /// Starts (or extends) the ad-free window. Stacks on any time already left.
  Future<void> grantAdFree(Duration d) async {
    final now = DateTime.now();
    final base = isAdFreeActive ? _adFreeUntil! : now;
    _adFreeUntil = base.add(d);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAdFreeUntil, _adFreeUntil!.millisecondsSinceEpoch);
    changes.value++;
  }

  /// Time left in the current ad-free window (zero when none).
  Duration get adFreeRemaining => isAdFreeActive
      ? _adFreeUntil!.difference(DateTime.now())
      : Duration.zero;

  /// Bumped whenever the ad-free window or reward credits change, so UI such
  /// as the rewards card can rebuild.
  final ValueNotifier<int> changes = ValueNotifier(0);

  /// Shows [count] rewarded ads back to back (each must be fully watched).
  /// [AdWatchResult.unavailable] means no ad could be shown at all, so callers
  /// can fail open instead of locking a user out because of ad fill.
  Future<AdWatchResult> watchAds(int count) async {
    for (var i = 0; i < count; i++) {
      // The next rewarded ad preloads after the previous one dismisses.
      for (var w = 0; w < 16 && !isRewardedReady; w++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (!isRewardedReady) {
        return i == 0 ? AdWatchResult.unavailable : AdWatchResult.dismissed;
      }
      if (!await showRewarded()) return AdWatchResult.dismissed;
    }
    return AdWatchResult.earned;
  }

  // ---------------- Rewarded ----------------
  void _loadRewarded() {
    if (_rewardedLoading || _rewarded != null) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading = false;
          _rewardedAttempts = 0;
          _rewardedLoadedAt = DateTime.now();
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
          debugPrint('Rewarded failed: ${err.code} ${err.message}');
          if (isRetryable(err) && _rewardedAttempts < _maxFullScreenAttempts) {
            Future.delayed(
                retryDelayJittered(_rewardedAttempts++), _loadRewarded);
          }
        },
      ),
    );
  }

  // ---------------- Rewarded interstitial ----------------
  RewardedInterstitialAd? _rewardedInterstitial;
  bool _riLoading = false;
  bool _riOffering = false;
  int _riAttempts = 0;
  int _pageOpens = 0;
  DateTime _riLoadedAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRiOffer = DateTime.now(); // no offer right after launch

  void _loadRewardedInterstitial() {
    if (_riLoading || _rewardedInterstitial != null) return;
    _riLoading = true;
    RewardedInterstitialAd.load(
      adUnitId: AdConfig.rewardedInterstitialUnit,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _riLoading = false;
          _riAttempts = 0;
          _riLoadedAt = DateTime.now();
          _rewardedInterstitial = ad;
        },
        onAdFailedToLoad: (err) {
          _riLoading = false;
          _rewardedInterstitial = null;
          debugPrint(
              'Rewarded interstitial failed: ${err.code} ${err.message}');
          if (isRetryable(err) && _riAttempts < _maxFullScreenAttempts) {
            Future.delayed(
                retryDelayJittered(_riAttempts++), _loadRewardedInterstitial);
          }
        },
      ),
    );
  }

  /// Call when the user opens a page. Every Nth open (frequency-capped, and
  /// never during an ad-free window or right after another full-screen ad)
  /// offers a rewarded interstitial. Per AdMob policy the user first sees an
  /// intro dialog stating the reward and can decline; the ad only plays after
  /// they tap Watch.
  void onPageOpened() {
    if (!_initialized || isAdFreeActive || _riOffering) return;
    _pageOpens++;
    if (_pageOpens % AdConfig.rewardedInterstitialEveryNPages != 0) return;
    final now = DateTime.now();
    if (now.difference(_lastRiOffer) < AdConfig.rewardedInterstitialMinGap ||
        now.difference(_lastInterstitial) < AdConfig.interstitialMinGap) {
      return;
    }
    if (_rewardedInterstitial != null &&
        now.difference(_riLoadedAt) > _adTtl) {
      _rewardedInterstitial?.dispose();
      _rewardedInterstitial = null;
    }
    if (_rewardedInterstitial == null) {
      _loadRewardedInterstitial();
      return;
    }
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    _riOffering = true;
    _lastRiOffer = now;
    final mins = AdConfig.rewardedInterstitialReward.inMinutes;
    showLiquidGlassDialog<void>(
      context: context,
      builder: (dialogContext) => LiquidGlassAlertDialog(
        icon: Icon(Icons.card_giftcard_rounded,
            size: 40, color: Theme.of(dialogContext).colorScheme.primary),
        title: Text('Ad-free for $mins minutes'),
        content: Text('Watch a short video and every ad stays off for the '
            'next $mins minutes.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _riOffering = false;
            },
            child: const Text('No thanks'),
          ),
          LiquidGlassButton(
            label: 'Watch video',
            height: 40,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _showRewardedInterstitial();
              _riOffering = false;
            },
          ),
        ],
      ),
    ).whenComplete(() => _riOffering = false);
  }

  Future<void> _showRewardedInterstitial() async {
    final ad = _rewardedInterstitial;
    if (ad == null) return;
    _rewardedInterstitial = null;
    var earned = false;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _loadRewardedInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    await done.future;
    if (earned) await grantAdFree(AdConfig.rewardedInterstitialReward);
  }

  bool get isRewardedReady => _rewarded != null;

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
    _rewardedInterstitial?.dispose();
  }
}
