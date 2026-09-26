import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Shows a brief loading spinner while ensuring a rewarded ad is ready (in
/// case none happened to be preloaded at the moment the user tapped),
/// then shows it. Returns whether the user actually earned the reward —
/// false both when no ad could be loaded in time and when the user closed
/// it early, since every caller treats those the same way.
Future<bool> tryShowRewardedAd(
  BuildContext context,
  WidgetRef ref, {
  String notReadyMessage = 'Ad not available right now — try again in a bit.',
}) async {
  final ads = ref.read(adsManagerProvider);
  final messenger = ScaffoldMessenger.of(context);
  if (!ads.isRewardedReady) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final ready = await ads.ensureRewardedReady();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!ready) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(notReadyMessage)));
      }
      return false;
    }
  }
  return ads.showRewarded();
}
