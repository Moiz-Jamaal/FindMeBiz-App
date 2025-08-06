enum UserRole {
  seller,
  buyer,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.seller:
        return 'Seller';
      case UserRole.buyer:
        return 'Buyer';
    }
  }
  
  String get description {
    switch (this) {
      case UserRole.seller:
        return 'Showcase my products and connect with buyers';
      case UserRole.buyer:
        return 'Discover amazing products and connect with sellers';
    }
  }
  
  String get value {
    switch (this) {
      case UserRole.seller:
        return 'seller';
      case UserRole.buyer:
        return 'buyer';
    }
  }
  
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'seller':
        return UserRole.seller;
      case 'buyer':
        return UserRole.buyer;
      default:
        throw ArgumentError('Invalid user role: $value');
    }
  }
}
