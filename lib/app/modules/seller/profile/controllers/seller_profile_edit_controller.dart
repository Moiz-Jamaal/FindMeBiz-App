import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/seller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class SellerProfileEditController extends GetxController {
  // Form controllers
  final businessNameController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final whatsappController = TextEditingController();
  
  // Social media links
  final instagramController = TextEditingController();
  final facebookController = TextEditingController();
  final websiteController = TextEditingController();
  
  // Profile images
  final RxString profileImage = ''.obs;
  final RxString businessLogo = ''.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool hasChanges = false.obs;
  
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _loadCurrentProfile();
    _setupListeners();
  }

  @override
  void onClose() {
    _disposeControllers();
    super.onClose();
  }

  void _loadCurrentProfile() {
    // Load current seller profile
    // In a real app, this would come from a service/repository
    _populateFields();
  }

  void _populateFields() {
    // Mock data for testing
    businessNameController.text = 'Surat Silk Emporium';
    fullNameController.text = 'Rajesh Patel';
    emailController.text = 'rajesh@suratsik.com';
    phoneController.text = '+91 98765 43210';
    bioController.text = 'Premium silk sarees and traditional wear from Surat. Family business since 1985.';
    whatsappController.text = '+91 98765 43210';
    instagramController.text = '@suratsik_emporium';
  }

  void _setupListeners() {
    // Add listeners to detect changes
    businessNameController.addListener(_onFieldChanged);
    fullNameController.addListener(_onFieldChanged);
    emailController.addListener(_onFieldChanged);
    phoneController.addListener(_onFieldChanged);
    bioController.addListener(_onFieldChanged);
    whatsappController.addListener(_onFieldChanged);
    instagramController.addListener(_onFieldChanged);
    facebookController.addListener(_onFieldChanged);
    websiteController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    hasChanges.value = true;
  }

  void _disposeControllers() {
    businessNameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    whatsappController.dispose();
    instagramController.dispose();
    facebookController.dispose();
    websiteController.dispose();
  }

  void updateProfileImage(String imagePath) {
    profileImage.value = imagePath;
    hasChanges.value = true;
  }

  void updateBusinessLogo(String imagePath) {
    businessLogo.value = imagePath;
    hasChanges.value = true;
  }

  void removeProfileImage() {
    profileImage.value = '';
    hasChanges.value = true;
  }

  void removeBusinessLogo() {
    businessLogo.value = '';
    hasChanges.value = true;
  }

  void saveProfile() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    // Create updated seller object
    final updatedSeller = _createUpdatedSeller();

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      hasChanges.value = false;

      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    });
  }

  Seller _createUpdatedSeller() {
    return Seller(
      id: 'current_seller_id',
      email: emailController.text.trim(),
      fullName: fullNameController.text.trim(),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      businessName: businessNameController.text.trim(),
      bio: bioController.text.trim(),
      businessLogo: businessLogo.value.isNotEmpty ? businessLogo.value : null,
      socialMediaLinks: _getSocialMediaLinks(),
      whatsappNumber: whatsappController.text.trim(),
      profileImage: profileImage.value.isNotEmpty ? profileImage.value : null,
      phoneNumber: phoneController.text.trim(),
    );
  }

  List<String> _getSocialMediaLinks() {
    List<String> links = [];
    
    if (instagramController.text.trim().isNotEmpty) {
      links.add('instagram:${instagramController.text.trim()}');
    }
    if (facebookController.text.trim().isNotEmpty) {
      links.add('facebook:${facebookController.text.trim()}');  
    }
    if (websiteController.text.trim().isNotEmpty) {
      links.add('website:${websiteController.text.trim()}');
    }
    
    return links;
  }

  void discardChanges() {
    Get.dialog(
      AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool get canSave {
    return hasChanges.value && 
           businessNameController.text.trim().isNotEmpty &&
           fullNameController.text.trim().isNotEmpty &&
           emailController.text.trim().isNotEmpty;
  }

  double get profileCompletionPercentage {
    int completedFields = 0;
    int totalFields = 9; // Total important fields

    if (businessNameController.text.trim().isNotEmpty) completedFields++;
    if (fullNameController.text.trim().isNotEmpty) completedFields++;
    if (emailController.text.trim().isNotEmpty) completedFields++;
    if (phoneController.text.trim().isNotEmpty) completedFields++;
    if (bioController.text.trim().isNotEmpty) completedFields++;
    if (whatsappController.text.trim().isNotEmpty) completedFields++;
    if (profileImage.value.isNotEmpty) completedFields++;
    if (businessLogo.value.isNotEmpty) completedFields++;
    if (instagramController.text.trim().isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }
}
