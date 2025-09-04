import 'package:get/get.dart';
import '../data/models/campaign/campaign_models.dart';
import '../data/models/sponsored_content.dart';
import 'api/base_api_service.dart';
import 'auth_service.dart';

class CampaignService extends BaseApiService {
  // Map ad slots to campaign groups
  static const Map<AdSlot, String> _slotToCampaignGroup = {
    AdSlot.homeHeaderBanner: 'home_header_banner',
    AdSlot.homeBelowSearchBanner: 'home_below_search',
    AdSlot.homeFeatured: 'featured_sellers',  // Updated to use featured sellers
    AdSlot.homeNewSellers: 'new_sellers_section',
    AdSlot.searchSellers: 'search_sellers',
    AdSlot.searchProducts: 'search_products',
  };

  // New slot for featured products
  static const String featuredProductsGroup = 'featured_products';

  // Get current user ID from auth service
  int? get _currentUserId {
    final authService = Get.find<AuthService>();
    return authService.currentUser?.userid;
  }

  /// Get campaigns for a specific ad slot
  Future<List<SponsoredContent>> getCampaignsForSlot(
    AdSlot slot, {
    int limit = 100,
  }) async {
    try {
      final userId = _currentUserId;
      final campGroup = _slotToCampaignGroup[slot];
if (campGroup == null) {
return [];
      }

      final request = TopCampaignsRequest(
        userId: userId,
        campGroup: campGroup,
        campaignCount: limit,
        userInterestCategories: [],
      );
final response = await post<Map<String, dynamic>>(
        '/TopCampaigns',
        body: request.toJson(),
      );
if (response.success && response.data != null) {
        final campaignsResponse = TopCampaignsResponse.fromJson(response.data!);
if (campaignsResponse.success) {
          final mappedContent = _mapCampaignsToSponsoredContent(campaignsResponse.campaigns);
return mappedContent;
        }
      } else {
}
      return [];
    } catch (e) {
return [];
    }
  }

  /// Get featured products campaigns
  Future<List<SponsoredContent>> getFeaturedProducts({int limit = 10}) async {
    try {
      final userId = _currentUserId;
      
      final request = TopCampaignsRequest(
        userId: userId,
        campGroup: featuredProductsGroup,
        campaignCount: limit,
        userInterestCategories: [],
      );
      
      final response = await post<Map<String, dynamic>>(
        '/TopCampaigns',
        body: request.toJson(),
      );
      
      if (response.success && response.data != null) {
        final campaignsResponse = TopCampaignsResponse.fromJson(response.data!);
        if (campaignsResponse.success) {
          return _mapCampaignsToSponsoredContent(campaignsResponse.campaigns);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Map campaigns to sponsored content
  List<SponsoredContent> _mapCampaignsToSponsoredContent(
    List<CampaignResponse> campaigns,
  ) {
    return campaigns.map((campaign) {
      final navigateUrl = campaign.campaign.navigateUrl ?? '';
      
      return SponsoredContent(
        id: campaign.campaign.campId.toString(),
        type: _determineSponsoredType(navigateUrl),
        title: campaign.sellerName ?? 'Featured Item',
        subtitle: campaign.categoryName ?? 'Featured',
        imageUrl: campaign.campaign.displayUrl, // Can be null for fallback
        ctaLabel: 'View Details',
        deeplinkRoute: _parseNavigateUrl(navigateUrl),
        payload: {
          'sellerId': campaign.campaign.sellerId,
          'campaignId': campaign.campaign.campId,
          'categoryId': campaign.campaign.catId,
          'type': 'campaign',
          'externalUrl': navigateUrl,
        },
      );
    }).toList();
  }
        
  /// Determine sponsored type based on navigate URL
  SponsoredType _determineSponsoredType(String navigateUrl) {
    if (navigateUrl.contains('/seller') || navigateUrl.contains('/buyer-seller-view')) {
      return SponsoredType.seller;
    } else if (navigateUrl.contains('/product') || navigateUrl.contains('/buyer-product-view')) {
      return SponsoredType.product;
    }
    return SponsoredType.banner;
  }

  /// Parse navigate URL to extract deep link route or external URL
  String? _parseNavigateUrl(String navigateUrl) {
    try {
      final uri = Uri.parse(navigateUrl);
      
      // Handle findmebiz.com URLs with deep linking
      if (navigateUrl.startsWith('https://findmebiz.com')) {
        // Let AppLinksService handle this
        return null; // Will be handled by external URL launching
      } else if (navigateUrl.startsWith('/')) {
        // Internal route
        return navigateUrl;
      } else {
        // External URL - will open in Chrome
        return null;
      }
    } catch (e) {
      // Invalid URL - fallback to seller view
      return '/buyer-seller-view';
    }
  }

  /// Record campaign view (called when ad is rendered)
  Future<void> recordCampaignView(List<SponsoredContent> campaigns, AdSlot slot) async {
    try {
      final userId = _currentUserId;
      if (userId == null || campaigns.isEmpty) return;

      final campGroup = _slotToCampaignGroup[slot];
      if (campGroup == null) return;

      final campaignIds = campaigns
          .where((c) => c.payload?['campaignId'] != null)
          .map((c) => c.payload!['campaignId'].toString())
          .join(',');

      if (campaignIds.isNotEmpty) {
        // This would normally be a separate endpoint, but since it's handled
        // by the TopCampaigns endpoint automatically, we don't need to make another call
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Create a campaign (for future seller functionality)
  Future<bool> createCampaign(CampaignDetails campaign) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/Campaign',
        body: campaign.toJson(),
      );
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Get campaigns for a specific seller
  Future<List<CampaignResponse>> getSellerCampaigns(int sellerId) async {
    try {
      final response = await get<List<dynamic>>(
        '/Seller/$sellerId/Campaigns',
      );

      if (response.success && response.data != null) {
        return response.data!
            .map((json) => CampaignResponse.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}