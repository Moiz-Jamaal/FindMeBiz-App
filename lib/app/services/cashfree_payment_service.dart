import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentcomponents/cfpaymentcomponent.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:souq/app/core/config/api_config.dart';
import 'payment_service.dart';
import 'auth_service.dart';

/// Cashfree payment implementation
class CashfreePaymentService extends GetxService implements PaymentService {
  CFPaymentGatewayService? _cfPaymentGatewayService;
  final _completer = Rx<Completer<PaymentResult>?>(null);
  final AuthService _authService = Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    _initializeCashfree();
  }

  void _initializeCashfree() {
    try {
      print('🔵 Initializing Cashfree SDK...');
      _cfPaymentGatewayService = CFPaymentGatewayService();
      _cfPaymentGatewayService!.setCallback(_onCashfreeVerify, _onCashfreeError);
      print('🟢 Cashfree SDK initialized successfully');
    } catch (e) {
      print('🔴 Failed to initialize Cashfree SDK: $e');
      Get.snackbar('Initialization Error', 'Failed to initialize Cashfree: $e');
    }
  }

  @override
  Future<PaymentResult> payINR({
    required int amountInPaise,
    required String description,
    required String receipt,
    String? name,
    String? email,
    String? contact,
    Map<String, dynamic>? notes,
  }) async {
    try {
      print('🔵 CASHFREE PAYMENT START');
      print('🔵 Amount in paise: $amountInPaise');
      print('🔵 Name: $name');
      print('🔵 Email: $email');
      print('🔵 Contact: $contact');
      print('🔵 Notes: $notes');
      
      // Convert paise to rupees for Cashfree (they expect amount in rupees)
      double amountInRupees = amountInPaise / 100.0;
      print('🔵 Amount in rupees: $amountInRupees');
      
      // Extract seller and subscription IDs from notes
      final sellerId = notes?['seller_id'] != null 
          ? int.tryParse(notes!['seller_id'].toString()) 
          : null;
      final subscriptionId = notes?['subscription_id'] != null 
          ? int.tryParse(notes!['subscription_id'].toString()) 
          : null;
      
      print('🔵 Extracted Seller ID: $sellerId');
      print('🔵 Extracted Subscription ID: $subscriptionId');
      
      if (sellerId == null || subscriptionId == null) {
        print('🔴 Missing seller or subscription information');
        return PaymentResult.failure('Missing seller or subscription information');
      }
      
      // Create order on backend first
      final orderData = await _createCashfreeOrder(
        sellerId: sellerId,
        subscriptionId: subscriptionId,
        amount: amountInRupees,
        currency: 'INR',
        customerName: name ?? 'Customer',
        customerEmail: email ?? '',
        customerPhone: contact ?? '',
        notes: notes,
      );
      
      if (orderData == null) {
        print('🔴 Failed to create order - orderData is null');
        return PaymentResult.failure('Failed to create payment order');
      }
      
      print('🔵 Order data received: $orderData');
      
      // Create Cashfree session
      print('🔵 Creating Cashfree session...');
      print('🔵 Order Token: ${orderData['orderToken']}');
      print('🔵 Order ID: ${orderData['orderId']}');
      
      if (orderData['orderToken'] == null || orderData['orderToken'].toString().isEmpty) {
        print('🔴 Order token is null or empty!');
        return PaymentResult.failure('Invalid order token received');
      }
      
      CFSession? cfSession;
      try {
        // Follow official documentation pattern exactly
        cfSession = CFSessionBuilder()
            .setEnvironment(CFEnvironment.PRODUCTION)  // Match backend production
            .setOrderId(orderData['orderId'].toString())
            .setPaymentSessionId(orderData['orderToken'].toString())
            .build();
        
        print('🟢 Cashfree session created successfully');
      } on CFException catch (e) {
        print('🔴 CFException creating session: ${e.message}');
        return PaymentResult.failure('Failed to create payment session: ${e.message}');
      } catch (e) {
        print('🔴 General error creating session: $e');
        return PaymentResult.failure('Failed to create payment session: $e');
      }
      
      print('🔵 Session created, building payment object...');
      
      // Create payment object
      final cfDropCheckoutPayment = CFDropCheckoutPaymentBuilder()
          .setSession(cfSession!)
          .setTheme(_buildCashfreeTheme())
          .build();
      
      // Set up completer for async payment result
      final completer = Completer<PaymentResult>();
      _completer.value = completer;
      
      print('🔵 Launching Cashfree payment...');
      
      // Launch payment
      _cfPaymentGatewayService!.doPayment(cfDropCheckoutPayment);
      
      return completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print('🔴 Payment timeout');
          return PaymentResult.failure('Payment timed out');
        },
      );
      
    } catch (e) {
      print('🔴 Exception in payINR: $e');
      return PaymentResult.failure('Payment initialization failed: $e');
    }
  }

  /// Create Cashfree order through backend API
  Future<Map<String, dynamic>?> _createCashfreeOrder({
    required int sellerId,
    required int subscriptionId,
    required double amount,
    required String currency,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    Map<String, dynamic>? notes,
  }) async {
    try {
      print('🔵 CASHFREE DEBUG: Starting order creation');
      print('🔵 Seller ID: $sellerId');
      print('🔵 Subscription ID: $subscriptionId');
      print('🔵 Amount: $amount $currency');
      
      final headers = {
        'Content-Type': 'application/json',
      };

      // Add authorization if available
      final currentUser = _authService.currentUser;
      if (currentUser?.emailid != null && currentUser?.upassword != null) {
        final credentials = base64Encode(
          utf8.encode('${currentUser!.emailid}:${currentUser.upassword}')
        );
        headers['Authorization'] = 'Basic $credentials';
        print('🔵 Authorization added for: ${currentUser.emailid}');
      } else {
        print('🔴 No user credentials available');
      }

      final requestBody = {
        'sellerId': sellerId,
        'subscriptionId': subscriptionId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
      };

      print('🔵 Request URL: ${ApiConfig.baseUrl}/FMB/CreateCashfreeOrder');
      print('🔵 Request Body: ${jsonEncode(requestBody)}');
      print('🔵 Headers: $headers');
      
      // Add a small delay to ensure request is properly formed
      await Future.delayed(const Duration(milliseconds: 100));

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/FMB/CreateCashfreeOrder'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🔵 Response Status: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔵 Parsed Response: $responseData');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          print('🟢 Order created successfully: ${responseData['data']}');
          return responseData['data'];
        } else {
          print('🔴 Order creation failed: ${responseData['message']}');
          Get.snackbar(
            'Order Creation Failed',
            responseData['message'] ?? 'Failed to create order',
          );
          return null;
        }
      } else {
        print('🔴 HTTP Error ${response.statusCode}: ${response.body}');
        Get.snackbar(
          'Network Error',
          'Failed to create order. Status: ${response.statusCode}',
        );
        return null;
      }
      
    } catch (e) {
      print('🔴 Exception in order creation: $e');
      Get.snackbar('Order Creation Failed', 'Unable to create payment order: $e');
      return null;
    }
  }

  /// Build Cashfree theme
  CFTheme _buildCashfreeTheme() {
    return CFThemeBuilder()
        .setNavigationBarTextColor("#FFFFFF")
        .setButtonBackgroundColor("#0EA5A4")
        .setButtonTextColor("#FFFFFF")
        .setPrimaryTextColor("#000000")
        .setSecondaryTextColor("#666666")
        .build();
  }

  /// Handle successful payment verification
  void _onCashfreeVerify(String orderId) async {
    try {
      print('🟢 CASHFREE VERIFY CALLBACK: $orderId');
      
      // Verify payment on backend
      final isVerified = await _verifyCashfreePayment(orderId);
      
      print('🔵 Verification result: $isVerified');
      
      final completer = _completer.value;
      if (completer != null && !completer.isCompleted) {
        if (isVerified) {
          print('🟢 Payment verified successfully, completing with success');
          completer.complete(PaymentResult.success(
            paymentId: orderId,
            orderId: orderId,
            signature: null, // Cashfree doesn't use signature like Razorpay
          ));
        } else {
          print('🔴 Payment verification failed');
          completer.complete(PaymentResult.failure('Payment verification failed'));
        }
        _completer.value = null;
      } else {
        print('🔴 No completer available or already completed');
      }
    } catch (e) {
      print('🔴 Exception in verify callback: $e');
      final completer = _completer.value;
      if (completer != null && !completer.isCompleted) {
        completer.complete(PaymentResult.failure('Verification error: $e'));
        _completer.value = null;
      }
    }
  }

  /// Handle payment errors
  void _onCashfreeError(CFErrorResponse errorResponse, String orderId) {
    print('🔴 CASHFREE ERROR CALLBACK');
    print('🔴 Order ID: $orderId');
    print('🔴 Error Message: ${errorResponse.getMessage()}');
    print('🔴 Error Status: ${errorResponse.getStatus()}');
    
    final completer = _completer.value;
    if (completer != null && !completer.isCompleted) {
      completer.complete(PaymentResult.failure(
        'Payment failed: ${errorResponse.getMessage()} (${errorResponse.getStatus()})'
      ));
      _completer.value = null;
    }
  }

  /// Verify payment on backend
  Future<bool> _verifyCashfreePayment(String orderId) async {
    try {
      print('🔵 VERIFYING PAYMENT: $orderId');
      
      final headers = {
        'Content-Type': 'application/json',
      };

      // Add authorization if available
      final currentUser = _authService.currentUser;
      if (currentUser?.emailid != null && currentUser?.upassword != null) {
        final credentials = base64Encode(
          utf8.encode('${currentUser!.emailid}:${currentUser.upassword}')
        );
        headers['Authorization'] = 'Basic $credentials';
        print('🔵 Verification auth for: ${currentUser.emailid}');
      } else {
        print('🔴 No auth for verification');
      }

      final requestBody = {
        'orderId': orderId,
        'paymentId': orderId, // For Cashfree, payment ID can be same as order ID
      };

      print('🔵 Verification URL: ${ApiConfig.baseUrl}/FMB/VerifyCashfreePayment');
      print('🔵 Verification Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/FMB/VerifyCashfreePayment'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🔵 Verification Status: ${response.statusCode}');
      print('🔵 Verification Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] == true;
        print('🔵 Verification success: $success');
        return success;
      } else {
        print('🔴 Verification HTTP error: ${response.statusCode}');
        Get.snackbar(
          'Verification Error',
          'Failed to verify payment. Status: ${response.statusCode}',
        );
        return false;
      }
      
    } catch (e) {
      print('🔴 Verification exception: $e');
      Get.snackbar('Verification Failed', 'Unable to verify payment: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _cfPaymentGatewayService = null;
    super.onClose();
  }
}
