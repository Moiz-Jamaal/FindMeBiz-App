import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum NotificationType {
  sellerUpdate,
  newProduct,
  priceUpdate,
  general,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class BuyerNotificationsController extends GetxController {
  // Notifications data
  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxBool isLoading = false.obs;
  
  // Filter state
  final RxString selectedFilter = 'All'.obs;
  final List<String> filterOptions = [
    'All',
    'Unread',
    'Seller Updates',
    'New Products',
    'Price Updates',
  ];
  
  // Stats
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  void _loadNotifications() {
    isLoading.value = true;
    
    Future.delayed(const Duration(milliseconds: 800), () {
      // Mock notifications data
      notifications.addAll([
        NotificationItem(
          id: '1',
          title: 'New Product Added',
          message: 'Surat Silk Emporium added "Premium Silk Saree" to their collection',
          type: NotificationType.newProduct,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          data: {'sellerId': '1', 'productId': 'p1'},
        ),
        NotificationItem(
          id: '2',
          title: 'Price Update',
          message: 'Diamond Jewelry House updated prices on selected items',
          type: NotificationType.priceUpdate,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          data: {'sellerId': '3'},
        ),
        NotificationItem(
          id: '3',
          title: 'Seller Update',
          message: 'Gujarati Handicrafts updated their business profile',
          type: NotificationType.sellerUpdate,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          data: {'sellerId': '2'},
        ),
        NotificationItem(
          id: '4',
          title: 'Welcome to FindMeBiz!',
          message: 'Discover amazing sellers and products at Istefada marketplace',
          type: NotificationType.general,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
        ),
        NotificationItem(
          id: '5',
          title: 'New Seller Nearby',
          message: 'A new seller "Traditional Crafts" just joined near your area',
          type: NotificationType.sellerUpdate,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          data: {'sellerId': '5'},
        ),
      ]);
      
      _updateUnreadCount();
      isLoading.value = false;
    });
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  List<NotificationItem> get filteredNotifications {
    switch (selectedFilter.value) {
      case 'Unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'Seller Updates':
        return notifications.where((n) => n.type == NotificationType.sellerUpdate).toList();
      case 'New Products':
        return notifications.where((n) => n.type == NotificationType.newProduct).toList();
      case 'Price Updates':
        return notifications.where((n) => n.type == NotificationType.priceUpdate).toList();
      default:
        return notifications.toList();
    }
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
  }

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
    _updateUnreadCount();
    
    Get.snackbar(
      'All Marked as Read',
      'All notifications marked as read',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void deleteNotification(String notificationId) {
    notifications.removeWhere((n) => n.id == notificationId);
    _updateUnreadCount();
    
    Get.snackbar(
      'Notification Deleted',
      'Notification removed',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void clearAllNotifications() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              notifications.clear();
              unreadCount.value = 0;
              Get.back();
              
              Get.snackbar(
                'All Cleared',
                'All notifications have been cleared',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void handleNotificationTap(NotificationItem notification) {
    // Mark as read
    markAsRead(notification.id);
    
    // Navigate based on notification type
    if (notification.data != null) {
      final data = notification.data!;
      
      switch (notification.type) {
        case NotificationType.newProduct:
          if (data['productId'] != null) {
            Get.toNamed('/buyer-product-view', arguments: data['productId']);
          }
          break;
        case NotificationType.sellerUpdate:
        case NotificationType.priceUpdate:
          if (data['sellerId'] != null) {
            Get.toNamed('/buyer-seller-view', arguments: data['sellerId']);
          }
          break;
        case NotificationType.general:
          // Handle general notifications
          break;
      }
    }
  }

  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newProduct:
        return Icons.new_releases;
      case NotificationType.priceUpdate:
        return Icons.price_change;
      case NotificationType.sellerUpdate:
        return Icons.store;
      case NotificationType.general:
        return Icons.info;
    }
  }

  Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newProduct:
        return Colors.green;
      case NotificationType.priceUpdate:
        return Colors.orange;
      case NotificationType.sellerUpdate:
        return Colors.blue;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  String getRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void refreshNotifications() {
    _loadNotifications();
  }
}
