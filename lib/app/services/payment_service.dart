import 'dart:async';

import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Lightweight payment result
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? error;

  PaymentResult.success({this.paymentId, this.orderId, this.signature})
      : success = true,
        error = null;

  PaymentResult.failure(this.error)
      : success = false,
        paymentId = null,
        orderId = null,
        signature = null;
}

/// Payment abstraction
abstract class PaymentService {
  Future<PaymentResult> payINR({
    required int amountInPaise,
    required String description,
    required String receipt,
    String? name,
    String? email,
    String? contact,
    Map<String, dynamic>? notes,
  });
}

/// Razorpay implementation
class RazorpayPaymentService extends GetxService implements PaymentService {
  late final Razorpay _razorpay;
  final _completer = Rx<Completer<PaymentResult>?>(null);

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
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
    // NOTE: In production, create an order on your backend and pass order_id here
    final options = {
      'key': const String.fromEnvironment('RAZORPAY_KEY', defaultValue: ''),
      'amount': amountInPaise, // paise
      'currency': 'INR',
      'name': name ?? 'FindMeBiz',
      'description': description,
      'order_id': null, // backend-generated order id recommended
      'timeout': 180, // seconds
      'prefill': {
        'contact': contact ?? '',
        'email': email ?? '',
      },
      if (notes != null) 'notes': notes,
      'theme': {'color': '#6A1B9A'},
    };

    final completer = Completer<PaymentResult>();
    _completer.value = completer;
    try {
      _razorpay.open(options);
    } catch (e) {
      _completer.value = null;
      return PaymentResult.failure(e.toString());
    }
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => PaymentResult.failure('Payment timed out'),
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final completer = _completer.value;
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        PaymentResult.success(
          paymentId: response.paymentId,
          orderId: response.orderId,
          signature: response.signature,
        ),
      );
      _completer.value = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final completer = _completer.value;
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        PaymentResult.failure(
          '${response.code}: ${response.message ?? 'Payment failed'}',
        ),
      );
      _completer.value = null;
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional: treat as cancel or wait for wallet callback
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
