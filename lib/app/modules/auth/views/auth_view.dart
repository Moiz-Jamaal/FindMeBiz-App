import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_constants.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 20),
              Obx(() => Text(
                controller.isLoginMode.value ? 'Welcome Back!' : 'Create Account',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              )),
              const SizedBox(height: 8),
              Obx(() => Text(
                controller.isLoginMode.value 
                    ? 'Sign in to continue' 
                    : 'Join FindMeBiz today',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              )),
              
              const SizedBox(height: 32),
              
              // Form
              Obx(() => controller.isLoginMode.value 
                  ? _buildLoginForm() 
                  : _buildRegisterForm()),
              
              const SizedBox(height: 24),
              
              // Submit Button
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value 
                      ? null 
                      : () {
                          if (controller.isLoginMode.value) {
                            controller.login();
                          } else {
                            controller.register();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5A4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                    ),
                  ),
                  child: controller.isLoading.value 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          controller.isLoginMode.value ? 'Sign In' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              )),
              
              const SizedBox(height: 24),
              
              // Toggle Mode
              Center(
                child: Obx(() => TextButton(
                  onPressed: controller.toggleMode,
                  child: RichText(
                    text: TextSpan(
                      text: controller.isLoginMode.value 
                          ? "Don't have an account? " 
                          : "Already have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                      children: [
                        TextSpan(
                          text: controller.isLoginMode.value ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(
                            color: Color(0xFF0EA5A4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        children: [
          // Email field
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email or Username',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: controller.emailValidator,
          ),
          
          const SizedBox(height: 16),
          
          // Password field
          Obx(() => TextFormField(
            controller: controller.passwordController,
            obscureText: controller.obscurePassword.value,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword.value 
                      ? Icons.visibility_off 
                      : Icons.visibility,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: controller.passwordValidator,
          )),
          
          const SizedBox(height: 8),
          
          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
                Get.snackbar(
                  'Coming Soon',
                  'Forgot password feature will be available soon',
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  colorText: Colors.blue,
                );
              },
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: Color(0xFF0EA5A4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: controller.registerFormKey,
      child: Column(
        children: [
          // Full Name field
          TextFormField(
            controller: controller.fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: controller.nameValidator,
          ),
          
          const SizedBox(height: 16),
          
          // Username field
          TextFormField(
            controller: controller.usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.alternate_email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              suffixIcon: Obx(() => controller.showUsernameIcon.value
                  ? Icon(
                      controller.usernameAvailable.value 
                          ? Icons.check_circle 
                          : Icons.cancel,
                      color: controller.usernameAvailable.value 
                          ? Colors.green 
                          : Colors.red,
                    )
                  : const SizedBox.shrink()),
            ),
            validator: controller.usernameValidator,
            onChanged: (value) {
              if (value.length > 2) {
                controller.checkUsernameAvailability(value);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email field
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              suffixIcon: Obx(() => controller.showEmailIcon.value
                  ? Icon(
                      controller.emailAvailable.value 
                          ? Icons.check_circle 
                          : Icons.cancel,
                      color: controller.emailAvailable.value 
                          ? Colors.green 
                          : Colors.red,
                    )
                  : const SizedBox.shrink()),
            ),
            validator: controller.emailValidator,
            onChanged: (value) {
              if (value.isEmail) {
                controller.checkEmailAvailability(value);
              }
            },
          ),
          
          const SizedBox(height: 16),
          // Password field
          Obx(() => TextFormField(
            controller: controller.passwordController,
            obscureText: controller.obscurePassword.value,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword.value 
                      ? Icons.visibility_off 
                      : Icons.visibility,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: controller.passwordValidator,
          )),
          
          const SizedBox(height: 16),
          
          // Confirm Password field
          Obx(() => TextFormField(
            controller: controller.confirmPasswordController,
            obscureText: controller.obscureConfirmPassword.value,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscureConfirmPassword.value 
                      ? Icons.visibility_off 
                      : Icons.visibility,
                ),
                onPressed: controller.toggleConfirmPasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: controller.confirmPasswordValidator,
          )),
          
          const SizedBox(height: 16),
          
          // Mobile Number field (optional)
          TextFormField(
            controller: controller.mobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number (Optional)',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: controller.phoneValidator,
          ),
          
          const SizedBox(height: 16),
          
          // WhatsApp Number field (optional)
          TextFormField(
            controller: controller.whatsappController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'WhatsApp Number (Optional)',
              prefixIcon: const Icon(Icons.chat_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: controller.phoneValidator,
          ),
        ],
      ),
    );
  }
}
