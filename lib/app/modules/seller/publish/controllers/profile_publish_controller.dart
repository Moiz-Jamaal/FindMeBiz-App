import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/seller.dart';
import '../../../../data/models/product.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class ProfilePublishController extends GetxController {
  // Profile data
  final Rx<Seller?> sellerProfile = Rx<Seller?>(null);
  final RxList<Product> products = <Product>[].obs;
  
  // Payment state
  final RxString selectedPaymentMethod = 'razorpay'.obs;
  final RxBool isProcessingPayment = false.obs;
  final RxBool paymentCompleted = false.obs;
  
  // Publishing state
  final RxBool isPublishing = false.obs;
  final RxBool isPublished = false.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxInt currentStep = 0.obs; // 0: Preview, 1: Payment, 2: Success

  @override
  void onInit() {
    super.onInit();
    _loadProfileData();
  }

  void _loadProfileData() {
    isLoading.value = true;
    
    // Simulate loading seller profile and products
    Future.delayed(const Duration(seconds: 1), () {
      // Mock seller data
      sellerProfile.value = Seller(
        id: 'seller_1',
        email: 'rajesh@suratsik.com',
        fullName: 'Rajesh Patel',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        businessName: 'Surat Silk Emporium',
        bio: 'Premium silk sarees and traditional wear from Surat. Family business since 1985 with authentic designs.',
        socialMediaLinks: ['instagram:@suratsik_emporium'],
        whatsappNumber: '+91 98765 43210',
        profileCompletionScore: 0.85,
      );
      
      // Mock products
      products.addAll([
        Product(
          id: '1',
          sellerId: 'seller_1',
          name: 'Beautiful Silk Saree',
          description: 'Traditional Surat silk saree with intricate designs.',
          price: 2500.0,
          category: 'Apparel',
          images: ['mock_image_1'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          id: '2',
          sellerId: 'seller_1',
          name: 'Handcrafted Jewelry Set',
          description: 'Elegant jewelry set with matching earrings.',
          price: 1800.0,
          category: 'Jewelry',
          images: ['mock_image_2'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
      
      isLoading.value = false;
    });
  }

  void proceedToPayment() {
    if (currentStep.value == 0) {
      currentStep.value = 1;
    }
  }

  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  void processPayment() {
    if (selectedPaymentMethod.value.isEmpty) {
      Get.snackbar(
        'Payment Method Required',
        'Please select a payment method',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isProcessingPayment.value = true;

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 3), () {
      isProcessingPayment.value = false;
      paymentCompleted.value = true;
      
      // Auto proceed to publishing
      _publishProfile();
    });
  }

  void _publishProfile() {
    isPublishing.value = true;
    
    // Simulate profile publishing
    Future.delayed(const Duration(seconds: 2), () {
      isPublishing.value = false;
      isPublished.value = true;
      currentStep.value = 2;
      
      Get.snackbar(
        'Success!',
        'Your profile is now live and visible to buyers',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    });
  }

  void goToDashboard() {
    Get.offAllNamed('/seller-dashboard');
  }

  void previewAsbuyer() {
    Get.toNamed('/seller-profile-preview', arguments: sellerProfile.value);
  }

  void editProfile() {
    Get.toNamed('/seller-profile-edit');
  }

  void addMoreProducts() {
    Get.toNamed('/seller-add-product');
  }

  // Getters for UI
  String get stepTitle {
    switch (currentStep.value) {
      case 0:
        return 'Preview Your Profile';
      case 1:
        return 'Complete Payment';
      case 2:
        return 'Profile Published!';
      default:
        return 'Publish Profile';
    }
  }

  String get stepDescription {
    switch (currentStep.value) {
      case 0:
        return 'Review your profile before publishing';
      case 1:
        return 'Pay ${AppConstants.currency}${AppConstants.sellerEntryFee.toStringAsFixed(0)} to make your profile visible';
      case 2:
        return 'Your profile is now live and visible to buyers';
      default:
        return '';
    }
  }

  bool get canProceed {
    switch (currentStep.value) {
      case 0:
        return sellerProfile.value != null && products.isNotEmpty;
      case 1:
        return selectedPaymentMethod.value.isNotEmpty && !isProcessingPayment.value;
      case 2:
        return true;
      default:
        return false;
    }
  }

  double get profileCompletionScore {
    if (sellerProfile.value == null) return 0.0;
    
    double score = 0.0;
    int totalChecks = 8;
    
    // Basic info checks
    if (sellerProfile.value!.businessName.isNotEmpty) score += 1;
    if (sellerProfile.value!.fullName.isNotEmpty) score += 1;
    if (sellerProfile.value!.email.isNotEmpty) score += 1;
    if (sellerProfile.value!.bio?.isNotEmpty == true) score += 1;
    
    // Contact checks
    if (sellerProfile.value!.whatsappNumber?.isNotEmpty == true) score += 1;
    
    // Products check
    if (products.isNotEmpty) score += 1;
    
    // Social media check
    if (sellerProfile.value!.socialMediaLinks.isNotEmpty) score += 1;
    
    // Images check (placeholder)
    score += 1; // Always count as having images in mock
    
    return score / totalChecks;
  }

  List<Map<String, dynamic>> get paymentMethods {
    return [
      {
        'id': 'razorpay',
        'name': 'Razorpay',
        'description': 'Credit/Debit Card, UPI, Net Banking',
        'icon': Icons.payment,
        'recommended': true,
      },
      {
        'id': 'upi',
        'name': 'UPI',
        'description': 'Google Pay, PhonePe, Paytm',
        'icon': Icons.account_balance_wallet,
        'recommended': false,
      },
      {
        'id': 'netbanking',
        'name': 'Net Banking',
        'description': 'All major banks supported',
        'icon': Icons.account_balance,
        'recommended': false,
      },
    ];
  }

  String get paymentStatusMessage {
    if (isProcessingPayment.value) {
      return 'Processing your payment...';
    } else if (paymentCompleted.value) {
      return 'Payment completed successfully!';
    } else {
      return 'Complete payment to publish your profile';
    }
  }
}
