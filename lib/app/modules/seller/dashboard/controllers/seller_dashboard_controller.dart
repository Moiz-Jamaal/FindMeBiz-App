import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../services/product_service.dart';
import '../../../../data/models/api/index.dart';

class SellerDashboardController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  final ProductService _productService = ProductService.instance;
  
  // Current navigation index
  final RxInt currentIndex = 0.obs;
  
  // Dashboard statistics (keeping as dummy for now as requested)
  final RxInt totalProducts = 0.obs;
  final RxDouble averageRating = 0.0.obs;
  final RxInt totalReviews = 0.obs;
  final RxDouble profileCompletion = 0.0.obs; // Start with 0% to avoid misleading display
  
  // Profile data
  final Rx<SellerDetailsExtended?> sellerProfile = Rx<SellerDetailsExtended?>(null);
  final RxString businessName = 'Loading...'.obs; // Better loading indicator
  final RxBool isProfilePublished = false.obs;
  
  // Subscription data
  final Rx<Map<String, dynamic>?> currentSubscription = Rx<Map<String, dynamic>?>(null);
  
  // UI state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      isLoading.value = true;
      
      final currentUser = _authService.currentUser;
      if (currentUser?.userid == null) {
        Get.snackbar(
          'Error',
          'No user found. Please login again.',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
        return;
      }

      // Load seller profile data
      final response = await _sellerService.getSellerByUserId(currentUser!.userid!);

      if (response.success && response.data != null) {
        sellerProfile.value = response.data;
        businessName.value = response.data!.businessname ?? 'My Business';
        isProfilePublished.value = response.data!.ispublished ?? false;

        // Calculate profile completion based on filled fields
        profileCompletion.value = _calculateProfileCompletion(response.data!);

        // Load subscription details and statistics asynchronously if published
        if (isProfilePublished.value) {
          final futures = <Future>[
            _loadSubscriptionDetails(response.data!.sellerid!),
            _loadSellerStatistics(response.data!.sellerid!),
          ];
          await Future.wait(futures);
        }
      } else {
        // If no seller profile exists yet, user needs to complete onboarding
        businessName.value = currentUser.fullname ?? 'My Business';
        isProfilePublished.value = false;
        profileCompletion.value = 0.0;
        _loadDummyStatistics(); // Keep as fallback
      }
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load dashboard data',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      _loadDummyStatistics(); // Fallback to dummy data
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSellerStatistics(int sellerId) async {
    try {
      // Load products and reviews data asynchronously in parallel
      final futures = <Future>[
        _productService.getProductsBySeller(sellerId, pageSize: 1),
        _sellerService.getSellerReviews(sellerId),
      ];

      final results = await Future.wait(futures);

      // Process products response
      final productsResponse = results[0] as dynamic; // Adjust type based on actual response type
      if (productsResponse.isSuccess && productsResponse.data != null) {
        totalProducts.value = productsResponse.data!.totalCount;
      }

      // Process reviews response
      try {
        final reviewsResponse = results[1] as dynamic; // Adjust type based on actual response type
        if (reviewsResponse.isSuccess && reviewsResponse.data != null) {
          final reviewData = reviewsResponse.data!;

          // Always calculate from actual review data when available
          _calculateReviewStatistics(reviewData);

          // Fallback to API statistics if no individual reviews found
          if (totalReviews.value == 0) {
            totalReviews.value = (reviewData['totalReviews'] as int?) ??
                               (reviewData['totalSellerReviews'] as int?) ?? 0;
            averageRating.value = (reviewData['averageRating'] as num?)?.toDouble() ??
                                 (reviewData['avgSellerRating'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } catch (e) {
        // Reviews API might not be available yet, keep defaults
        totalReviews.value = 0;
        averageRating.value = 0.0;
      }

    } catch (e) {
      // If statistics loading fails, keep current values or set to 0
      totalProducts.value = 0;
      averageRating.value = 0.0;
      totalReviews.value = 0;
    }
  }  void _calculateReviewStatistics(Map<String, dynamic> reviewData) {
    try {
      final sellerReviews = reviewData['sellerReviews'] as List?;
      final productReviews = reviewData['productReviews'] as List?;
      
      double totalRating = 0;
      int reviewCount = 0;
      
      // Calculate from seller reviews
      if (sellerReviews != null) {
        for (var review in sellerReviews) {
          final rating = (review['sellerRating'] as num?)?.toDouble() ??
                         (review['rating'] as num?)?.toDouble() ??
                         (review['Rating'] as num?)?.toDouble();
          if (rating != null) {
            totalRating += rating;
            reviewCount++;
          }
        }
      }
      
      // Calculate from product reviews
      if (productReviews != null) {
        for (var review in productReviews) {
          final rating = (review['productRating'] as num?)?.toDouble() ??
                         (review['rating'] as num?)?.toDouble() ??
                         (review['Rating'] as num?)?.toDouble();
          if (rating != null) {
            totalRating += rating;
            reviewCount++;
          }
        }
      }
      
      totalReviews.value = reviewCount;
      averageRating.value = reviewCount > 0 ? (totalRating / reviewCount) : 0.0;
    } catch (e) {
      totalReviews.value = 0;
      averageRating.value = 0.0;
    }
  }

  void _loadDummyStatistics() {
    // Fallback dummy data only when APIs fail
    totalProducts.value = 0;
    averageRating.value = 0.0;
    totalReviews.value = 0;
  }
  

  Future<void> _loadSubscriptionDetails(int sellerId) async {
    try {
      final settings = sellerProfile.value?.settings?.firstOrNull;
      if (settings?.subscriptionDetails != null) {
        try {
          final details = jsonDecode(settings!.subscriptionDetails!);
          currentSubscription.value = details;
        } catch (e) {
          // If JSON parsing fails, create a basic subscription object
          currentSubscription.value = {
            'planId': null,
            'name': settings!.subscriptionPlan ?? 'Basic',
            'amount': 250,
            'currency': 'INR',
            'startDate': null,
            'endDate': null,
          };
        }
      }
    } catch (e) {
      // Handle error gracefully
    }
  }

  double _calculateProfileCompletion(SellerDetailsExtended seller) {
    int completedFields = 0;
    int totalFields = 13; // Matching edit controller fields

    if (seller.businessname?.isNotEmpty == true) completedFields++;
    if (seller.profilename?.isNotEmpty == true) completedFields++;
    if (seller.bio?.isNotEmpty == true) completedFields++;
    if (seller.logo?.isNotEmpty == true) completedFields++;
    if (seller.contactno?.isNotEmpty == true) completedFields++;
    if (seller.mobileno?.isNotEmpty == true) completedFields++;
    if (seller.whatsappno?.isNotEmpty == true) completedFields++;
    if (seller.address?.isNotEmpty == true) completedFields++;
    if (seller.city?.isNotEmpty == true) completedFields++;
    if (seller.state?.isNotEmpty == true) completedFields++;
    if (seller.establishedyear != null) completedFields++;
    if (seller.geolocation?.isNotEmpty == true) completedFields++;
    if (seller.urls?.isNotEmpty == true) completedFields++;

    return completedFields / totalFields;
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void addProduct() {
    Get.toNamed('/seller-add-product');
  }

  void editProfile() {
    Get.toNamed('/seller-profile-edit');
  }

  void viewAnalytics() {
    Get.toNamed('/seller-analytics');
  }

  void manageAdvertising() {
    Get.toNamed('/seller-advertising');
  }

  void publishProfile() {
    Get.toNamed('/seller-publish');
  }

  void setStallLocation() {
    Get.toNamed('/seller-stall-location');
  }

  void viewProducts() {
    // Navigate to products tab (index 1 in the dashboard)
    changeTab(1);
  }

  void previewProfile() {
    Get.toNamed('/seller-profile-edit');
  }

  


  void refreshData() {
    _loadDashboardData();
  }

  // Subscription helper methods
  String get subscriptionPlanName {
    return currentSubscription.value?['name'] ?? 'Basic';
  }

  double get subscriptionAmount {
    return (currentSubscription.value?['amount'] as num?)?.toDouble() ?? 250.0;
  }

  String get subscriptionCurrency {
    return currentSubscription.value?['currency'] ?? 'INR';
  }
  
  String get subscriptionPeriod {
    return currentSubscription.value?['period'] ?? 'year';
  }
  
  int get subscriptionInterval {
    return currentSubscription.value?['interval'] ?? 1;
  }

  String? get subscriptionStartDate {
    final startDate = currentSubscription.value?['startDate'];
    if (startDate != null) {
      try {
        final date = DateTime.parse(startDate.toString());
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? get subscriptionEndDate {
    final endDate = currentSubscription.value?['endDate'];
    if (endDate != null) {
      try {
        final date = DateTime.parse(endDate.toString());
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
