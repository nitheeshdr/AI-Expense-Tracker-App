import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../services/ads/ad_config.dart';
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

  Future<void> _load(int width) async {
    if (!AdsManager.instance.isInitialized || width <= 0) return;
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
        if (_size == null || _ad == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          padding: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
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
        );
      },
    );
  }
}
