import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/ads/ads_manager.dart';
import '../../design/spacing.dart';

const _naazhiUrl =
    'https://play.google.com/store/apps/details?id=com.setupsworks.naazhi';

/// House ad promoting the Naazhi app, styled like a banner ad.
/// Hidden while the user has an active ad-free reward.
class NaazhiPromoCard extends StatelessWidget {
  const NaazhiPromoCard({super.key});

  Future<void> _open() async {
    final uri = Uri.parse(_naazhiUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (AdsManager.instance.isAdFreeActive) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ad',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.4,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo/naazhi-logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Naazhi: Notes, To-do & Journal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text('Free on Google Play',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _open,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Install'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
