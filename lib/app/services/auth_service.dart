import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
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
  // Google Sign-In instance (mobile only). Lazily created to avoid web plugin init.
  GoogleSignIn? _googleSignIn;
  // Apple Sign-In: no persistent instance needed
  
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
    // No artificial delay needed
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

  // Check if seller profile name is available; optionally exclude current seller by sellerId
  Future<ApiResponse<bool>> isProfileNameAvailable(String profileName, {int? sellerId}) async {
    final qp = {'profileName': profileName};
    if (sellerId != null) {
      qp['sellerId'] = sellerId.toString();
    }
    final response = await get<Map<String, dynamic>>(
      '/ProfileAvailable',
      queryParams: qp,
    );

    if (response.success && response.data != null) {
      final available = response.data!['available'] as bool? ?? false;
      return ApiResponse.success(available);
    }

    return ApiResponse.error(response.message ?? 'Failed to check profile name availability');
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
  _googleSignIn ??= GoogleSignIn(scopes: ['email', 'profile']);
  final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        
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
  await _googleSignIn?.signOut();
    } catch (e) {
      // Continue with regular logout even if Google sign-out fails
}
  }

  // Check if user is signed in with Google
  bool get isGoogleUser => _currentUser.value?.googleid != null && _currentUser.value!.googleid!.isNotEmpty;

  // Check if user is signed in with Apple
  bool get isAppleUser => _currentUser.value?.appleid != null && _currentUser.value!.appleid!.isNotEmpty;

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

  // Apple Sign-In with Firebase Auth (iOS/macOS)
  Future<ApiResponse<UsersProfile>> signInWithApple() async {
    try {
      // Web: use Firebase popup provider if enabled in Firebase Console
      if (kIsWeb) {
        final appleProvider = OAuthProvider('apple.com');
        // Request basic scopes
        appleProvider.addScope('email');
        appleProvider.addScope('name');

        final userCredential = await _firebaseAuth.signInWithPopup(appleProvider);
        final firebaseUser = userCredential.user;
        if (firebaseUser == null) {
          return ApiResponse.error('Firebase authentication failed');
        }

        final response = await post<UsersProfile>(
          '/AppleAuth',
          body: {
            'appleId': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'name': (firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User'),
            'pictureUrl': firebaseUser.photoURL,
          },
          fromJson: (json) => UsersProfile.fromJson(json),
        );

        if (response.success && response.data != null) {
          _saveUser(response.data!);
          if (Get.isRegistered<RoleService>()) {
            await Get.find<RoleService>().checkSellerData();
            await _loadSellerData();
          }
        }

        return response;
      }

      // Native Apple flow is supported only on iOS/macOS
      if (!(defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
        return ApiResponse.error(
          'Apple Sign-In is only supported on iOS/macOS in this app. '
          'On Android, configure the Apple Web flow with a Services ID and use a backend exchange.',
        );
      }

      // Create a cryptographically secure random nonce, to include in the ID token.
      String _generateNonce([int length = 32]) {
        const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
        final random = Random.secure();
        return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
      }

      String _sha256ofString(String input) {
        final bytes = utf8.encode(input);
        final digest = sha256.convert(bytes);
        return digest.toString();
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // If Apple didn't return an ID token, Firebase cannot verify the credential
      if (appleCredential.identityToken == null || appleCredential.identityToken!.isEmpty) {
        return ApiResponse.error(
          'Apple did not return a valid identity token. Ensure "Sign in with Apple" is enabled for your app ID, '
          'the capability is added in Xcode, and try again with a real device/account.',
        );
      }

  // Debug-only: decode JWT payload to validate nonce and audience
      if (kDebugMode) {
        Map<String, dynamic>? _decodeJwtPayload(String token) {
          try {
            final parts = token.split('.');
            if (parts.length != 3) return null;
            String _normalize(String input) {
              var out = input.replaceAll('-', '+').replaceAll('_', '/');
              switch (out.length % 4) {
                case 2:
                  out += '==';
                  break;
                case 3:
                  out += '=';
                  break;
              }
              return out;
            }
            final payload = utf8.decode(base64.decode(_normalize(parts[1])));
            return jsonDecode(payload) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        }

        final claims = _decodeJwtPayload(appleCredential.identityToken!);
        if (claims != null) {
          // Compare token.nonce (SHA256 of rawNonce) with our computed hash
          final expectedNonce = _sha256ofString(rawNonce);
          debugPrint('[Apple Sign-In] JWT aud=${claims['aud']}, email=${claims['email']}, ' 
              'nonce=${claims['nonce']}, iss=${claims['iss']}');
// If nonce doesn't match, surface a clear, actionable error
          if (claims.containsKey('nonce') && claims['nonce'] != expectedNonce) {
            return ApiResponse.error(
              'Nonce mismatch in Apple token. Ensure you pass SHA256(rawNonce) to getAppleIDCredential(nonce: ...) '
              'and pass the rawNonce to Firebase (credential.rawNonce).',
            );
          }
        } else {
}
      }

      final oauth = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauth);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return ApiResponse.error('Firebase authentication failed');
      }

      final displayName = firebaseUser.displayName ??
          [appleCredential.givenName, appleCredential.familyName]
              .where((e) => e != null && e.isNotEmpty)
              .join(' ');

      // Send Apple user data to backend
      final response = await post<UsersProfile>(
        '/AppleAuth',
        body: {
          'appleId': firebaseUser.uid, // Firebase UID
          'email': firebaseUser.email ?? appleCredential.email ?? '',
          'name': displayName.isNotEmpty ? displayName : (firebaseUser.email?.split('@').first ?? 'User'),
          'pictureUrl': firebaseUser.photoURL,
        },
        fromJson: (json) => UsersProfile.fromJson(json),
      );

      if (response.success && response.data != null) {
        _saveUser(response.data!);
        if (Get.isRegistered<RoleService>()) {
          await Get.find<RoleService>().checkSellerData();
          await _loadSellerData();
        }
      }

      return response;
    } catch (e) {
      // Provide a more actionable message for invalid credential errors
      if (e is FirebaseAuthException && e.code == 'invalid-credential') {
        return ApiResponse.error(
          'Apple credential was rejected. Check that the nonce hashing is correct, '
          'the Apple capability is enabled for this bundle ID, and Firebase Apple provider is configured.',
        );
      }
      if (e is PlatformException && e.code == 'invalid-credential') {
        return ApiResponse.error(
          'Invalid OAuth response from Apple. Verify that Sign in with Apple is enabled in Apple Developer, '
          'the app capability is added in Xcode, and test on a real device signed into iCloud.',
        );
      }
      return ApiResponse.error('Apple Sign-In failed: $e');
    }
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
