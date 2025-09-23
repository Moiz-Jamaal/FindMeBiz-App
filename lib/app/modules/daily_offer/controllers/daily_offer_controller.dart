import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:souq/app/data/models/sponsored_content.dart';
import 'package:souq/app/services/auth_service.dart';
import '../../../../services/daily_offer_service.dart';


class DailyOfferController extends GetxController with GetTickerProviderStateMixin {
  final DailyOfferService _dailyOfferService = Get.find<DailyOfferService>();
  final AuthService _authService = Get.find<AuthService>();

  // Animation
  late AnimationController _flipController;
  late Animation<double> flipAnimation;

  // State
  final hasOffer = false.obs;
  final isRedeemed = false.obs;
  final isLoading = false.obs;
  final countdown = '00:00:00'.obs;
  final qrToken = ''.obs;
  final Rx<SponsoredContent?> offer = Rx<SponsoredContent?>(null);

  // Timer
  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _loadDailyOffer();
    _startCountdownTimer();
  }

  @override
  void onClose() {
    _flipController.dispose();
    _countdownTimer?.cancel();
    super.onClose();
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadDailyOffer() async {
    try {
      isLoading.value = true;
      
      final userId = _authService.currentUser?.userid;
      if (userId == null) {
return;
      }

  // Use existing TopCampaign API for daily_offer campaigns
  final offerResponse = await _dailyOfferService.getTodaysOffer(userId: userId);
if (offerResponse.success && offerResponse.data != null && offerResponse.data!.isNotEmpty) {
        final todaysOffer = offerResponse.data!.first;
        offer.value = todaysOffer;
        hasOffer.value = true;
// Generate QR token
        qrToken.value = _dailyOfferService.generateQRToken(userId);
        
        // Check redemption status separately
        final hasRedeemed = await _dailyOfferService.hasRedeemedToday(userId);
        isRedeemed.value = hasRedeemed;
} else {
        // Fallback: query full daily status
        final statusResp = await _dailyOfferService.getUserRedemptionStatus(userId);
if (statusResp.success && statusResp.data != null && statusResp.data!.hasTodaysOffer && statusResp.data!.todaysOffer != null) {
          offer.value = statusResp.data!.todaysOffer;
          hasOffer.value = true;
          isRedeemed.value = statusResp.data!.isRedeemed;
          qrToken.value = statusResp.data!.qrToken ?? _dailyOfferService.generateQRToken(userId);
} else {
          hasOffer.value = false;
}
      }
    } catch (e) {
} finally {
      isLoading.value = false;
    }
  }
   
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _dailyOfferService.getTimeUntilExpiry();
      countdown.value = _dailyOfferService.formatCountdown(remaining);
      
      // Stop timer when expired
      if (remaining.inSeconds <= 0) {
        timer.cancel();
        countdown.value = 'EXPIRED';
        _refreshOffer();
      }
    });
  }

  void flipCard() {
    if (isRedeemed.value) return; // Don't flip if already redeemed
    
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  Future<void> _refreshOffer() async {
    await _loadDailyOffer();
  }

  void refresh() {
    _refreshOffer();
  }

  // Helper getters
  bool get isShowingFront => flipAnimation.value < 0.5;
  bool get isShowingBack => flipAnimation.value >= 0.5;
  
  String get offerTitle => offer.value?.title ?? 'Daily Exclusive Offer';
  String get offerDescription => offer.value?.subtitle ?? 'Special offer just for you!';
  String? get offerImageUrl => offer.value?.imageUrl;
}
