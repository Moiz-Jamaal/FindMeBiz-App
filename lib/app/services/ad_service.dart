import 'dart:math';
import 'package:get/get.dart';
import '../data/models/sponsored_content.dart';
import 'campaign_service.dart';
import 'fallback_content_service.dart';

/// Enhanced ad service that integrates campaign system with fallback content.
/// Prioritizes paid campaigns, falls back to organic/promotional content gracefully.
class AdService extends GetxService {
  final _rnd = Random();
  CampaignService? _campaignService;
  FallbackContentService? _fallbackContentService;

  // Lazy getters for services  
  CampaignService get campaignService {
    if (_campaignService == null) {
      try {
        _campaignService = Get.find<CampaignService>();
      } catch (e) {
rethrow;
      }
    }
    return _campaignService!;
  }
  
  FallbackContentService get fallbackContentService {
    if (_fallbackContentService == null) {
      try {
        _fallbackContentService = Get.find<FallbackContentService>();
      } catch (e) {
_fallbackContentService = FallbackContentService();
      }
    }
    return _fallbackContentService!;
  }

  // Frequency caps per slot (for fallback content insertion)
  final Map<AdSlot, int> frequency = {
    AdSlot.homeHeaderBanner: 1,
    AdSlot.homeBelowSearchBanner: 1,
    AdSlot.homeFeatured: 5,
    AdSlot.homeNewSellers: 6,
    AdSlot.searchSellers: 6,
    AdSlot.searchProducts: 8,
  };

  @override
  void onInit() {
    super.onInit();
    // Services are now loaded lazily when needed
  }

  /// Get sponsored content for a specific slot with campaign integration
  Future<List<SponsoredContent>> getSponsoredForSlot(AdSlot slot, {int limit = 1}) async {
List<SponsoredContent> content = [];

    // 1. Try to get campaigns first
    try {
content = await campaignService.getCampaignsForSlot(slot, limit: limit);
// Record view tracking when campaigns are retrieved
      if (content.isNotEmpty) {
        await campaignService.recordCampaignView(content, slot);
      }
    } catch (e) {
}

    // 2. If no campaigns available, try fallback content
    if (content.isEmpty) {
      try {
content = await fallbackContentService.getFallbackContent(slot, limit: limit);
} catch (e) {
content = [];
      }
    }

    return content.take(limit).toList();
  }

  /// Synchronous version - now calls async version
  Future<List<SponsoredContent>> getSponsoredForSlotSync(AdSlot slot, {int limit = 1}) async {
    return getSponsoredForSlot(slot, limit: limit);
  }

  /// Check if content is cached and still valid
  bool _isContentCached(AdSlot slot) {
    return false; // No caching
  }

  /// Preload campaigns for all home page slots
  Future<void> preloadHomeCampaigns() async {
    final homeSlots = [
      AdSlot.homeHeaderBanner,
      AdSlot.homeBelowSearchBanner,
      AdSlot.homeFeatured,
      AdSlot.homeNewSellers,
    ];

    // Load campaigns concurrently for better performance
    await Future.wait(
      homeSlots.map((slot) => getSponsoredForSlot(slot, limit: 5)),
    );
  }
  /// Decide whether to insert fallback content at this index based on frequency and randomness
  /// Used for organic content insertion in lists
  bool shouldInsertAt(AdSlot slot, int index) {
    final f = frequency[slot] ?? 0;
    if (f <= 0) return false;
    if (index == 0 && slot == AdSlot.homeHeaderBanner) return _rnd.nextBool();
    return index % f == 0 && _rnd.nextInt(100) < 35; // ~35% chance
  }
}