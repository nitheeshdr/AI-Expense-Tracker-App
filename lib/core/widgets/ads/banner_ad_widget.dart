import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../services/ads/ad_config.dart';
import '../../../services/ads/ad_request_gate.dart';
import '../../../services/ads/ads_manager.dart';
import '../../design/spacing.dart';

/// Anchored adaptive banner sized to the available width (via LayoutBuilder).
/// Uses the real platform ad size reported after load so it always renders.
///
/// Only requests an ad once this slot actually scrolls into view. The same
/// banner ad unit ID appears on 8 widget instances across different screens
/// (2 on Dashboard alone), and Flutter's IndexedStack keeps every visited
/// tab's widgets alive underneath the active one — loading eagerly on build
/// meant several of them could request the same ad unit ID at once
/// regardless of what the user could actually see, which is what tripped
/// AdMob's own "too many recently failed requests" guard.
class BannerAdCard extends StatefulWidget {
  const BannerAdCard({super.key});

  @override
  State<BannerAdCard> createState() => _BannerAdCardState();
}

class _BannerAdCardState extends State<BannerAdCard> {
  BannerAd? _ad;
  AdSize? _size;
  bool _requested = false;
  int _width = 0;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_requested || info.visibleFraction <= 0 || _width <= 0) return;
    _requested = true;
    _load(_width);
  }

  Future<void> _load(int width) async {
    if (!AdsManager.instance.isInitialized ||
        AdsManager.instance.isAdFreeActive ||
        width <= 0) {
      return;
    }
    // Every widget instance sharing this ad unit ID funnels through one
    // cooldown, so the combined request rate across all of them (not just
    // this one widget's own retries) stays under AdMob's guard.
    if (!AdRequestGate.tryAcquire(AdConfig.bannerUnit)) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _load(width);
      });
      return;
    }
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait, width);
    if (size == null || !mounted) return;
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          final platformSize = await (ad as BannerAd).getPlatformAdSize();
          if (!mounted) return;
          setState(() => _size = platformSize ?? size);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint('Banner failed: ${err.code} ${err.message}');
          // A single failed load (a transient network hiccup or a no-fill
          // moment) previously left this slot empty forever — retry as long
          // as the widget is still on screen. AdMob Network is the only
          // mediation source now, so a plain fixed retry is safe (Meta
          // Audience Network, since removed, rejected reloads faster than
          // its own ~30s minimum interval outright).
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) _load(width);
          });
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth.floor();
        if (_size == null ||
            _ad == null ||
            AdsManager.instance.isAdFreeActive) {
          // A near-zero-size placeholder reserves no real space (same as
          // before an ad loads) but gives VisibilityDetector something to
          // measure, so it can tell when this slot scrolls into view.
          return VisibilityDetector(
            key: Key('banner_ad_slot_${identityHashCode(this)}'),
            onVisibilityChanged: _onVisibilityChanged,
            child: const SizedBox(height: 1),
          );
        }
        return Card(
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
