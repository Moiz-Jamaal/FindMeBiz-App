import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/order.dart';

extension OrderStatusColors on OrderStatus {
  Color get color {
    switch (this) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.processing: return Colors.purple;
      case OrderStatus.shipped: return Colors.indigo;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }
}

class OrdersController extends GetxController {
  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedStatus = 'All'.obs;
  
  final List<String> statusFilters = [
    'All', 'Pending', 'Confirmed', 'Processing', 
    'Shipped', 'Delivered', 'Cancelled'
  ];

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  void loadOrders() {
    isLoading.value = true;
    
    Future.delayed(const Duration(seconds: 1), () {
      // Mock order data
      orders.clear();
      orders.addAll(_generateMockOrders());
      isLoading.value = false;
    });
  }

  List<Order> _generateMockOrders() {
    return [
      Order(
        id: 'ORD001',
        sellerId: 'seller1',
        sellerName: 'Surat Silk Emporium',
        items: [],
        totalAmount: 1250.00,
        status: OrderStatus.delivered,
        orderDate: DateTime.now().subtract(const Duration(days: 5)),
        deliveryAddress: 'A-23, Textile Market, Surat',
      ),
      Order(
        id: 'ORD002',
        sellerId: 'seller2',
        sellerName: 'Gujarati Crafts', 
        items: [],
        totalAmount: 850.00,
        status: OrderStatus.processing,
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        deliveryAddress: 'B-12, Handicraft Section, Surat',
      ),
    ];
  }

  List<Order> get filteredOrders {
    if (selectedStatus.value == 'All') return orders;
    return orders.where((order) => 
      order.status.name.toLowerCase() == selectedStatus.value.toLowerCase()).toList();
  }

  void filterByStatus(String status) => selectedStatus.value = status;

  void viewOrderDetails(String orderId) => 
    Get.toNamed('/buyer-order-details', arguments: orderId);

  void trackOrder(String orderId) => 
    Get.toNamed('/buyer-order-tracking', arguments: orderId);

  void reorderItems(Order order) {
    Get.snackbar('Items Added', 'Items added to cart successfully');
  }

  void cancelOrder(String orderId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          TextButton(
            onPressed: () {
              final orderIndex = orders.indexWhere((o) => o.id == orderId);
              if (orderIndex >= 0) {
                orders[orderIndex] = orders[orderIndex].copyWith(
                  status: OrderStatus.cancelled);
              }
              Get.back();
              Get.snackbar('Order Cancelled', 'Your order has been cancelled');
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
