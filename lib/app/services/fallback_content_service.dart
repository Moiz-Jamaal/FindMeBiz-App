import 'package:get/get.dart';
import '../data/models/sponsored_content.dart';
import '../data/models/api/index.dart';
import 'seller_service.dart';
import 'category_service.dart';

class FallbackContentService extends GetxService {
  final SellerService _sellerService = Get.find<SellerService>();
  final CategoryService _categoryService = Get.find<CategoryService>();

  /// Get fallback content for specific ad slots when no campaigns are available
  Future<List<SponsoredContent>> getFallbackContent(AdSlot slot, {int limit = 1}) async {
    switch (slot) {
      case AdSlot.homeHeaderBanner:
        return _getHeaderBannerFallback();
      case AdSlot.homeBelowSearchBanner:
        return _getBelowSearchFallback();
      case AdSlot.homeFeatured:
        return _getFeaturedFallback(limit);
      case AdSlot.homeNewSellers:
        return _getNewSellersFallback(limit);
      case AdSlot.searchSellers:
        return _getSearchSellersFallback(limit);
      case AdSlot.searchProducts:
        return _getSearchProductsFallback(limit);
      default:
        return [];
    }
  }

  /// Header banner fallback - static promotional content
  Future<List<SponsoredContent>> _getHeaderBannerFallback() async {
    return [
      const SponsoredContent(
        id: 'fallback_header_1',
        type: SponsoredType.banner,
        title: 'Discover Amazing Local Businesses',
        subtitle: 'Connect with trusted sellers in your area',
        imageUrl: null, // Can add local asset path later
        ctaLabel: 'Explore Now',
        deeplinkRoute: '/buyer-search',
        payload: {'type': 'organic', 'source': 'header_fallback'},
      ),
    ];
  }

  /// Below search fallback - "Become a Seller" call-to-action
  Future<List<SponsoredContent>> _getBelowSearchFallback() async {
    return [
      const SponsoredContent(
        id: 'fallback_cta_seller',
        type: SponsoredType.banner,
        title: 'Join Our Growing Community',
        subtitle: 'Start selling your products and services today',
        imageUrl: null,
        ctaLabel: 'Become a Seller',
        deeplinkRoute: '/seller-onboarding',
        payload: {'type': 'organic', 'source': 'seller_cta'},
      ),
    ];
  }

  /// Featured section fallback - promote top-rated sellers organically
  Future<List<SponsoredContent>> _getFeaturedFallback(int limit) async {
    try {
      // Get published sellers (we'll filter client-side since API doesn't support publishedOnly)
      final response = await _sellerService.searchSellers();

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!.take(limit).map((seller) {
          return SponsoredContent(
            id: 'fallback_seller_${seller.sellerid}',
            type: SponsoredType.seller,
            title: seller.businessname ?? 'Featured Business',
            subtitle: '⭐ Recommended • ${seller.city ?? seller.area ?? 'Local'}',
            imageUrl: seller.logo,
            ctaLabel: 'View Business',
            deeplinkRoute: '/buyer-seller-view',
            payload: {
              'sellerId': seller.sellerid,
              'type': 'organic',
              'source': 'featured_fallback'
            },
          );
        }).toList();
      }
    } catch (e) {
      // Continue to static fallback
    }

