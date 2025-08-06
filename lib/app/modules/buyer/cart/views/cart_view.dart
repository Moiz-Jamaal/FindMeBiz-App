import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/cart_controller.dart';

class CartView extends GetView<CartController> {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Obx(() => Text('Cart (${controller.itemCount})')),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Obx(() => controller.cartItems.isNotEmpty
              ? TextButton(
                  onPressed: () => _showClearCartDialog(),
                  child: Text('Clear', style: TextStyle(color: Colors.red)),
                )
              : const SizedBox()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.cartItems.isEmpty) {
          return _buildEmptyCart();
        }

        return Column(
          children: [
            Expanded(child: _buildCartItems()),
            _buildCartSummary(),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.textHint),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: Get.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Start shopping to add items', style: Get.textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.buyerPrimary),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: controller.cartItems.length,
      itemBuilder: (context, index) {
        final item = controller.cartItems[index];
        return _buildCartItemCard(item);
      },
    );
  }

  Widget _buildCartItemCard(item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: Icon(Icons.image, color: AppTheme.textHint),
            ),
            
            const SizedBox(width: 12),
            
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('₹${item.product.price}', style: Get.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.buyerPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  
                  // Quantity controls
                  Row(
                    children: [
                      _buildQuantityButton(
                        Icons.remove,
                        () => controller.updateQuantity(item.id, item.quantity - 1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('${item.quantity}', style: Get.textTheme.titleMedium),
                      ),
                      _buildQuantityButton(
                        Icons.add,
                        () => controller.updateQuantity(item.id, item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Remove button and total
            Column(
              children: [
                IconButton(
                  onPressed: () => controller.removeFromCart(item.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                Text('₹${(item.product.price * item.quantity).toStringAsFixed(2)}',
                  style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.buyerPrimary),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Icon(icon, size: 18, color: AppTheme.buyerPrimary),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promo code section
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: controller.applyPromoCode,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {}, // Apply promo code
                child: const Text('Apply'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price breakdown
          _buildPriceRow('Subtotal', controller.subtotal.value),
          _buildPriceRow('Tax', controller.tax.value),
          _buildPriceRow('Delivery', controller.deliveryFee.value),
          
          Obx(() => controller.discount.value > 0
              ? _buildPriceRow('Discount', -controller.discount.value, color: Colors.green)
              : const SizedBox()),
          
          const Divider(),
          
          Obx(() => _buildPriceRow('Total', controller.total.value, isTotal: true)),
          
          const SizedBox(height: 16),
          
          // Checkout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buyerPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          )),
          Text('₹${amount.toStringAsFixed(2)}', style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: color,
          )),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.clearCart();
              Get.back();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
