import 'package:flutter/material.dart';
import '../../../../data/models/sponsored_content.dart';
import '../../../../core/theme/app_theme.dart';
import 'sponsored_pill.dart';

/// Subtle native ad card that blends with existing list tiles/cards
class NativeAdCard extends StatelessWidget {
  final SponsoredContent ad;
  final VoidCallback? onTap;

  const NativeAdCard({super.key, required this.ad, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.buyerPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForType(ad.type),
                  color: AppTheme.buyerPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ad.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SponsoredPill(),
                      ],
                    ),
                    if (ad.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        ad.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (ad.ctaLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        ad.ctaLabel!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.buyerPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(SponsoredType type) {
    switch (type) {
      case SponsoredType.seller:
        return Icons.store;
      case SponsoredType.product:
        return Icons.local_mall;
      case SponsoredType.banner:
        return Icons.campaign;
    }
  }
}
