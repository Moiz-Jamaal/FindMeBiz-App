import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';
import 'role_service.dart';
import 'seller_service.dart';
import '../data/models/api/index.dart';

class AuthService extends BaseApiService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  
  final _box = GetStorage();
  final Rx<UsersProfile?> _currentUser = Rx<UsersProfile?>(null);
  final Rx<SellerDetails?> _currentSeller = Rx<SellerDetails?>(null);
  
  // Getters
  UsersProfile? get currentUser => _currentUser.value;
  SellerDetails? get currentSeller => _currentSeller.value;
  bool get isLoggedIn => _currentUser.value != null;
  RxBool get isLoggedInReactive => (_currentUser.value != null).obs;
  
  @override
  void onInit() {
    super.onInit();
    // Load saved user asynchronously
    Future(() async => await _loadSavedUser());
  }

  // Initialize service and load saved user data
  Future<AuthService> init() async {
    await _loadSavedUser();
    // Give it a moment to load
    await Future.delayed(const Duration(milliseconds: 100));
    return this;
  }

  // Load saved user from storage
  Future<void> _loadSavedUser() async {
    final userData = _box.read(_userKey);
    print('🔍 Checking saved user data: ${userData != null ? 'Found' : 'Not found'}');
    
    if (userData != null) {
      try {
        // Ensure userData is a Map<String, dynamic>
        Map<String, dynamic> userMap;
        if (userData is Map<String, dynamic>) {
          userMap = userData;
        } else if (userData is Map) {
          userMap = Map<String, dynamic>.from(userData);
        } else {
          throw Exception('Invalid user data format: ${userData.runtimeType}');
        }
        
        // Debug: Print the actual data structure
        print('📊 User data structure: ${userMap.keys.toList()}');
        
        // Handle both old format (userid) and new format (UserId)
        if (userMap.containsKey('userid') && !userMap.containsKey('UserId')) {
          // Convert old format to new format
          userMap = _convertToNewFormat(userMap);
          print('🔄 Converted old data format to new format');
        }
        
        // Validate required fields before creating UsersProfile
        if (userMap['UserId'] == null) {
          throw Exception('Missing UserId field');
        }
        if (userMap['Username'] == null) {
          throw Exception('Missing Username field');
        }
        if (userMap['EmailId'] == null) {
          throw Exception('Missing EmailId field');
        }
        
        _currentUser.value = UsersProfile.fromJson(userMap);
        print('✅ Loaded saved user: ${_currentUser.value?.username}');
        
        // Load seller data if user exists
        await _loadSellerData();
      } catch (e) {
        print('❌ Error loading saved user: $e');
        print('🧹 Clearing corrupted user data');
        _clearUserData();
      }
    } else {
      print('ℹ️ No saved user found');
    }
  }

  // Convert old field names to new field names
  Map<String, dynamic> _convertToNewFormat(Map<String, dynamic> oldData) {
    return {
      'UserId': oldData['userid'],
      'Username': oldData['username'],
      'FullName': oldData['fullname'],
      'EmailId': oldData['emailid'],
      'UPassword': oldData['upassword'],
      'Dob': oldData['dob'],
      'Sex': oldData['sex'],
      'MobileNo': oldData['mobileno'],
      'WhatsappNo': oldData['whatsappno'],
      'Active': oldData['active'],
      'CreatedDt': oldData['createddt'],
      'UpdatedDt': oldData['updateddt'],
    };
  }

  // Save user to storage
  void _saveUser(UsersProfile user) {
    _currentUser.value = user;
    // Always save in the new format with proper field names
    final userData = user.toJson();
    _box.write(_userKey, userData);
    print('💾 User saved to storage: ${user.username}');
  }

  // Clear user data
  void _clearUserData() {
    _currentUser.value = null;
    _box.remove(_userKey);
    _box.remove(_tokenKey);
  }

  // Clear all app data (for debugging or reset)
  Future<void> clearAllData() async {
    _clearUserData();
    
    // Clear all role and seller data from role service
    if (Get.isRegistered<RoleService>()) {
      Get.find<RoleService>().clearAllRoleData();
    }
    
    print('🧹 All app data cleared');
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
      
      // After successful login, check and load seller data
      if (Get.isRegistered<RoleService>()) {
        await Get.find<RoleService>().checkSellerData();
        await _loadSellerData(); // Load seller data into AuthService
      }
    }
    
    return response;
  }

  // Load seller data for current user
  Future<void> _loadSellerData() async {
    if (_currentUser.value?.userid == null) return;
    
    try {
      if (Get.isRegistered<SellerService>()) {
        final sellerService = Get.find<SellerService>();
        final response = await sellerService.getSellerByUserId(_currentUser.value!.userid!);
        
        if (response.success && response.data != null) {
          _currentSeller.value = response.data!;
          print('✅ Seller data loaded: ${response.data!.sellerId}');
        } else {
          _currentSeller.value = null;
          print('ℹ️ No seller data for user ${_currentUser.value!.username}');
        }
      }
    } catch (e) {
      print('❌ Error loading seller data: $e');
      _currentSeller.value = null;
    }
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
    
    // Clear all role and seller data from role service
    if (Get.isRegistered<RoleService>()) {
      Get.find<RoleService>().clearAllRoleData();
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
