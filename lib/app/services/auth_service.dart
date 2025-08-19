import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';
import 'role_service.dart';
import '../data/models/api/index.dart';

class AuthService extends BaseApiService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  
  final _box = GetStorage();
  final Rx<UsersProfile?> _currentUser = Rx<UsersProfile?>(null);
  
  // Getters
  UsersProfile? get currentUser => _currentUser.value;
  bool get isLoggedIn => _currentUser.value != null;
  RxBool get isLoggedInReactive => (_currentUser.value != null).obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadSavedUser();
  }

  // Load saved user from storage
  void _loadSavedUser() {
    final userData = _box.read(_userKey);
    if (userData != null) {
      try {
        _currentUser.value = UsersProfile.fromJson(Map<String, dynamic>.from(userData));
        print('✅ Loaded saved user: ${_currentUser.value?.username}');
      } catch (e) {
        print('❌ Error loading saved user: $e');
        _clearUserData();
      }
    } else {
      print('ℹ️ No saved user found');
    }
  }

  // Save user to storage
  void _saveUser(UsersProfile user) {
    _currentUser.value = user;
    _box.write(_userKey, user.toJson());
  }

  // Clear user data
  void _clearUserData() {
    _currentUser.value = null;
    _box.remove(_userKey);
    _box.remove(_tokenKey);
  }

  // Check if email is available
  Future<ApiResponse<bool>> isEmailAvailable(String email) async {
    final response = await get<Map<String, dynamic>>(
      '/EmailAvailable',
      queryParams: {'email': email},
    );
    
    if (response.success && response.data != null) {
      final available = response.data!['available'] as bool? ?? false;
      return ApiResponse.success(available);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to check email availability');
  }

  // Check if username is available
  Future<ApiResponse<bool>> isUsernameAvailable(String username) async {
    final response = await get<Map<String, dynamic>>(
      '/UsernameAvailable',
      queryParams: {'username': username},
    );
    
    if (response.success && response.data != null) {
      final available = response.data!['available'] as bool? ?? false;
      return ApiResponse.success(available);
    }
    
    return ApiResponse.error(response.message ?? 'Failed to check username availability');
  }

  // Register new user
  Future<ApiResponse<UsersProfile>> register(UsersProfile user) async {
    final response = await post<UsersProfile>(
      '/User',
      body: user.toJson(),
      fromJson: (json) => UsersProfile.fromJson(json),
    );
    
    if (response.success && response.data != null) {
      _saveUser(response.data!);
    }
    
    return response;
  }

  // Login user
  Future<ApiResponse<UsersProfile>> login(String username, String password) async {
    final response = await get<UsersProfile>(
      '/UserAuth',
      queryParams: {
        'username': username,
        'password': password,
      },
      fromJson: (json) => UsersProfile.fromJson(json),
    );
    
    if (response.success && response.data != null) {
      _saveUser(response.data!);
      
      // After successful login, check seller data
      if (Get.isRegistered<RoleService>()) {
        await Get.find<RoleService>().checkSellerData();
      }
    }
    
    return response;
  }

  // Update user profile
  Future<ApiResponse<void>> updateProfile(UsersProfile user) async {
    if (user.userid == null) {
      return ApiResponse.error('User ID is required for update');
    }
    
    final response = await put<void>(
      '/User/${user.userid}',
      body: user.toJson(),
    );
    
    if (response.success) {
      _saveUser(user);
    }
    
    return response;
  }

  // Get user by ID
  Future<ApiResponse<UsersProfile>> getUserById(int userId) async {
    final response = await get<UsersProfile>(
      '/User/$userId',
      fromJson: (json) => UsersProfile.fromJson(json),
    );
    
    return response;
  }

  // Logout
  Future<void> logout() async {
    _clearUserData();
    
    // Clear seller data from role service
    if (Get.isRegistered<RoleService>()) {
      Get.find<RoleService>().clearSellerData();
    }
    
    // Navigate to welcome screen
    Get.offAllNamed('/welcome');
  }

  // Delete user account (soft delete)
  Future<ApiResponse<void>> deleteAccount() async {
    if (_currentUser.value?.userid == null) {
      return ApiResponse.error('No user logged in');
    }
    
    final response = await delete('/User/${_currentUser.value!.userid}');
    
    if (response.success) {
      _clearUserData();
      Get.offAllNamed('/welcome');
    }
    
    return response;
  }
}
