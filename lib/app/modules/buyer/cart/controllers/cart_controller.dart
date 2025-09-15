import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/cart_item.dart';
import '../../../../core/theme/app_theme.dart';

class CartController extends GetxController {
  // Cart items
  final RxList<CartItem> cartItems = <CartItem>[].obs;
  
  // Cart state
  final RxBool isLoading = false.obs;
  final RxDouble subtotal = 0.0.obs;
  final RxDouble tax = 0.0.obs;
  final RxDouble deliveryFee = 0.0.obs;
  final RxDouble total = 0.0.obs;
  
  // UI state
  final RxBool isProcessingCheckout = false.obs;
  final RxString promoCode = ''.obs;
  final RxDouble discount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCart();
    
    // Listen to cart changes and recalculate totals
    ever(cartItems, (_) => _calculateTotals());
  }

  // Add item to cart
  void addToCart(Product product, {int quantity = 1}) {
    final existingItemIndex = cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex >= 0) {
      // Update quantity if item exists
      cartItems[existingItemIndex] = cartItems[existingItemIndex].copyWith(
        quantity: cartItems[existingItemIndex].quantity + quantity,
      );
    } else {
      // Add new item
      cartItems.add(CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: quantity,
        addedAt: DateTime.now(),
      ));
    }
    
    _saveCart();
    Get.snackbar(
      'Added to Cart',
      '${product.name} added to cart',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.buyerPrimary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // Remove item from cart
  void removeFromCart(String itemId) {
    cartItems.removeWhere((item) => item.id == itemId);
    _saveCart();
  }

  // Update item quantity
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final itemIndex = cartItems.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      cartItems[itemIndex] = cartItems[itemIndex].copyWith(quantity: quantity);
      _saveCart();
    }
  }

  // Clear cart
  void clearCart() {
    cartItems.clear();
    _saveCart();
  }

  // Get cart item count
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Check if product is in cart
  bool isInCart(String productId) {
    return cartItems.any((item) => item.product.id == productId);
  }

  // Get quantity of specific product in cart
  int getProductQuantity(String productId) {
    final item = cartItems.firstWhereOrNull(
      (item) => item.product.id == productId,
    );
    return item?.quantity ?? 0;
  }

  // Apply promo code
  void applyPromoCode(String code) {
    // Mock promo code validation
    if (code.toUpperCase() == 'SAVE10') {
      discount.value = subtotal.value * 0.1;
      promoCode.value = code;
      _calculateTotals();
      Get.snackbar(
        'Promo Applied',
        '10% discount applied!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Invalid Code',
        'Promo code not found',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Remove promo code
  void removePromoCode() {
    promoCode.value = '';
    discount.value = 0.0;
    _calculateTotals();
  }

  // Proceed to checkout
  void proceedToCheckout() {
    if (cartItems.isEmpty) {
      Get.snackbar(
        'Cart Empty',
        'Add items to cart before checkout',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.toNamed('/buyer-checkout', arguments: {
      'cartItems': cartItems,
      'total': total.value,
    });
  }

  // Calculate totals
  void _calculateTotals() {
    subtotal.value = cartItems.fold(
      0.0,
      (sum, item) => sum + ((item.product.price ?? 0.0) * item.quantity),
    );
    
    // Calculate tax (10%)
    tax.value = subtotal.value * 0.1;
    
    // Delivery fee (free for orders > 100)
    deliveryFee.value = subtotal.value > 100 ? 0.0 : 10.0;
    
    // Total = subtotal + tax + delivery - discount
    total.value = subtotal.value + tax.value + deliveryFee.value - discount.value;
  }

  // Load cart from storage (mock)
  void _loadCart() {
    // In real app, load from local storage or API
 
  }

  // Save cart to storage (mock)
  void _saveCart() {
    // In real app, save to local storage
    // Get.find<StorageService>().saveCart(cartItems);
  }
}
