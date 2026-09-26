import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../services/ads/ad_config.dart';
import '../../../services/ads/ad_request_gate.dart';
import '../../../services/ads/ads_manager.dart';
import '../../design/spacing.dart';

/// Anchored adaptive banner sized to the available width (via LayoutBuilder).
/// Uses the real platform ad size reported after load so it always renders.
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

  Future<void> _load(int width) async {
    if (!AdsManager.instance.isInitialized ||
        AdsManager.instance.isAdFreeActive ||
        width <= 0) {
      return;
    }
    _width = width;
    // The same banner ad unit ID is reused on several screens, and once a
    // tab is visited its widgets stay alive underneath (IndexedStack) — so
    // several BannerAdCards can be requesting/retrying at once. Gate every
    // attempt through one shared cooldown per ad unit ID so the combined
    // request rate never trips AdMob's own "too many recently failed
    // requests" guard, instead of each widget only pacing itself.
    if (!AdRequestGate.tryAcquire(AdConfig.bannerUnit)) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _load(width);
      });
      return;
    }
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait, width);
    if (size == null) return;
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
          // A single failed load (e.g. a transient network hiccup or a
          // no-fill moment) previously left this slot empty forever —
          // retry as long as the widget is still on screen. Meta Audience
          // Network (which rejected fast reloads outright) is no longer in
          // the mediation stack, so AdMob Network alone can retry quickly.
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) _load(_width);
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
        if (!_requested) {
          _requested = true;
          _load(constraints.maxWidth.floor());
        }
        if (_size == null ||
            _ad == null ||
            AdsManager.instance.isAdFreeActive) {
          return const SizedBox.shrink();
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
