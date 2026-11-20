import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../services/ads/ad_config.dart';
import '../../../services/ads/ads_manager.dart';
import '../../design/spacing.dart';

/// Standard anchored adaptive banner (~50-60dp tall) sized to the available width (via LayoutBuilder).
/// Uses the real platform ad size reported after load so it always renders.
///
/// Loading is resilient to a slow SDK start and to no-fill: it waits for
/// [AdsManager.ready] instead of giving up when built early, retries with
/// jittered backoff, and tries again whenever the app returns to the
/// foreground.
class BannerAdCard extends StatefulWidget {
  const BannerAdCard({super.key});

  @override
  State<BannerAdCard> createState() => _BannerAdCardState();
}

class _BannerAdCardState extends State<BannerAdCard> {
  BannerAd? _ad;
  AdSize? _size;
  int _width = 0;
  int _attempts = 0;
  bool _loading = false;
  Timer? _retryTimer;
  static const _maxAttempts = 4;

  @override
  void initState() {
    super.initState();
    AdsManager.instance.ready.addListener(_kick);
    AdsManager.instance.resumeTick.addListener(_onResume);
  }

  @override
  void dispose() {
    AdsManager.instance.ready.removeListener(_kick);
    AdsManager.instance.resumeTick.removeListener(_onResume);
    _retryTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  void _onResume() {
    if (_size != null || _loading) return;
    _attempts = 0; // fresh start after a background trip
    _retryTimer?.cancel();
    _kick();
  }

  void _kick() {
    if (mounted && _size == null && !_loading) _load();
  }

  Future<void> _load() async {
    if (!mounted ||
        !AdsManager.instance.isInitialized ||
        AdsManager.instance.isAdFreeActive ||
        _width <= 0) {
      return;
    }
    _loading = true;
    // ignore: deprecated_member_use
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(_width);
    if (size == null || !mounted) {
      _loading = false;
      return;
    }
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          _attempts = 0;
          final platformSize = await (ad as BannerAd).getPlatformAdSize();
          _loading = false;
          if (!mounted) return;
          setState(() => _size = platformSize ?? size);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (identical(_ad, ad)) _ad = null;
          _loading = false;
          debugPrint('Banner failed: ${err.code} ${err.message}');
          if (AdsManager.isRetryable(err) && _attempts < _maxAttempts) {
            _retryTimer?.cancel();
            _retryTimer = Timer(
                AdsManager.retryDelayJittered(_attempts++), _kick);
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.floor();
        if (w > 0 && w != _width) {
          final first = _width == 0;
          _width = w;
          if (first) WidgetsBinding.instance.addPostFrameCallback((_) => _kick());
        }
        if (_size == null ||
            _ad == null ||
            AdsManager.instance.isAdFreeActive) {
          return const SizedBox.shrink();
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 2),
                    child: Text('Sponsored',
                        style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.4,
                            color: cs.onSurfaceVariant)),
                  ),
                ),
                SizedBox(
                  width: _size!.width.toDouble(),
                  height: _size!.height.toDouble(),
                  child: AdWidget(ad: _ad!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
