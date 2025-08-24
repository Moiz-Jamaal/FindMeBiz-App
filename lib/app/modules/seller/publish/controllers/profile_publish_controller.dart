import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../../data/models/api/index.dart';
import '../../../../core/theme/app_theme.dart';

class ProfilePublishController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  final SubscriptionService _subscriptionService = Get.find<SubscriptionService>();
  
  // Profile data
  final Rx<SellerDetailsExtended?> sellerProfile = Rx<SellerDetailsExtended?>(null);
  final RxList<SubscriptionMaster> availableSubscriptions = <SubscriptionMaster>[].obs;
  final Rx<SubscriptionMaster?> selectedSubscription = Rx<SubscriptionMaster?>(null);
  
  // Mock products list (since products module is skipped)
  final RxList<dynamic> products = <dynamic>[].obs;
  
  // Payment methods
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'razorpay',
      'name': 'Razorpay',
      'description': 'Pay with cards, UPI, wallets & more',
      'icon': Icons.payment,
      'recommended': true,
    },
    {
      'id': 'upi',
      'name': 'UPI',
      'description': 'Pay directly with UPI apps',
      'icon': Icons.account_balance_wallet,
      'recommended': false,
    },
  ];
  
  // Payment state
  final RxString selectedPaymentMethod = 'razorpay'.obs;
  final RxBool isProcessingPayment = false.obs;
  final RxBool paymentCompleted = false.obs;
  final RxString paymentId = ''.obs;
  
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
    _loadSubscriptions();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data when page becomes ready (e.g., returning from edit)
    refreshProfileData();
  }

  /// Refresh profile data - call when returning from edit
  Future<void> refreshProfileData() async {
    await _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      isLoading.value = true;
      
      final currentUser = _authService.currentUser;
      if (currentUser?.userid == null) {
        Get.snackbar('Error', 'No user found. Please login again.');
        return;
      }

      // Load seller profile
      final response = await _sellerService.getSellerByUserId(currentUser!.userid!);
      
      if (response.success && response.data != null) {
        sellerProfile.value = response.data;
        isPublished.value = response.data!.ispublished ?? false;
        
        if (isPublished.value) {
          currentStep.value = 2; // Already published, show success
        }
      } else {
        Get.snackbar('Error', 'No seller profile found. Please complete onboarding first.');
        Get.back(); // Go back if no profile
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load profile data');
      
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      final response = await _subscriptionService.getSubscriptions();
      
      if (response.success && response.data != null) {
        // Sort by subid to ensure consistent order
        availableSubscriptions.value = response.data!
          ..sort((a, b) => (a.subid ?? 0).compareTo(b.subid ?? 0));
        
        // Auto-select first subscription by subid
        if (availableSubscriptions.isNotEmpty) {
          selectedSubscription.value = availableSubscriptions.first;
        }
      } else {
        // Create basic subscription if none exist
        await _createBasicSubscription();
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load subscription plans');
      
    }
  }

  Future<void> _createBasicSubscription() async {
   
      final response = await _subscriptionService.ensureBasicSubscription();
      if (response.success && response.data != null) {
        selectedSubscription.value = response.data;
        availableSubscriptions.add(response.data!);
      }
   
  }

  void selectSubscription(SubscriptionMaster subscription) {
    selectedSubscription.value = subscription;
  }

  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> processPayment() async {
    if (selectedSubscription.value == null) {
      Get.snackbar('Error', 'Please select a subscription plan');
      return;
    }

    try {
      isProcessingPayment.value = true;
      
      // Simulate payment processing with Razorpay
      // In real implementation, integrate with Razorpay SDK
      await Future.delayed(const Duration(seconds: 3));
      
      // Mock successful payment
      paymentCompleted.value = true;
      paymentId.value = 'pay_${DateTime.now().millisecondsSinceEpoch}';
      
      Get.snackbar(
        'Payment Successful',
        'Your payment has been processed successfully',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
      
      // Proceed to publish profile
      await publishProfile();
      
    } catch (e) {
      Get.snackbar('Payment Failed', 'Failed to process payment. Please try again.');
      
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<void> publishProfile() async {
    if (sellerProfile.value?.sellerid == null || selectedSubscription.value == null) {
      Get.snackbar('Error', 'Profile or subscription data missing');
      return;
    }

    try {
      isPublishing.value = true;
      
      // Parse subscription config to get amount details
      Map<String, dynamic> subscriptionConfig = {};
      try {
        subscriptionConfig = jsonDecode(selectedSubscription.value!.subconfig );
      } catch (e) {
        subscriptionConfig = {'amount': 250, 'currency': 'INR'};
      }
      
      // Set seller subscription
      final response = await _sellerService.setSellerSubscription(
        sellerId: sellerProfile.value!.sellerid!,
        planName: selectedSubscription.value!.subname,
        amount: (subscriptionConfig['amount'] as num?)?.toDouble(),
        currency: subscriptionConfig['currency'] as String?,
        razorpayPaymentId: paymentId.value.isNotEmpty ? paymentId.value : null,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)), // 1 year
      );
      
      if (response.success) {
        isPublished.value = true;
        currentStep.value = 2; // Success step
        
        Get.snackbar(
          'Profile Published!',
          'Your seller profile is now live and visible to customers',
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        
        // Refresh profile data
        await _loadProfileData();
        
      } else {
        Get.snackbar('Publishing Failed', response.message ?? 'Failed to publish profile');
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to publish profile');
      
    } finally {
      isPublishing.value = false;
    }
  }

  void goToDashboard() {
    Get.offAllNamed('/seller-dashboard');
  }

  void retryPayment() {
    paymentCompleted.value = false;
    paymentId.value = '';
    currentStep.value = 1; // Back to payment step
  }

  void editProfile() {
    Get.toNamed('/seller-profile-edit')?.then((_) {
      // Refresh data when returning from edit profile
      refreshProfileData();
    });
  }

  void previewProfile() {
    Get.toNamed('/seller-profile-preview', arguments: sellerProfile.value);
  }

  // Add missing methods for the view
  void previewAsbuyer() {
    previewProfile();
  }

  void addMoreProducts() {
    // Products module is skipped - redirect to dashboard
    Get.snackbar(
      'Feature Unavailable',
      'Product management has been temporarily disabled',
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      colorText: Colors.grey[600],
    );
  }

  void proceedToPayment() {
    nextStep();
  }

  // Payment status message getter
  String get paymentStatusMessage {
    if (isProcessingPayment.value) {
      return 'Processing payment...';
    } else if (paymentCompleted.value) {
      return 'Payment completed successfully!';
    } else {
      return 'Ready to process payment';
    }
  }

  // Validation Methods
  bool get isProfileValid {
    final profile = sellerProfile.value;
    if (profile == null) return false;
    
    return isBusinessNameValid && isBusinessLocationValid && isContactInfoValid;
  }
  
  bool get isBusinessNameValid {
    final profile = sellerProfile.value;
    return profile?.businessname?.trim().isNotEmpty == true;
  }
  
  bool get isBusinessLocationValid {
    final profile = sellerProfile.value;
    return profile?.address?.trim().isNotEmpty == true &&
           profile?.city?.trim().isNotEmpty == true &&
           profile?.geolocation?.trim().isNotEmpty == true;
  }
  
  bool get isContactInfoValid {
    final profile = sellerProfile.value;
    return profile?.contactno?.trim().isNotEmpty == true &&
           profile?.mobileno?.trim().isNotEmpty == true &&
           profile?.whatsappno?.trim().isNotEmpty == true;
  }
  
  List<String> get validationErrors {
    List<String> errors = [];
    if (!isBusinessNameValid) errors.add('Business Name is required');
    if (!isBusinessLocationValid) {
      if (sellerProfile.value?.address?.trim().isEmpty != false) errors.add('Business Address is required');
      if (sellerProfile.value?.city?.trim().isEmpty != false) errors.add('Business City is required');
      if (sellerProfile.value?.geolocation?.trim().isEmpty != false) errors.add('Business Location coordinates are required');
    }
    if (!isContactInfoValid) {
      if (sellerProfile.value?.contactno?.trim().isEmpty != false) errors.add('Contact Number is required');
      if (sellerProfile.value?.mobileno?.trim().isEmpty != false) errors.add('Mobile Number is required');
      if (sellerProfile.value?.whatsappno?.trim().isEmpty != false) errors.add('WhatsApp Number is required');
    }
    return errors;
  }

  // Subscription Getters with JSON parsing
  Map<String, dynamic> get subscriptionConfig {
    if (selectedSubscription.value?.subconfig == null) {
      return {'amount': 250, 'currency': 'INR', 'period': 'year', 'interval': 1};
    }
    
    try {
      return jsonDecode(selectedSubscription.value!.subconfig);
    } catch (e) {
      return {'amount': 250, 'currency': 'INR', 'period': 'year', 'interval': 1};
    }
  }

  double get subscriptionAmount {
    return (subscriptionConfig['amount'] as num?)?.toDouble() ?? 250.0;
  }

  String get subscriptionCurrency {
    return subscriptionConfig['currency'] as String? ?? 'INR';
  }
  
  String get subscriptionPeriod {
    return subscriptionConfig['period'] as String? ?? 'year';
  }
  
  int get subscriptionInterval {
    return subscriptionConfig['interval'] as int? ?? 1;
  }
  
  // Formatted subscription details for display
  List<MapEntry<String, String>> get subscriptionDetails {
    final config = subscriptionConfig;
    return config.entries
        .map((entry) => MapEntry(entry.key, entry.value.toString()))
        .toList();
  }

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
        return 'Pay $subscriptionCurrency ${subscriptionAmount.toStringAsFixed(0)} to make your profile visible';
      case 2:
        return 'Your profile is now live and visible to buyers';
      default:
        return '';
    }
  }

  bool get canProceed {
    switch (currentStep.value) {
      case 0:
        return sellerProfile.value != null && isProfileValid;
      case 1:
        return selectedPaymentMethod.value.isNotEmpty && !isProcessingPayment.value;
      case 2:
        return true;
      default:
        return false;
    }
  }

  double get profileCompletionScore {
    final profile = sellerProfile.value;
    if (profile == null) return 0.0;
    
    int completedFields = 0;
    int totalFields = 13; // Matching edit controller fields
    
    if (profile.businessname?.isNotEmpty == true) completedFields++;
    if (profile.profilename?.isNotEmpty == true) completedFields++;
    if (profile.bio?.isNotEmpty == true) completedFields++;
    if (profile.logo?.isNotEmpty == true) completedFields++;
    if (profile.contactno?.isNotEmpty == true) completedFields++;
    if (profile.mobileno?.isNotEmpty == true) completedFields++;
    if (profile.whatsappno?.isNotEmpty == true) completedFields++;
    if (profile.address?.isNotEmpty == true) completedFields++;
    if (profile.city?.isNotEmpty == true) completedFields++;
    if (profile.state?.isNotEmpty == true) completedFields++;
    if (profile.establishedyear != null) completedFields++;
    if (profile.geolocation?.isNotEmpty == true) completedFields++;
    if (profile.urls?.isNotEmpty == true) completedFields++;
    
    return completedFields / totalFields;
  }

  String get profileCompletionMessage {
    final score = profileCompletionScore;
    if (score >= 0.8) return 'Excellent! Your profile is well-detailed.';
    if (score >= 0.6) return 'Good! Your profile is ready to publish.';
    if (score >= 0.4) return 'Consider adding more details to improve visibility.';
    return 'Please complete more fields before publishing.';
  }

  List<String> get missingFields {
    final profile = sellerProfile.value;
    if (profile == null) return ['Complete seller onboarding first'];
    
    List<String> missing = [];
    
    if (profile.businessname?.isEmpty != false) missing.add('Business Name');
    if (profile.profilename?.isEmpty != false) missing.add('Profile Name');
    if (profile.bio?.isEmpty != false) missing.add('Business Description');
    if (profile.logo?.isEmpty != false) missing.add('Business Logo');
    if (profile.contactno?.isEmpty != false) missing.add('Contact Number');
    if (profile.mobileno?.isEmpty != false) missing.add('Mobile Number');
    if (profile.whatsappno?.isEmpty != false) missing.add('WhatsApp Number');
    if (profile.address?.isEmpty != false) missing.add('Business Address');
    if (profile.city?.isEmpty != false) missing.add('City');
    if (profile.state?.isEmpty != false) missing.add('State');
    if (profile.establishedyear == null) missing.add('Established Year');
    if (profile.geolocation?.isEmpty != false) missing.add('Location');
    if (profile.urls?.isEmpty != false) missing.add('Social Media Links');
    
    return missing;
  }
}
