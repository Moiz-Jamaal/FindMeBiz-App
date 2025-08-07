import 'package:flutter/material.dart';

class Enquiry {
  final String id;
  final String buyerId;
  final String title;
  final String description;
  final List<String> categories;
  final List<String> images;
  final double? budgetMin;
  final double? budgetMax;
  final String? urgency; // 'low', 'medium', 'high', 'urgent'
  final String? preferredLocation;
  final Map<String, dynamic> additionalDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int responseCount;
  final List<String> interestedSellerIds;

  Enquiry({
    required this.id,
    required this.buyerId,
    required this.title,
    required this.description,
    required this.categories,
    this.images = const [],
    this.budgetMin,
    this.budgetMax,
    this.urgency = 'medium',
    this.preferredLocation,
    this.additionalDetails = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.responseCount = 0,
    this.interestedSellerIds = const [],
  });

  factory Enquiry.fromJson(Map<String, dynamic> json) {
    return Enquiry(
      id: json['id'] as String,
      buyerId: json['buyerId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categories: List<String>.from(json['categories'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      budgetMin: (json['budgetMin'] as num?)?.toDouble(),
      budgetMax: (json['budgetMax'] as num?)?.toDouble(),
      urgency: json['urgency'] as String? ?? 'medium',
      preferredLocation: json['preferredLocation'] as String?,
      additionalDetails: Map<String, dynamic>.from(json['additionalDetails'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      responseCount: json['responseCount'] as int? ?? 0,
      interestedSellerIds: List<String>.from(json['interestedSellerIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerId': buyerId,
      'title': title,
      'description': description,
      'categories': categories,
      'images': images,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'urgency': urgency,
      'preferredLocation': preferredLocation,
      'additionalDetails': additionalDetails,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'responseCount': responseCount,
      'interestedSellerIds': interestedSellerIds,
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory Enquiry.fromMap(Map<String, dynamic> map) => Enquiry.fromJson(map);

  Enquiry copyWith({
    String? id,
    String? buyerId,
    String? title,
    String? description,
    List<String>? categories,
    List<String>? images,
    double? budgetMin,
    double? budgetMax,
    String? urgency,
    String? preferredLocation,
    Map<String, dynamic>? additionalDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? responseCount,
    List<String>? interestedSellerIds,
  }) {
    return Enquiry(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      title: title ?? this.title,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      images: images ?? this.images,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      urgency: urgency ?? this.urgency,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      responseCount: responseCount ?? this.responseCount,
      interestedSellerIds: interestedSellerIds ?? this.interestedSellerIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Enquiry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Enquiry(id: $id, title: $title, categories: $categories, urgency: $urgency)';
  }

  // Helper methods
  String get budgetRange {
    if (budgetMin != null && budgetMax != null) {
      return '\$${budgetMin!.toStringAsFixed(0)} - \$${budgetMax!.toStringAsFixed(0)}';
    } else if (budgetMin != null) {
      return 'From \$${budgetMin!.toStringAsFixed(0)}';
    } else if (budgetMax != null) {
      return 'Up to \$${budgetMax!.toStringAsFixed(0)}';
    }
    return 'Budget not specified';
  }

  String get urgencyDisplay {
    switch (urgency) {
      case 'low':
        return 'Low Priority';
      case 'medium':
        return 'Medium Priority';
      case 'high':
        return 'High Priority';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Medium Priority';
    }
  }

  Color get urgencyColor {
    switch (urgency) {
      case 'low':
        return const Color(0xFF4CAF50); // Green
      case 'medium':
        return const Color(0xFFFF9800); // Orange
      case 'high':
        return const Color(0xFFFF5722); // Deep Orange
      case 'urgent':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFFFF9800); // Orange
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
