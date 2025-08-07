import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class AddProductController extends GetxController {
  // Form controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  
  // Form data
  final RxString selectedCategory = ''.obs;
  final RxList<String> productImages = <String>[].obs;
  final RxBool isAvailable = true.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxInt currentStep = 0.obs;
  
  // Form validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Set default category
    if (AppConstants.productCategories.isNotEmpty) {
      selectedCategory.value = AppConstants.productCategories.first;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.onClose();
  }

  void nextStep() {
    if (currentStep.value < 2) {
      if (_validateCurrentStep()) {
        currentStep.value++;
      }
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        // Basic info validation
        return nameController.text.isNotEmpty && 
               selectedCategory.value.isNotEmpty;
      case 1:
        // Description validation
        return descriptionController.text.isNotEmpty;
      case 2:
        // Images validation (optional for now)
        return true;
      default:
        return false;
    }
  }

  void updateCategory(String? category) {
    if (category != null) {
      selectedCategory.value = category;
    }
  }

  void addImage() {
    // Placeholder for image picker
    // In a real app, this would use image_picker package
    productImages.add('placeholder_image_${productImages.length + 1}');
  }

  void removeImage(int index) {
    if (index >= 0 && index < productImages.length) {
      productImages.removeAt(index);
    }
  }

  void toggleAvailability() {
    isAvailable.value = !isAvailable.value;
  }

  void saveProduct() {
    if (!_validateAllSteps()) {
      Get.snackbar(
        'Validation Error',
        'Please fill in all required fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    
    // Create product object
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sellerId: 'current_seller_id', // This would come from auth service
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      price: double.tryParse(priceController.text.trim()),
      categories: [selectedCategory.value],
      images: List<String>.from(productImages),
      isAvailable: isAvailable.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      
      Get.snackbar(
        'Success',
        'Product added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
      
      // Navigate back to products list
      Get.back();
    });
  }

  bool _validateAllSteps() {
    return nameController.text.trim().isNotEmpty &&
           descriptionController.text.trim().isNotEmpty &&
           selectedCategory.value.isNotEmpty;
  }

  bool get canProceed {
    return _validateCurrentStep();
  }

  String get stepTitle {
    switch (currentStep.value) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Product Details';
      case 2:
        return 'Images & Availability';
      default:
        return 'Add Product';
    }
  }

  String get stepDescription {
    switch (currentStep.value) {
      case 0:
        return 'Enter the basic details of your product';
      case 1:
        return 'Provide a detailed description';
      case 2:
        return 'Add images and set availability';
      default:
        return '';
    }
  }
}