    // Static fallback if API fails
    return _getStaticFeaturedFallback(limit);
  }

  /// New sellers fallback - recently joined sellers
  Future<List<SponsoredContent>> _getNewSellersFallback(int limit) async {
    try {
      // This would ideally get recently registered sellers
      // For now, we'll use the same logic as featured but with different labeling
      final response = await _sellerService.searchSellers();

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        // Filter for published sellers and take limit
        final publishedSellers = response.data!
            .where((seller) => seller.ispublished == true)
            .toList();
            
        return publishedSellers.take(limit).map((seller) {
          return SponsoredContent(
            id: 'fallback_new_seller_${seller.sellerid}',
            type: SponsoredType.seller,
            title: seller.businessname ?? 'New Business',
            subtitle: '🆕 Recently Joined • ${seller.city ?? seller.area ?? 'Local'}',
            imageUrl: seller.logo,
            ctaLabel: 'Welcome Visit',
            deeplinkRoute: '/buyer-seller-view',
            payload: {
              'sellerId': seller.sellerid,
              'type': 'organic',
              'source': 'new_sellers_fallback'
            },
          );
        }).toList();
      }
    } catch (e) {
      // Continue to static fallback
    }

    return _getStaticNewSellersFallback(limit);
  }
  /// Search sellers fallback
  Future<List<SponsoredContent>> _getSearchSellersFallback(int limit) async {
    return [
      const SponsoredContent(
        id: 'fallback_search_sellers',
        type: SponsoredType.banner,
        title: 'Expand Your Search',
        subtitle: 'Try different keywords or browse categories',
        imageUrl: null,
        ctaLabel: 'Browse Categories',
        deeplinkRoute: '/buyer-categories',
        payload: {'type': 'organic', 'source': 'search_fallback'},
      ),
    ];
  }

  /// Search products fallback
  Future<List<SponsoredContent>> _getSearchProductsFallback(int limit) async {
    return [
      const SponsoredContent(
        id: 'fallback_search_products',
        type: SponsoredType.banner,
        title: 'Discover More Products',
        subtitle: 'Explore popular categories and trending items',
        imageUrl: null,
        ctaLabel: 'Browse All',
        deeplinkRoute: '/buyer-search',
        payload: {'type': 'organic', 'source': 'product_search_fallback'},
      ),
    ];
  }

  /// Static featured fallback when API fails
  List<SponsoredContent> _getStaticFeaturedFallback(int limit) {
    final staticContent = [
      const SponsoredContent(
        id: 'static_featured_1',
        type: SponsoredType.seller,
        title: 'Quality Local Businesses',
        subtitle: '⭐ Verified Sellers • Trusted by Community',
        imageUrl: null,
        ctaLabel: 'Explore',
        deeplinkRoute: '/buyer-search',
        payload: {'type': 'static', 'source': 'featured_static'},
      ),
      const SponsoredContent(
        id: 'static_featured_2',
        type: SponsoredType.banner,
        title: 'Find What You Need',
        subtitle: 'Browse thousands of local products and services',
        imageUrl: null,
        ctaLabel: 'Search Now',
        deeplinkRoute: '/buyer-search',
        payload: {'type': 'static', 'source': 'featured_static'},
      ),
    ];
    
    return staticContent.take(limit).toList();
  }

  /// Static new sellers fallback
  List<SponsoredContent> _getStaticNewSellersFallback(int limit) {
    final staticContent = [
      const SponsoredContent(
        id: 'static_new_1',
        type: SponsoredType.seller,
        title: 'Welcome New Businesses',
        subtitle: '🆕 Fresh arrivals in your area',
        imageUrl: null,
        ctaLabel: 'Discover',
        deeplinkRoute: '/buyer-search',
        payload: {'type': 'static', 'source': 'new_sellers_static'},
      ),
    ];
    
    return staticContent.take(limit).toList();
  }

  /// Get category-based promotional content
  Future<List<SponsoredContent>> getCategoryPromotions(int? categoryId) async {
    if (categoryId == null) return [];

    try {
      final categoriesResponse = await _categoryService.getCategories();
      if (categoriesResponse.success && categoriesResponse.data != null) {
        final category = categoriesResponse.data!
            .firstWhereOrNull((cat) => cat.catid == categoryId);
        
        if (category != null) {
          return [
            SponsoredContent(
              id: 'category_promo_$categoryId',
              type: SponsoredType.banner,
              title: 'Discover ${category.catname}',
              subtitle: 'Find the best local ${category.catname?.toLowerCase()} providers',
              imageUrl: null,
              ctaLabel: 'Browse ${category.catname}',
              deeplinkRoute: '/buyer-search',
              payload: {
                'categoryId': categoryId,
                'categoryName': category.catname,
                'type': 'organic',
                'source': 'category_promotion'
              },
            ),
          ];
        }
      }
    } catch (e) {
      // Return empty list on error
    }
    
    return [];
  }
}