import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/role_service.dart';
import '../../../data/models/api/users_profile.dart';
import '../../../data/models/user_role.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final RoleService _roleService = Get.find<RoleService>();
  
  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final mobileController = TextEditingController();
  final whatsappController = TextEditingController();
  
  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();
  
  // Observable states
  final isLoading = false.obs;
  final isLoginMode = true.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final emailAvailable = true.obs;
  final usernameAvailable = true.obs;
  final showEmailIcon = false.obs;
  final showUsernameIcon = false.obs;
  
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    usernameController.dispose();
    mobileController.dispose();
    whatsappController.dispose();
    super.onClose();
  }
  
  // Toggle between login and register modes
  void toggleMode() {
    isLoginMode.value = !isLoginMode.value;
    clearForm();
  }
  
  // Clear form fields
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    fullNameController.clear();
    usernameController.clear();
    mobileController.clear();
    whatsappController.clear();
    showEmailIcon.value = false;
    showUsernameIcon.value = false;
  }
  
  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }
  
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }
  
  // Check email availability
  Future<void> checkEmailAvailability(String email) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      showEmailIcon.value = false;
      return;
    }
    
    showEmailIcon.value = true;
    
   
      final response = await _authService.isEmailAvailable(email);
      if (response.success) {
        emailAvailable.value = response.data ?? false;
      }
  
  }
  
  // Check username availability
  Future<void> checkUsernameAvailability(String username) async {
    if (username.isEmpty || username.length < 3) {
      showUsernameIcon.value = false;
      return;
    }
    
    showUsernameIcon.value = true;
    

      final response = await _authService.isUsernameAvailable(username);
      if (response.success) {
        usernameAvailable.value = response.data ?? false;
      }
    
  }
  
  // Login user
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;
    
    isLoading.value = true;
    
    try {
      final response = await _authService.login(
        emailController.text.trim(),
        passwordController.text,
      );
      
      if (response.success && response.data != null) {
        Get.snackbar(
          'Success',
          'Welcome back!',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
        
        // Navigate based on role
        _navigateAfterAuth();
      } else {
        Get.snackbar(
          'Login Failed',
          response.message ?? 'Invalid credentials',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to login. Please try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Register new user
  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;
    
    if (!emailAvailable.value) {
      Get.snackbar(
        'Error',
        'Email is already taken',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }
    
    if (!usernameAvailable.value) {
      Get.snackbar(
        'Error',
        'Username is already taken',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }
    
    isLoading.value = true;
    
    try {
      final user = UsersProfile(
        username: usernameController.text.trim(),
        fullname: fullNameController.text.trim(),
        emailid: emailController.text.trim(),
        upassword: passwordController.text,
        mobileno: mobileController.text.trim().isNotEmpty ? mobileController.text.trim() : null,
        whatsappno: whatsappController.text.trim().isNotEmpty ? whatsappController.text.trim() : null,
      );
      
      final response = await _authService.register(user);
      
      if (response.success && response.data != null) {
        Get.snackbar(
          'Success',
          'Account created successfully!',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
        
        // Navigate based on role
        _navigateAfterAuth();
      } else {
        Get.snackbar(
          'Registration Failed',
          response.message ?? 'Failed to create account',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to register. Please try again.',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Navigate after successful authentication
  void _navigateAfterAuth() async {
    final currentRole = _roleService.currentRole.value;
    
    // Persist the role selection after successful authentication
    await _roleService.persistCurrentRole();
    
    // Navigate based on role and check seller data for sellers
    if (currentRole == UserRole.seller) {
      await _roleService.checkSellerData();
      final route = _roleService.getSellerRoute();
      Get.offAllNamed(route);
    } else {
      Get.offAllNamed('/buyer-home');
    }
  }
  
  // Form validators
  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  
  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  String? confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
  
  String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
  
  String? usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.contains(' ')) {
      return 'Username cannot contain spaces';
    }
    return null;
  }
  
  String? phoneValidator(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!GetUtils.isPhoneNumber(value)) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }
}
