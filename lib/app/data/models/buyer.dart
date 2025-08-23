import 'user.dart';
import 'user_role.dart';

class Buyer extends User {
  final String? address;
  final String preferredLanguage;
  final List<String> favoriteSellerIds;
  final List<String> recentlyViewedSellerIds;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> preferences;

  Buyer({
    required super.id,
    required super.email,
    required super.fullName,
    super.profileImage,
    super.phoneNumber,
    required super.createdAt,
    required super.updatedAt,
    super.isActive,
    this.address,
    this.preferredLanguage = 'English',
    this.favoriteSellerIds = const [],
    this.recentlyViewedSellerIds = const [],
    this.lastLoginAt,
    this.preferences = const {},
  }) : super(
          role: UserRole.buyer,
        );

  factory Buyer.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    
    return Buyer(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      profileImage: user.profileImage,
      phoneNumber: user.phoneNumber,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isActive: user.isActive,
      address: json['address'] as String?,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'English',
      favoriteSellerIds: List<String>.from(json['favoriteSellerIds'] ?? []),
      recentlyViewedSellerIds: List<String>.from(json['recentlyViewedSellerIds'] ?? []),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'address': address,
      'preferredLanguage': preferredLanguage,
      'favoriteSellerIds': favoriteSellerIds,
      'recentlyViewedSellerIds': recentlyViewedSellerIds,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
    });
    return json;
  }

  @override
  Buyer copyWith({
    String? id,
    String? email,
    String? fullName,
    String? profileImage,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    UserRole? role,
    String? address,
    String? preferredLanguage,
    List<String>? favoriteSellerIds,
    List<String>? recentlyViewedSellerIds,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return Buyer(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      address: address ?? this.address,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      favoriteSellerIds: favoriteSellerIds ?? this.favoriteSellerIds,
      recentlyViewedSellerIds: recentlyViewedSellerIds ?? this.recentlyViewedSellerIds,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }

  // Helper methods
  bool isFavoriteSeller(String sellerId) {
    return favoriteSellerIds.contains(sellerId);
  }

  bool hasRecentlyViewed(String sellerId) {
    return recentlyViewedSellerIds.contains(sellerId);
  }

  Buyer addToFavorites(String sellerId) {
    if (!favoriteSellerIds.contains(sellerId)) {
      final updatedFavorites = [...favoriteSellerIds, sellerId];
      return copyWith(favoriteSellerIds: updatedFavorites);
    }
    return this;
  }

  Buyer removeFromFavorites(String sellerId) {
    final updatedFavorites = favoriteSellerIds.where((id) => id != sellerId).toList();
    return copyWith(favoriteSellerIds: updatedFavorites);
  }

  Buyer addToRecentlyViewed(String sellerId) {
    final updatedRecentlyViewed = [sellerId];
    updatedRecentlyViewed.addAll(recentlyViewedSellerIds.where((id) => id != sellerId));
    
    // Keep only last 10 recently viewed
    if (updatedRecentlyViewed.length > 10) {
      updatedRecentlyViewed.removeRange(10, updatedRecentlyViewed.length);
    }
    
    return copyWith(recentlyViewedSellerIds: updatedRecentlyViewed);
  }
}
