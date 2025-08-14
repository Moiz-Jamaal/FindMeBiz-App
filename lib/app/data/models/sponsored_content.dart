import 'package:flutter/material.dart';

/// Types of sponsored content supported in the app
enum SponsoredType { seller, product, banner }

/// Logical placement slots for subtle ad insertions
enum AdSlot {
  homeHeaderBanner,
  homeBelowSearchBanner,
  homeFeatured,
  homeNewSellers,
  searchSellers,
  searchProducts,
}

/// Lightweight sponsored content model used by the UI widgets
class SponsoredContent {
  final String id;
  final SponsoredType type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? ctaLabel;
  final String? deeplinkRoute;
  final Map<String, dynamic>? payload;

  const SponsoredContent({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.ctaLabel,
    this.deeplinkRoute,
    this.payload,
  });
}

/// Small helper for subtle 'Sponsored' label styling
class SponsoredLabel extends StatelessWidget {
  const SponsoredLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Sponsored',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
