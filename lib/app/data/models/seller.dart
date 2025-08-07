import 'user.dart';
import 'user_role.dart';

class Seller extends User {
  final String businessName;
  final String? bio;
  final String? businessLogo;
  final List<String> categories;
  final List<String> socialMediaLinks;
  final String? whatsappNumber;
  final StallLocation? stallLocation;
  final bool isProfilePublished;
  final DateTime? publishedAt;
  final double profileCompletionScore;

  Seller({
    required String id,
    required String email,
    required String fullName,
    String? profileImage,
    String? phoneNumber,
    required DateTime createdAt,
    required DateTime updatedAt,
    bool isActive = true,
    required this.businessName,
    this.bio,
    this.businessLogo,
    this.categories = const [],
    this.socialMediaLinks = const [],
    this.whatsappNumber,
    this.stallLocation,
    this.isProfilePublished = false,
    this.publishedAt,
    this.profileCompletionScore = 0.0,
  }) : super(
          id: id,
          email: email,
          fullName: fullName,
          role: UserRole.seller,
          profileImage: profileImage,
          phoneNumber: phoneNumber,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isActive: isActive,
        );

  factory Seller.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    
    return Seller(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      profileImage: user.profileImage,
      phoneNumber: user.phoneNumber,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isActive: user.isActive,
      businessName: json['businessName'] as String,
      bio: json['bio'] as String?,
      businessLogo: json['businessLogo'] as String?,
      categories: List<String>.from(json['categories'] ?? []),
      socialMediaLinks: List<String>.from(json['socialMediaLinks'] ?? []),
      whatsappNumber: json['whatsappNumber'] as String?,
      stallLocation: json['stallLocation'] != null 
          ? StallLocation.fromJson(json['stallLocation'])
          : null,
      isProfilePublished: json['isProfilePublished'] as bool? ?? false,
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      profileCompletionScore: (json['profileCompletionScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'businessName': businessName,
      'bio': bio,
      'businessLogo': businessLogo,
      'categories': categories,
      'socialMediaLinks': socialMediaLinks,
      'whatsappNumber': whatsappNumber,
      'stallLocation': stallLocation?.toJson(),
      'isProfilePublished': isProfilePublished,
      'publishedAt': publishedAt?.toIso8601String(),
      'profileCompletionScore': profileCompletionScore,
    });
    return json;
  }

  @override
  Seller copyWith({
    String? id,
    String? email,
    String? fullName,
    String? profileImage,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    UserRole? role,
    String? businessName,
    String? bio,
    String? businessLogo,
    List<String>? categories,
    List<String>? socialMediaLinks,
    String? whatsappNumber,
    StallLocation? stallLocation,
    bool? isProfilePublished,
    DateTime? publishedAt,
    double? profileCompletionScore,
  }) {
    return Seller(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      businessName: businessName ?? this.businessName,
      bio: bio ?? this.bio,
      businessLogo: businessLogo ?? this.businessLogo,
      categories: categories ?? this.categories,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      stallLocation: stallLocation ?? this.stallLocation,
      isProfilePublished: isProfilePublished ?? this.isProfilePublished,
      publishedAt: publishedAt ?? this.publishedAt,
      profileCompletionScore: profileCompletionScore ?? this.profileCompletionScore,
    );
  }
}

class StallLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? stallNumber;
  final String? area;

  StallLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.stallNumber,
    this.area,
  });

  factory StallLocation.fromJson(Map<String, dynamic> json) {
    return StallLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      stallNumber: json['stallNumber'] as String?,
      area: json['area'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'stallNumber': stallNumber,
      'area': area,
    };
  }

  StallLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? stallNumber,
    String? area,
  }) {
    return StallLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      stallNumber: stallNumber ?? this.stallNumber,
      area: area ?? this.area,
    );
  }
}
