import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:razorpay_web/razorpay_web.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/seller_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/payment_service.dart';
import '../../../../data/models/api/index.dart';
import '../../../../core/theme/app_theme.dart';
import '../../dashboard/controllers/seller_dashboard_controller.dart';

class ProfilePublishController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final SellerService _sellerService = Get.find<SellerService>();
  final SubscriptionService _subscriptionService = Get.find<SubscriptionService>();
  final PaymentGatewayManager _paymentGatewayManager = Get.put(PaymentGatewayManager());
  
  // Razorpay instance - works on all platforms with razorpay_web
  Razorpay? _razorpay;
  
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
      'gateway': PaymentGateway.razorpay,
      'name': 'Razorpay',
      'description': 'Pay with cards, UPI, wallets & more',
      'icon': Icons.payment,
      'recommended': true,
    },
    // {
    //   'id': 'cashfree',
    //   'gateway': PaymentGateway.cashfree,
    //   'name': 'Cashfree',
    //   'description': 'Secure payments with cards, UPI & wallets',
    //   'icon': Icons.account_balance_wallet,
    //   'recommended': false,
    // },
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
  final RxInt currentStep = 0.obs; // 0: Preview, 1: Success

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();
    _loadProfileData();
    loadSubscriptions();
  }

  @override
  void onClose() {
    _razorpay?.clear();
    super.onClose();
  }

  void _initializeRazorpay() {
    // Only initialize Razorpay on supported platforms (not web)
    // Initialize Razorpay - now works on all platforms with razorpay_web
    _razorpay = Razorpay();
    _razorpay!.on(RazorpayEvents.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(RazorpayEvents.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(RazorpayEvents.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
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
          currentStep.value = 1; // Already published, show success
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

  Future<void> loadSubscriptions() async {
    try {
      isLoading.value = true;
      
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
      Get.snackbar(
        'Network Error',
        'Unable to load subscription plans. Please check your internet connection and try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createBasicSubscription() async {
    try {
      final response = await _subscriptionService.ensureBasicSubscription();
      if (response.success && response.data != null) {
        selectedSubscription.value = response.data;
        availableSubscriptions.add(response.data!);
      } else {
        Get.snackbar(
          'Subscription Error',
          'Unable to create subscription plans. Please try again later.',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Unable to initialize subscription plans. Please check your internet connection.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  void selectSubscription(SubscriptionMaster subscription) {
    selectedSubscription.value = subscription;
    // Force refresh of UI elements that depend on subscription data
    selectedSubscription.refresh();
  }

  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  void nextStep() {
    if (currentStep.value < 1) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> processPayment() async {
    if (selectedSubscription.value == null || sellerProfile.value?.sellerid == null) {
      Get.snackbar('Error', 'Missing subscription or seller data');
      return;
    }

    // Check if subscription has valid pricing data
    if (subscriptionAmount == null || subscriptionCurrency == null) {
      Get.snackbar(
        'Payment Error',
        'Unable to load subscription details. Please check your internet connection and try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      isProcessingPayment.value = true;
      
      // Get selected payment gateway
      final selectedMethod = paymentMethods.firstWhere(
        (method) => method['id'] == selectedPaymentMethod.value,
        orElse: () => paymentMethods.first,
      );
      
      final PaymentGateway gateway = selectedMethod['gateway'];
      final paymentService = _paymentGatewayManager.getService(gateway);
      
      // Use the appropriate payment service
      if (gateway == PaymentGateway.razorpay) {
        await _processRazorpayPayment();
      } else if (gateway == PaymentGateway.cashfree) {
        await _processCashfreePayment(paymentService);
      }
      
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Unable to process payment. Please check your internet connection and try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      isProcessingPayment.value = false;
    }
  }

  Future<void> _processRazorpayPayment() async {
    // Create Razorpay order
    final orderResponse = await _sellerService.createRazorpayOrder(
      sellerId: sellerProfile.value!.sellerid!,
      subscriptionId: selectedSubscription.value!.subid!,
    );
    
    if (!orderResponse.success || orderResponse.data == null) {
      String errorMsg = 'Unable to initialize payment';
      if (orderResponse.errorMessage?.isNotEmpty == true) {
        errorMsg = orderResponse.errorMessage!;
      } else if (orderResponse.message?.isNotEmpty == true) {
        errorMsg = orderResponse.message!;
      }
      
      Get.snackbar(
        'Payment Error',
        errorMsg,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }
    
    // Launch Razorpay payment
    final options = {
      'key': orderResponse.data!['keyId'],
      'amount': orderResponse.data!['amount'],
      'name': 'FindMeBiz Subscription',
      'description': 'Seller subscription payment',
      'order_id': orderResponse.data!['orderId'],
      'prefill': {
        'contact': sellerProfile.value?.mobileno ?? '',
        'email': _authService.currentUser?.emailid ?? '',
      },
      'theme': {
        'color': '#0EA5A4'
      }
    };
    
    // Check if Razorpay is available (not on web)
    if (_razorpay != null) {
      _razorpay!.open(options);
    } else {
      // Web platform - show alternative payment method
      _handleWebPayment(orderResponse.data!);
    }
  }

  Future<void> _processCashfreePayment(PaymentService paymentService) async {
    try {
      final amount = (subscriptionAmount! * 100).toInt(); // Convert to paise
      
      final result = await paymentService.payINR(
        amountInPaise: amount,
        description: 'Seller subscription payment',
        receipt: 'sub_${selectedSubscription.value!.subid}_${DateTime.now().millisecondsSinceEpoch}',
        name: sellerProfile.value?.businessname ?? 'Customer',
        email: _authService.currentUser?.emailid ?? '',
        contact: sellerProfile.value?.mobileno ?? '',
        notes: {
          'seller_id': sellerProfile.value!.sellerid!.toString(),
          'subscription_id': selectedSubscription.value!.subid!.toString(),
        },
      );
      
      if (result.success) {
        await _handleCashfreeSuccess(result);
      } else {
        _handleCashfreeError(result.error ?? 'Payment failed');
      }
      
    } catch (e) {
      _handleCashfreeError('Payment processing failed: $e');
    } finally {
      isProcessingPayment.value = false;
    }
  }

  Future<void> _handleCashfreeSuccess(PaymentResult result) async {
    try {
      // Verify payment on backend (implement backend verification)
    
      
      paymentCompleted.value = true;
      paymentId.value = result.paymentId ?? '';
      
      // Show success message
      Get.snackbar(
        'Payment Successful',
        'Your subscription has been activated successfully',
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Wait a moment for user to see the success message

      
      // Navigate to dashboard and clear all previous routes
      _navigateToDashboardAndRefresh();
      
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Payment verification failed due to network error. Please check your internet connection.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    }
  }

  void _handleCashfreeError(String error) {
    isProcessingPayment.value = false;
    
    Get.snackbar(
      'Payment Failed', 
      error,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
    );
  }

  void _handleWebPayment(Map<String, dynamic> orderData) {
    // For web platform, show information about alternative payment methods
    Get.dialog(
      AlertDialog(
        title: const Text('Payment Not Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment processing is not available on the web version of this app.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'To complete your subscription and publish your profile, please:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Use the mobile app (Android/iOS)'),
            const Text('• Contact our support team for manual processing'),
            const SizedBox(height: 16),
            Text(
              'Order ID: ${orderData['orderId']}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              isProcessingPayment.value = false;
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Verify payment on backend
      final verifyResponse = await _sellerService.verifyRazorpayPayment(
        sellerId: sellerProfile.value!.sellerid!,
        subscriptionId: selectedSubscription.value!.subid!,
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        signature: response.signature!,
      );
      
      if (verifyResponse.success) {
        paymentCompleted.value = true;
        paymentId.value = response.paymentId!;
        
        // Show success message
        Get.snackbar(
          'Payment Successful',
          'Your subscription has been activated successfully',
          backgroundColor: AppTheme.successColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        // Wait a moment for user to see the success message

        
        // Navigate to dashboard and clear all previous routes
        _navigateToDashboardAndRefresh();
        
      } else {
        Get.snackbar(
          'Payment Verification Failed',
          'Payment was successful but verification failed. Please contact support if amount is deducted.',
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          colorText: Colors.orange.shade700,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Network Error',
        'Payment verification failed due to network error. Please check your internet connection.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isProcessingPayment.value = false;
    }
  }

  void _navigateToDashboardAndRefresh() {
    // Clear all routes and navigate to dashboard
    Get.offAllNamed('/seller-dashboard');
    
    // Refresh dashboard data after navigation

      try {
        final dashboardController = Get.find<SellerDashboardController>();
        dashboardController.refreshData();
      } catch (e) {
}
    }
  

  void _handlePaymentError(PaymentFailureResponse response) {
    isProcessingPayment.value = false;
    
    String errorMessage = 'Payment was unsuccessful';
    if (response.message?.toLowerCase().contains('network') == true ||
        response.message?.toLowerCase().contains('internet') == true) {
      errorMessage = 'Network error. Please check your internet connection and try again.';
    } else if (response.message?.toLowerCase().contains('cancelled') == true) {
      errorMessage = 'Payment was cancelled by user.';
    } else if (response.message?.isNotEmpty == true) {
      errorMessage = response.message!;
    }
    
    Get.snackbar(
      'Payment Failed', 
      errorMessage,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar('External Wallet', 'External wallet selected: ${response.walletName}');
  }

  Future<void> publishProfile() async {
    if (sellerProfile.value?.sellerid == null) {
      Get.snackbar('Error', 'Profile data missing');
      return;
    }

    try {
      isPublishing.value = true;
      
      // Publish profile directly without subscription requirement
      final response = await _sellerService.publishSellerProfile(
        sellerId: sellerProfile.value!.sellerid!,
      );
      
      if (response.success) {
        isPublished.value = true;
        currentStep.value = 1; // Success step
        
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
    _navigateToDashboardAndRefresh();
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
    
    return isBusinessNameValid && isBusinessLocationValid && isContactInfoValid && isBusinessLogoValid;
  }
  
  bool get isBusinessNameValid {
    final profile = sellerProfile.value;
    return profile?.businessname?.trim().isNotEmpty == true;
  }
  
  bool get isBusinessLogoValid {
    final profile = sellerProfile.value;
    return profile?.logo?.trim().isNotEmpty == true;
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
    if (!isBusinessLogoValid) errors.add('Business Logo is required');
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
  Map<String, dynamic>? get subscriptionConfig {
    if (selectedSubscription.value?.subconfig == null) {
      return null;
    }
    
    try {
      return jsonDecode(selectedSubscription.value!.subconfig);
    } catch (e) {
      return null; // No fallback - return null on error
    }
  }

  double? get subscriptionAmount {
    final config = subscriptionConfig;
    if (config == null) return null;
    return (config['amount'] as num?)?.toDouble();
  }

  String? get subscriptionCurrency {
    final config = subscriptionConfig;
    return config?['currency'] as String?;
  }
  
  String get subscriptionPeriod {
    return subscriptionConfig!['period'] as String? ?? 'year';
  }
  
  int get subscriptionInterval {
    return subscriptionConfig!['interval'] as int? ?? 1;
  }
  
  // Formatted subscription details for display
  List<MapEntry<String, String>> get subscriptionDetails {
    final config = subscriptionConfig;
    return config!.entries
        .map((entry) => MapEntry(entry.key, entry.value.toString()))
        .toList();
  }

  String get stepTitle {
    switch (currentStep.value) {
      case 0:
        return 'Preview Your Profile';
      case 1:
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
    if (profile.bio?.isEmpty != false) missing.add('Product Catalog');
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
