class EnquiryResponse {
  final String id;
  final String enquiryId;
  final String sellerId;
  final String message;
  final List<String> productIds; // Products that match the enquiry
  final double? quotedPrice;
  final String? availability; // 'available', 'limited', 'custom_order'
  final String? deliveryTime;
  final List<String> attachments;
  final Map<String, dynamic> additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final String status; // 'pending', 'accepted', 'declined', 'negotiating'

  EnquiryResponse({
    required this.id,
    required this.enquiryId,
    required this.sellerId,
    required this.message,
    this.productIds = const [],
    this.quotedPrice,
    this.availability = 'available',
    this.deliveryTime,
    this.attachments = const [],
    this.additionalInfo = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isRead = false,
    this.status = 'pending',
  });

  factory EnquiryResponse.fromJson(Map<String, dynamic> json) {
    return EnquiryResponse(
      id: json['id'] as String,
      enquiryId: json['enquiryId'] as String,
      sellerId: json['sellerId'] as String,
      message: json['message'] as String,
      productIds: List<String>.from(json['productIds'] ?? []),
      quotedPrice: (json['quotedPrice'] as num?)?.toDouble(),
      availability: json['availability'] as String? ?? 'available',
      deliveryTime: json['deliveryTime'] as String?,
      attachments: List<String>.from(json['attachments'] ?? []),
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enquiryId': enquiryId,
      'sellerId': sellerId,
      'message': message,
      'productIds': productIds,
      'quotedPrice': quotedPrice,
      'availability': availability,
      'deliveryTime': deliveryTime,
      'attachments': attachments,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isRead': isRead,
      'status': status,
    };
  }

  Map<String, dynamic> toMap() => toJson();
  factory EnquiryResponse.fromMap(Map<String, dynamic> map) => EnquiryResponse.fromJson(map);

  EnquiryResponse copyWith({
    String? id,
    String? enquiryId,
    String? sellerId,
    String? message,
    List<String>? productIds,
    double? quotedPrice,
    String? availability,
    String? deliveryTime,
    List<String>? attachments,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    String? status,
  }) {
    return EnquiryResponse(
      id: id ?? this.id,
      enquiryId: enquiryId ?? this.enquiryId,
      sellerId: sellerId ?? this.sellerId,
      message: message ?? this.message,
      productIds: productIds ?? this.productIds,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      availability: availability ?? this.availability,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      attachments: attachments ?? this.attachments,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnquiryResponse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EnquiryResponse(id: $id, enquiryId: $enquiryId, sellerId: $sellerId, status: $status)';
  }

  // Helper methods
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

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'negotiating':
        return 'Negotiating';
      default:
        return 'Unknown';
    }
  }
}
