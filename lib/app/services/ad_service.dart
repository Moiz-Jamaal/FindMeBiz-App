import 'dart:math';
import 'package:get/get.dart';
import '../data/models/sponsored_content.dart';

/// Very lightweight ad service that returns mock sponsored content.
/// In production, replace with a backend-driven targeting feed.
class AdService extends GetxService {
  final _rnd = Random();

  // Frequency caps per slot (e.g., insert every N items at most)
  final Map<AdSlot, int> frequency = {
    AdSlot.homeHeaderBanner: 1, // show at top occasionally
    AdSlot.homeFeatured: 5, // every ~5 cards
    AdSlot.homeNewSellers: 6,
    AdSlot.searchSellers: 6,
    AdSlot.searchProducts: 8,
  };

  List<SponsoredContent> getSponsoredForSlot(AdSlot slot, {int limit = 1}) {
    // Mock pool inspired by Zomato/Swiggy/Instagram/Amazon native styles
    final pool = <SponsoredContent>[
      SponsoredContent(
        id: 'sp1',
        type: SponsoredType.banner,
        title: 'Flat 20% off on Silk Sarees',
        subtitle: 'Limited time • A-23 Surat Silk Emporium',
        imageUrl: null,
        ctaLabel: 'Shop now',
        deeplinkRoute: '/buyer-seller-view',
        payload: {'id': '1'},
      ),
      SponsoredContent(
        id: 'sp2',
        type: SponsoredType.seller,
        title: 'Gujarati Handicrafts',
        subtitle: 'Authentic mirror work & wall art',
        imageUrl: null,
        ctaLabel: 'View stall',
        deeplinkRoute: '/buyer-seller-view',
        payload: {'id': '2'},
      ),
      SponsoredContent(
        id: 'sp3',
        type: SponsoredType.product,
        title: 'Diamond Necklace Set',
        subtitle: 'Festive picks curated for you',
        imageUrl: null,
        ctaLabel: 'Explore',
        deeplinkRoute: '/buyer-product-view',
        payload: {'id': '3'},
      ),
    ];

    pool.shuffle(_rnd);
    return pool.take(limit).toList();
  }

  /// Decide whether to insert at this index based on slot frequency and randomness
  bool shouldInsertAt(AdSlot slot, int index) {
    final f = frequency[slot] ?? 0;
    if (f <= 0) return false;
    if (index == 0 && slot == AdSlot.homeHeaderBanner) return _rnd.nextBool();
    return index % f == 0 && _rnd.nextInt(100) < 35; // ~35% chance
  }
}
