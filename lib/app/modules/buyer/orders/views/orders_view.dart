import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/orders_controller.dart';

class OrdersView extends GetView<OrdersController> {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.statusFilters.length,
        itemBuilder: (context, index) {
          final status = controller.statusFilters[index];
          final isSelected = controller.selectedStatus.value == status;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (_) => controller.filterByStatus(status),
              backgroundColor: Colors.white,
              selectedColor: AppTheme.buyerPrimary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.buyerPrimary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      )),
    );
  }

  Widget _buildOrdersList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final orders = controller.filteredOrders;
      if (orders.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: AppTheme.textHint),
          const SizedBox(height: 16),
          Text('No orders found', style: Get.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Start shopping to see your orders here', style: Get.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildOrderCard(order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.id}', style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
                    Text(order.sellerName, style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(order.statusText, style: TextStyle(
                    color: order.status.color, 
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Order details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${order.totalAmount.toStringAsFixed(2)}', 
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: AppTheme.buyerPrimary, fontWeight: FontWeight.w600)),
                Text('${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                  style: Get.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.viewOrderDetails(order.id),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (order.canTrack) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.trackOrder(order.id),
                      child: const Text('Track'),
                    ),
                  ),
                ] else if (order.canCancel) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.cancelOrder(order.id),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Cancel'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.reorderItems(order),
                      child: const Text('Reorder'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension OrderStatusExtension on dynamic {
  Color get color {
    switch (toString().toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'processing': return Colors.purple;
      case 'shipped': return Colors.indigo;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
