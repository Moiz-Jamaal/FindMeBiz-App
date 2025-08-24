import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:souq/app/services/auth_service.dart';
import 'package:souq/app/services/seller_service.dart';


class SellerReviewsController extends GetxController {
  final RxList<Map<String, dynamic>> sellerReviews = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> productReviews = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> statistics = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedTab = 'seller'.obs;

  @override
  void onInit() {
    super.onInit();
    loadReviews();
  }

  void loadReviews() async {
    final authService = Get.find<AuthService>();
    final sellerId = authService.currentSeller?.sellerId;
    if (sellerId == null) return;

    isLoading.value = true;
    try {
      final sellerService = Get.find<SellerService>();
      final response = await sellerService.getSellerReviews(sellerId);
      
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        sellerReviews.value = List<Map<String, dynamic>>.from(data['sellerReviews'] ?? []);
        productReviews.value = List<Map<String, dynamic>>.from(data['productReviews'] ?? []);
        
        // Calculate statistics from actual review data
        final sellerReviewsList = sellerReviews;
        final productReviewsList = productReviews;
        
        // Calculate seller review statistics
        double sellerTotalRating = 0.0;
        int sellerReviewCount = sellerReviewsList.length;
        for (var review in sellerReviewsList) {
          sellerTotalRating += (review['rating'] ?? 0).toDouble();
        }
        double sellerAvgRating = sellerReviewCount > 0 ? sellerTotalRating / sellerReviewCount : 0.0;
        
        // Calculate product review statistics
        double productTotalRating = 0.0;
        int productReviewCount = productReviewsList.length;
        for (var review in productReviewsList) {
          productTotalRating += (review['rating'] ?? 0).toDouble();
        }
        double productAvgRating = productReviewCount > 0 ? productTotalRating / productReviewCount : 0.0;
        
        // Use calculated statistics when API statistics are 0
        statistics.value = {
          'totalSellerReviews': sellerReviewCount,
          'avgSellerRating': sellerAvgRating,
          'totalProductReviews': productReviewCount,
          'avgProductRating': productAvgRating,
          'totalReviews': sellerReviewCount + productReviewCount,
          'averageRating': (sellerReviewCount + productReviewCount) > 0 
              ? (sellerTotalRating + productTotalRating) / (sellerReviewCount + productReviewCount) 
              : 0.0,
        };
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load reviews');
    }
    isLoading.value = false;
  }

  void switchTab(String tab) {
    selectedTab.value = tab;
  }

  void deleteSellerReview(int reviewId) async {
    final authService = Get.find<AuthService>();
    final sellerId = authService.currentSeller?.sellerId;
    if (sellerId == null) return;

    try {
      final sellerService = Get.find<SellerService>();
      final response = await sellerService.deleteSellerReview(reviewId, sellerId);
      
      if (response.isSuccess) {
        sellerReviews.removeWhere((review) => review['reviewid'] == reviewId);
        Get.snackbar('Success', 'Review deleted successfully');
      } else {
        Get.snackbar('Error', 'Failed to delete review');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error');
    }
  }

  void deleteProductReview(int reviewId) async {
    final authService = Get.find<AuthService>();
    final sellerId = authService.currentSeller?.sellerId;
    if (sellerId == null) return;

    try {
      final sellerService = Get.find<SellerService>();
      final response = await sellerService.deleteProductReview(reviewId, sellerId);
      
      if (response.isSuccess) {
        productReviews.removeWhere((review) => review['reviewid'] == reviewId);
        Get.snackbar('Success', 'Review deleted successfully');
      } else {
        Get.snackbar('Error', 'Failed to delete review');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error');
    }
  }

  void confirmDelete(bool isSellerReview, int reviewId, String reviewTitle) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Review'),
        content: Text('Are you sure you want to delete this review? This action cannot be undone.\n\n"$reviewTitle"'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              if (isSellerReview) {
                deleteSellerReview(reviewId);
              } else {
                deleteProductReview(reviewId);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
