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
  // Rendering hints
  final bool suppressOverlay; // Hide gradient/grey overlays when true
  final bool hideSponsoredTag; // Do not show 'Sponsored' badge when true

  const SponsoredContent({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.ctaLabel,
    this.deeplinkRoute,
    this.payload,
    this.suppressOverlay = false,
    this.hideSponsoredTag = false,
  });

  factory SponsoredContent.fromJson(Map<String, dynamic> json) {
    return SponsoredContent(
    id: json['id']?.toString() 
      ?? json['campId']?.toString() 
      ?? json['CampId']?.toString() 
      ?? '',
    type: _parseType(json['type'] 
      ?? json['campGroup'] 
      ?? json['CampGroup']),
    title: json['title'] 
      ?? json['offerTitle'] 
      ?? json['OfferTitle'] 
      ?? '',
    subtitle: json['subtitle'] 
      ?? json['offerDescription'] 
      ?? json['OfferDescription'],
    imageUrl: json['imageUrl'] 
      ?? json['displayUrl'] 
      ?? json['DisplayUrl'],
    ctaLabel: json['ctaLabel'] ?? 'View Offer',
    deeplinkRoute: json['deeplinkRoute'] 
      ?? json['navigateUrl'] 
      ?? json['NavigateUrl'],
      payload: json['payload'] as Map<String, dynamic>? ?? json,
      suppressOverlay: json['suppressOverlay'] ?? false,
      hideSponsoredTag: json['hideSponsoredTag'] ?? false,
    );
  }

  static SponsoredType _parseType(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'seller':
        return SponsoredType.seller;
      case 'product':
        return SponsoredType.product;
      case 'banner':
      case 'daily_offer':
      default:
        return SponsoredType.banner;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'ctaLabel': ctaLabel,
      'deeplinkRoute': deeplinkRoute,
      'payload': payload,
      'suppressOverlay': suppressOverlay,
      'hideSponsoredTag': hideSponsoredTag,
    };
  }
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
