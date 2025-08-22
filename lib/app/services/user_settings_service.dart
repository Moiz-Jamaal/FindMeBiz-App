import 'package:get/get.dart';
import '../data/models/api/index.dart';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';
import 'auth_service.dart';

class UserSettingsService extends BaseApiService {
  final AuthService _authService = Get.find<AuthService>();

  // Get user settings
  Future<ApiResponse<UserSettings>> getUserSettings() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await get<UserSettings>(
        '/UserSettings/$userId',
        fromJson: (json) => UserSettings.fromJson(json),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get user settings: ${e.toString()}');
    }
  }

  // Create or update user settings
  Future<ApiResponse<UserSettings>> saveUserSettings(UserSettings settings) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      // Ensure user ID is set
      final settingsWithUserId = settings.copyWith(userid: userId);
      
      final response = await put<UserSettings>(
        '/UserSettings/$userId',
        body: settingsWithUserId.toJson(),
        fromJson: (json) => UserSettings.fromJson(json),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to save user settings: ${e.toString()}');
    }
  }

  // Update interest categories
  Future<ApiResponse<void>> updateInterestCategories(List<int> categoryIds) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await put<void>(
        '/UserInterestCategories/$userId',
        body: {
          'categoryIds': categoryIds,
        },
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to update interest categories: ${e.toString()}');
    }
  }

  // Update notification preferences
  Future<ApiResponse<void>> updateNotificationSettings(NotificationSettings notifications) async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await put<void>(
        '/UserNotifications/$userId',
        body: notifications.toJson(),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to update notification settings: ${e.toString()}');
    }
  }

  // Get user's interest categories with details
  Future<ApiResponse<List<CategoryMaster>>> getUserInterestCategories() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final response = await getList<CategoryMaster>(
        '/UserInterestCategories/$userId',
        fromJson: (json) => CategoryMaster.fromJson(json),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get interest categories: ${e.toString()}');
    }
  }

  // Reset settings to default
  Future<ApiResponse<UserSettings>> resetToDefaults() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      final defaultSettings = UserSettings.defaultSettings(userId);
      return await saveUserSettings(defaultSettings);
    } catch (e) {
      return ApiResponse.error('Failed to reset settings: ${e.toString()}');
    }
  }

  // Initialize settings for new user
  Future<ApiResponse<UserSettings>> initializeUserSettings() async {
    final userId = _authService.currentUser?.userid;
    if (userId == null) {
      return ApiResponse.error('User not logged in');
    }

    try {
      // Check if settings already exist
      final existingResponse = await getUserSettings();
      if (existingResponse.isSuccess) {
        return existingResponse; // Settings already exist
      }

      // Create default settings
      final defaultSettings = UserSettings.defaultSettings(userId);
      final response = await post<UserSettings>(
        '/UserSettings',
        body: defaultSettings.toJson(),
        fromJson: (json) => UserSettings.fromJson(json),
      );
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to initialize user settings: ${e.toString()}');
    }
  }
}

// User Settings Model
class UserSettings {
  final int userid;
  final List<int> interestCategories;
  final NotificationSettings notifications;

  UserSettings({
    required this.userid,
    required this.interestCategories,
    required this.notifications,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    // Parse interest categories from JSON string or list
    List<int> categories = [];
    final interestCat = json['interest_cat'] ?? json['interestCategories'];
    if (interestCat is String) {
      try {
        // Parse JSON string to list
        final decoded = json['interest_cat'] != null ? 
            json['interest_cat'].split(',').map((e) => int.tryParse(e.trim())).where((e) => e != null).cast<int>().toList() :
            [];
        categories = decoded;
      } catch (e) {
        categories = [];
      }
    } else if (interestCat is List) {
      categories = interestCat.cast<int>();
    }

    // Parse notifications from JSON string or map
    NotificationSettings notifications;
    final notificationsData = json['notifications'];
    if (notificationsData is String) {
      try {
        // Parse JSON string to map
        final Map<String, dynamic> notifMap = {};
        // Simple parsing for comma-separated key:value pairs
        notifications = NotificationSettings.fromJson(notifMap);
      } catch (e) {
        notifications = NotificationSettings.defaultSettings();
      }
    } else if (notificationsData is Map) {
      notifications = NotificationSettings.fromJson(Map<String, dynamic>.from(notificationsData));
    } else {
      notifications = NotificationSettings.defaultSettings();
    }

    return UserSettings(
      userid: json['userid'],
      interestCategories: categories,
      notifications: notifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'interest_cat': interestCategories.join(','), // Store as comma-separated string
      'notifications': notifications.toJsonString(), // Store as JSON string
    };
  }

  UserSettings copyWith({
    int? userid,
    List<int>? interestCategories,
    NotificationSettings? notifications,
  }) {
    return UserSettings(
      userid: userid ?? this.userid,
      interestCategories: interestCategories ?? this.interestCategories,
      notifications: notifications ?? this.notifications,
    );
  }

  // Create default settings for a user
  static UserSettings defaultSettings(int userId) {
    return UserSettings(
      userid: userId,
      interestCategories: [], // No categories selected by default
      notifications: NotificationSettings.defaultSettings(),
    );
  }
}

// Notification Settings Model
class NotificationSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool newProductNotifications;
  final bool priceDropNotifications;
  final bool favoriteSellerNotifications;
  final bool orderStatusNotifications;
  final bool marketingNotifications;

  NotificationSettings({
    required this.pushNotifications,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.newProductNotifications,
    required this.priceDropNotifications,
    required this.favoriteSellerNotifications,
    required this.orderStatusNotifications,
    required this.marketingNotifications,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      newProductNotifications: json['newProductNotifications'] ?? true,
      priceDropNotifications: json['priceDropNotifications'] ?? true,
      favoriteSellerNotifications: json['favoriteSellerNotifications'] ?? true,
      orderStatusNotifications: json['orderStatusNotifications'] ?? true,
      marketingNotifications: json['marketingNotifications'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'newProductNotifications': newProductNotifications,
      'priceDropNotifications': priceDropNotifications,
      'favoriteSellerNotifications': favoriteSellerNotifications,
      'orderStatusNotifications': orderStatusNotifications,
      'marketingNotifications': marketingNotifications,
    };
  }

  String toJsonString() {
    // Convert to JSON string for database storage
    return toJson().toString().replaceAll('{', '').replaceAll('}', '').replaceAll(':', '=');
  }

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? newProductNotifications,
    bool? priceDropNotifications,
    bool? favoriteSellerNotifications,
    bool? orderStatusNotifications,
    bool? marketingNotifications,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      newProductNotifications: newProductNotifications ?? this.newProductNotifications,
      priceDropNotifications: priceDropNotifications ?? this.priceDropNotifications,
      favoriteSellerNotifications: favoriteSellerNotifications ?? this.favoriteSellerNotifications,
      orderStatusNotifications: orderStatusNotifications ?? this.orderStatusNotifications,
      marketingNotifications: marketingNotifications ?? this.marketingNotifications,
    );
  }

  // Create default notification settings
  static NotificationSettings defaultSettings() {
    return NotificationSettings(
      pushNotifications: true,
      emailNotifications: true,
      smsNotifications: false,
      newProductNotifications: true,
      priceDropNotifications: true,
      favoriteSellerNotifications: true,
      orderStatusNotifications: true,
      marketingNotifications: false,
    );
  }
}
