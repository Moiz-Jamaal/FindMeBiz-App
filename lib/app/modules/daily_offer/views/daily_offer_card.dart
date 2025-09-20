import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:souq/app/core/constants/app_constants.dart';
import 'package:souq/app/core/theme/app_theme.dart';

import '../controllers/daily_offer_controller.dart';

class DailyOfferCard extends GetView<DailyOfferController> {
  const DailyOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasOffer.value) return const SizedBox.shrink();

      return Container(
        height: 320,
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: GestureDetector(
          onTap: controller.flipCard,
          child: AnimatedBuilder(
            animation: controller.flipAnimation,
            builder: (context, child) {
              final isShowingFront = controller.flipAnimation.value < 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(controller.flipAnimation.value * 3.14159),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.buyerPrimary.withOpacity(0.8),
                          const Color(0xFF6366F1).withOpacity(0.9),
                          const Color(0xFF8B5CF6).withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: isShowingFront ? _buildFrontSide() : _buildBackSide(),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildFrontSide() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: controller.offer.value?.imageUrl != null
                  ? Image.network(
                      controller.offer.value!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          _buildGradientBackground(),
                    )
                  : _buildGradientBackground(),
            ),
          ),
          
          // Content
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'DAILY EXCLUSIVE',
                                style: Get.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Countdown Timer
                        Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.countdown.value,
                            style: Get.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Offer Title
                    Text(
                      controller.offer.value?.title ?? 'Daily Exclusive Offer',
                      style: Get.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Offer Description
                    Text(
                      controller.offer.value?.subtitle ?? 
                          'Tap to reveal your exclusive QR code',
                      style: Get.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // CTA Button
                    if (!controller.isRedeemed.value)
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              controller.flipCard();
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Center(
                              child: Text(
                                'Claim Offer',
                                style: Get.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Already Redeemed',
                                style: Get.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: AppTheme.buyerPrimary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your QR Code',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flip_to_front),
                  onPressed: controller.flipCard,
                  color: AppTheme.buyerPrimary,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // QR Code
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Obx(() => QrImageView(
                    data: controller.qrToken.value,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.textPrimary,
                  )),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Text(
              'Show this QR code to the merchant to redeem your offer',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Expiry Notice
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Expires in ${controller.countdown.value}',
                style: Get.textTheme.labelMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.buyerPrimary,
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
          ],
        ),
      ),
    );
  }
}
