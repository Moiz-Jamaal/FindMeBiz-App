import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
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
  
  // Firebase Auth instance
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // Google Sign-In instance (for mobile only)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  // Getters
  UsersProfile? get currentUser => _currentUser.value;
  SellerDetails? get currentSeller => _currentSeller.value;
  bool get isLoggedIn => _currentUser.value != null;
  RxBool get isLoggedInReactive => (_currentUser.value != null).obs;
  // True if the logged-in user has an associated seller profile
  bool get isSeller => _currentSeller.value != null;
  
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
        
        
        // Handle both old format (userid) and new format (UserId)
        if (userMap.containsKey('userid') && !userMap.containsKey('UserId')) {
          // Convert old format to new format
          userMap = _convertToNewFormat(userMap);
          
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
        
        
        // Load seller data if user exists
        await _loadSellerData();
      } catch (e) {
        
        
        _clearUserData();
      }
    } else {
      
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
    _currentSeller.value = null;

    // Clear all role and seller data from role service
    if (Get.isRegistered<RoleService>()) {
      Get.find<RoleService>().clearAllRoleData();
    }

    // Erase all locally stored data
    try {
      await _box.erase();
    } catch (_) {}
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

  // Google Sign-In with Firebase Auth
  Future<ApiResponse<UsersProfile>> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        // For web, use Firebase Auth popup directly
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // For mobile, use Google Sign-In package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          // User cancelled the sign-in
          return ApiResponse.error('Google Sign-In was cancelled');
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google user credential
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }
      
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return ApiResponse.error('Firebase authentication failed');
      }

      // Send Google user data to backend
      final response = await post<UsersProfile>(
        '/GoogleAuth',
        body: {
          'googleId': firebaseUser.uid, // Use Firebase UID
          'email': firebaseUser.email!,
          'name': firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          'pictureUrl': firebaseUser.photoURL,
        },
        fromJson: (json) => UsersProfile.fromJson(json),
      );

      if (response.success && response.data != null) {
        _saveUser(response.data!);
        
        // After successful login, check and load seller data
        if (Get.isRegistered<RoleService>()) {
          await Get.find<RoleService>().checkSellerData();
          await _loadSellerData();
        }
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Google Sign-In failed: $e');
    }
  }

  // Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Continue with regular logout even if Google sign-out fails
      print('Google sign-out failed: $e');
    }
  }

  // Check if user is signed in with Google
  bool get isGoogleUser => _currentUser.value?.googleid != null && _currentUser.value!.googleid!.isNotEmpty;

  // Load seller data for current user
  Future<void> _loadSellerData() async {
    if (_currentUser.value?.userid == null) return;
    
    try {
      if (Get.isRegistered<SellerService>()) {
        final sellerService = Get.find<SellerService>();
        final response = await sellerService.getSellerByUserId(_currentUser.value!.userid!);
        
        if (response.success && response.data != null) {
          _currentSeller.value = response.data!;
          
        } else {
          _currentSeller.value = null;
          
        }
      }
    } catch (e) {
      
      _currentSeller.value = null;
    }
  }

  // Update user profile
  Future<ApiResponse<void>> updateProfile(UsersProfile user) async {
    if (user.userid == null) {
      return ApiResponse.error('User ID is required for update');
    }
    // Server requires UPassword on update; ensure we send one
    if (user.upassword == null || user.upassword!.isEmpty) {
      final existing = _currentUser.value;
      if (existing?.upassword != null && existing!.upassword!.isNotEmpty) {
        user = user.copyWith(upassword: existing.upassword);
      }
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
    // Sign out from Firebase Auth
    await _firebaseAuth.signOut();
    
    // Sign out from Google if user is signed in with Google
    if (isGoogleUser) {
      await signOutGoogle();
    }
    
    // Clear in-memory user and seller
    _clearUserData();
    _currentSeller.value = null;

    // Clear all role and seller data from role service
    if (Get.isRegistered<RoleService>()) {
      Get.find<RoleService>().clearAllRoleData();
    }

    // Wipe ALL locally persisted data (GetStorage)
    try {
      await _box.erase();
    } catch (_) {}

    // Navigate to welcome screen
    Get.offAllNamed('/welcome');
  }

  // Delete user account 
  Future<ApiResponse<void>> deleteAccount() async {
    if (_currentUser.value?.userid == null) {
      return ApiResponse.error('No user logged in');
    }
    
    // Use DELETE method and handle JSON response from backend
    try {
      final response = await apiClient.delete('/User/${_currentUser.value!.userid}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _clearUserData();
        Get.offAllNamed('/welcome');
        return ApiResponse.success(null);
      } else {
        // Try to parse error message from response
        String errorMessage = 'Failed to delete account';
        try {
          final jsonResponse = jsonDecode(response.body);
          errorMessage = jsonResponse['message'] ?? errorMessage;
        } catch (_) {
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}
