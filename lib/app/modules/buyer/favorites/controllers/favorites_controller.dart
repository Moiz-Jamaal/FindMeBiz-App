import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/buyer_service.dart';
import '../../../../services/auth_service.dart';


class FavoriteItem {
  final int refId;
  final String type; // 'P' for Product, 'S' for Seller
  final String name;
  final String? description;
  final String? imageUrl;
  final double? price;
  final String? sellerName;
  final String? sellerPhone;
  final double? latitude;
  final double? longitude;
  final DateTime? addedAt;

  FavoriteItem({
    required this.refId,
    required this.type,
    required this.name,
    this.description,
    this.imageUrl,
    this.price,
    this.sellerName,
    this.sellerPhone,
    this.latitude,
    this.longitude,
    this.addedAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      refId: json['refId'] ?? 0,
      type: json['type'] ?? 'P',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      price: json['price']?.toDouble(),
      sellerName: json['sellerName'],
      sellerPhone: json['sellerPhone'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt']) : null,
    );
  }
}

class FavoritesController extends GetxController {
  final RxList<FavoriteItem> products = <FavoriteItem>[].obs;
  final RxList<FavoriteItem> sellers = <FavoriteItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedTab = 'products'.obs; // 'products' or 'sellers'
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  void loadFavorites() async {
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.userid == null) {
      _showSnackbar('Login Required', 'Please login to view favorites', Colors.orange);
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    
    try {
      final buyerService = Get.find<BuyerService>();
      final response = await buyerService.getUserFavorites(currentUser!.userid!);
      
      if (response.isSuccess && response.data != null) {
        products.clear();
        sellers.clear();
        
        final data = response.data;
        if (data!['products'] != null) {
          final productList = (data['products'] as List)
              .map((item) => FavoriteItem.fromJson(item))
              .toList();
          products.addAll(productList);
        }
        
        if (data['sellers'] != null) {
          final sellerList = (data['sellers'] as List)
              .map((item) => FavoriteItem.fromJson(item))
              .toList();
          sellers.addAll(sellerList);
        }
      } else {
        _setError('Failed to load favorites: ${response.errorMessage}');
      }
    } catch (e) {
      _setError('Network error. Please try again.');
    }
    
    isLoading.value = false;
  }

  void _setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
  }

  void switchTab(String tab) {
    selectedTab.value = tab;
  }

  void contactSeller(FavoriteItem item) async {
    if (item.sellerPhone == null || item.sellerPhone!.isEmpty) {
      _showSnackbar('Contact Info', 'No contact information available', Colors.orange);
      return;
    }

    try {
      final phone = item.sellerPhone!.replaceAll(RegExp(r'[^\d]'), '');
      final message = Uri.encodeComponent('Hi, I found your ${item.type == 'P' ? 'product' : 'business'} "${item.name}" on FindMeBiz and I\'m interested.');
      final url = 'https://wa.me/$phone?text=$message';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar('WhatsApp', 'WhatsApp not available. Phone: ${item.sellerPhone}', Colors.blue);
      }
    } catch (e) {
      _showSnackbar('Error', 'Could not open WhatsApp', Colors.red);
    }
  }

  void getDirections(FavoriteItem item) async {
    if (item.latitude == null || item.longitude == null || 
        item.latitude == 0.0 || item.longitude == 0.0) {
      _showSnackbar('Location', 'Location not available', Colors.orange);
      return;
    }

    try {
      final url = 'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar('Maps', 'Could not open maps', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Error', 'Could not open maps', Colors.red);
    }
  }

  void removeFromFavorites(FavoriteItem item) async {
    final authService = Get.find<AuthService>();
    final currentUser = authService.currentUser;
    
    if (currentUser?.userid == null) {
      _showSnackbar('Login Required', 'Please login to manage favorites', Colors.orange);
      return;
    }

    try {
      final buyerService = Get.find<BuyerService>();
      final response = await buyerService.removeFromFavorites(
        userId: currentUser!.userid!,
        refId: item.refId,
        type: item.type,
      );
      
      if (response.isSuccess) {
        if (item.type == 'P') {
          products.removeWhere((p) => p.refId == item.refId);
        } else {
          sellers.removeWhere((s) => s.refId == item.refId);
        }
        _showSnackbar('Removed', 'Removed from favorites', Colors.grey);
      } else {
        _showSnackbar('Error', 'Failed to remove from favorites', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Error', 'Network error. Please try again.', Colors.red);
    }
  }

  void viewProduct(FavoriteItem item) {
    Get.toNamed('/buyer-product-view', arguments: item.refId);
  }

  void viewSeller(FavoriteItem item) {
    Get.toNamed('/buyer-seller-view', arguments: item.refId);
  }

  void _showSnackbar(String title, String message, Color backgroundColor) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
    );
  }
}
