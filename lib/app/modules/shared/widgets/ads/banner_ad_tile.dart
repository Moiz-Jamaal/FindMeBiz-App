import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/sponsored_content.dart';
import 'sponsored_pill.dart';

/// Slim banner inspired by Zomato/Swiggy top banners, very subtle
class BannerAdTile extends StatelessWidget {
  final SponsoredContent ad;
  final VoidCallback? onTap;
  final double? height;

  const BannerAdTile({super.key, required this.ad, this.onTap, this.height});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height ?? 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            image: ad.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(ad.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            gradient: ad.imageUrl == null
                ? LinearGradient(
                    colors: [
                      AppTheme.buyerPrimary.withValues(alpha: 0.08),
                      AppTheme.buyerPrimary.withValues(alpha: 0.02),
                    ],
                  )
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: ad.imageUrl != null
                  ? LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (ad.imageUrl == null) ...[
                  Icon(Icons.local_fire_department, color: AppTheme.buyerPrimary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ad.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ad.imageUrl != null ? Colors.white : null,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ad.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ad.subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: ad.imageUrl != null
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : AppTheme.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const SponsoredPill(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
