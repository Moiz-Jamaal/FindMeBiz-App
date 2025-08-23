import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/sponsored_content.dart';
import 'sponsored_pill.dart';

/// Slim banner inspired by Zomato/Swiggy top banners, very subtle
class BannerAdTile extends StatelessWidget {
  final SponsoredContent ad;
  final VoidCallback? onTap;

  const BannerAdTile({super.key, required this.ad, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.buyerPrimary.withValues(alpha: 0.08),
                AppTheme.buyerPrimary.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: AppTheme.buyerPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ad.subtitle != null)
                      Text(
                        ad.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const SponsoredPill(),
            ],
          ),
        ),
      ),
    );
  }
}
