import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../services/product_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/category_service.dart';
import '../../../../services/seller_service.dart';

class AddProductController extends GetxController {
  final ProductService _productService = ProductService.instance;
  final AuthService _authService = Get.find<AuthService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final SellerService _sellerService = Get.find<SellerService>();
  
  // Form controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  
  // Form data
  final RxString selectedCategory = ''.obs;
  final RxList<String> selectedCategoryIds = <String>[].obs;
  final RxList<ProductImageData> productImages = <ProductImageData>[].obs;
  final RxBool isAvailable = true.obs;
  final RxBool priceOnInquiry = false.obs;
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxInt currentStep = 0.obs;
  bool _savingDialogOpen = false;
  
  // Categories
  final RxList<CategoryOption> availableCategories = <CategoryOption>[].obs;
  
  // Form validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Trigger re-validation when non-Rx fields change
  void notifyValidationChanged() {
    // Force observers (like bottom nav) to re-evaluate canProceed
    currentStep.refresh();
  }

  @override
  void onInit() {
    super.onInit();
    _checkSubscriptionAndInit();
  }

  Future<void> _checkSubscriptionAndInit() async {
    final hasSubscription = await _checkSellerSubscription();
    if (!hasSubscription) {
      _showSubscriptionRequiredDialog();
      return;
    }
    _loadCategories();
  }

  Future<bool> _checkSellerSubscription() async {
    try {
      // Some parts of the app cache subscription state on the dashboard controller.
      // Honor that if available to avoid redundant calls and mismatches.
      try {
        final dashboard = Get.find<dynamic>(tag: null);
        if (dashboard is GetxController && dashboard.runtimeType.toString().contains('SellerDashboardController')) {
          final hasActive = (dashboard as dynamic).hasActiveSubscription as bool?;
          if (hasActive == true) return true;
        }
      } catch (_) {
        // ignore if dashboard is not in memory
      }

      final sellerId = _authService.currentSeller?.sellerid ?? _authService.currentSeller?.sellerId;
      if (sellerId == null) return false;

      // Use the unified subscription endpoint
      final response = await _sellerService.checkSubscription(sellerId);
      if (response.success && response.data != null) {
        final data = response.data!;
        final active = (data['hasActiveSubscription'] == true) && (data['isExpired'] != true);
        return active;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showSubscriptionRequiredDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Subscription Required'),
        content: const Text(
          'You need an active subscription to add products. Please subscribe to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Go back to previous screen
              Get.toNamed('/seller-publish'); // Navigate to subscription page
            },
            child: const Text('Subscribe Now'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.onClose();
  }

  Future<void> _loadCategories() async {
    try {
      isLoading.value = true;
      final response = await _categoryService.getCategories();
      
      if (response.isSuccess && response.data != null) {
        availableCategories.assignAll(
          response.data!.map((cat) => CategoryOption(
            id: cat.catid.toString(),
            name: cat.catname,
          )).toList()
        );
        
        // Set default category
        if (availableCategories.isNotEmpty) {
          selectedCategory.value = availableCategories.first.name;
          selectedCategoryIds.add(availableCategories.first.id);
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to load categories: $e');
    } finally {
      isLoading.value = false;
    }
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

  // Pure validation with optional error messages
  bool _isStepValid(int step, {bool showErrors = false}) {
    switch (step) {
      case 0:
        if (nameController.text.trim().isEmpty) {
          if (showErrors) _showErrorMessage('Product name is required');
          return false;
        }
        if (selectedCategoryIds.isEmpty) {
          if (showErrors) _showErrorMessage('Please select at least one category');
          return false;
        }
        return true;
      case 1:
        if (descriptionController.text.trim().isEmpty) {
          if (showErrors) _showErrorMessage('Product description is required');
          return false;
        }
        if (!priceOnInquiry.value && (priceController.text.trim().isEmpty ||
            double.tryParse(priceController.text) == null)) {
          if (showErrors) _showErrorMessage('Please enter a valid price or enable "Price on Inquiry"');
          return false;
        }
        return true;
      case 2:
        return true;
      default:
        return false;
    }
  }

  bool _validateCurrentStep() {
    return _isStepValid(currentStep.value, showErrors: true);
  }

  void updateCategory(String? category) {
    if (category != null) {
      selectedCategory.value = category;
      final categoryOption = availableCategories.firstWhereOrNull((cat) => cat.name == category);
      if (categoryOption != null) {
        selectedCategoryIds.clear();
        selectedCategoryIds.add(categoryOption.id);
      }
  notifyValidationChanged();
    }
  }

  void togglePriceOnInquiry() {
    priceOnInquiry.value = !priceOnInquiry.value;
    if (priceOnInquiry.value) {
      priceController.clear();
    }
  notifyValidationChanged();
  }

  Future<void> addImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorMessage('Failed to capture image: $e');
    }
  }

  Future<void> addImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  Future<void> addMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      for (final image in images) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick images: $e');
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      // Web-compatible image processing
      Uint8List imageBytes;
      
      if (kIsWeb) {
        // Web: Read as bytes directly
        imageBytes = await image.readAsBytes();
      } else {
        // Mobile: Use File approach
        final File imageFile = File(image.path);
        imageBytes = await imageFile.readAsBytes();
      }
      
      final String base64String = base64Encode(imageBytes);
      
      final imageData = ProductImageData(
        fileName: image.name,
        base64Content: base64String,
        contentType: _getContentType(image),
        order: productImages.length,
        isPrimary: productImages.isEmpty,
        localPath: kIsWeb ? null : image.path,
      );
      
      productImages.add(imageData);
    } catch (e) {
      _showErrorMessage('Failed to process image: $e');
    }
  }

  String _getContentType(XFile image) {
    // First try to use the mimeType from XFile (more reliable on web)
    if (image.mimeType != null && image.mimeType!.isNotEmpty) {
      return image.mimeType!;
    }

    // Fallback to extension-based detection
    final fileName = image.name.toLowerCase();
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.endsWith('.png')) {
      return 'image/png';
    } else if (fileName.endsWith('.webp')) {
      return 'image/webp';
    } else if (fileName.endsWith('.gif')) {
      return 'image/gif';
    } else {
      return 'image/jpeg'; // Safe default
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < productImages.length) {
      final wasRemovingPrimary = productImages[index].isPrimary;
      productImages.removeAt(index);
      
      // Reorder images
      for (int i = 0; i < productImages.length; i++) {
        productImages[i] = productImages[i].copyWith(order: i);
      }
      
      // Set new primary if needed
      if (wasRemovingPrimary && productImages.isNotEmpty) {
        productImages[0] = productImages[0].copyWith(isPrimary: true);
      }
    }
  }

  void setPrimaryImage(int index) {
    if (index >= 0 && index < productImages.length) {
      for (int i = 0; i < productImages.length; i++) {
        productImages[i] = productImages[i].copyWith(isPrimary: i == index);
      }
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = productImages.removeAt(oldIndex);
    productImages.insert(newIndex, item);
    
    // Update order
    for (int i = 0; i < productImages.length; i++) {
      productImages[i] = productImages[i].copyWith(order: i);
    }
  }

  void toggleAvailability() {
    isAvailable.value = !isAvailable.value;
  }

  // Getters for UI
  String get stepTitle {
    switch (currentStep.value) {
      case 0:
        return 'Product Information';
      case 1:
        return 'Description & Pricing';
      case 2:
        return 'Product Images';
      default:
        return 'Add Product';
    }
  }

  String get stepDescription {
    switch (currentStep.value) {
      case 0:
        return 'Enter basic product details';
      case 1:
        return 'Add description and set pricing';
      case 2:
        return 'Upload product images';
      default:
        return '';
    }
  }

  bool get canProceed => _isStepValid(currentStep.value, showErrors: false);

  void addImage() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => _handleImageSelection(addImageFromCamera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => _handleImageSelection(addImageFromGallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Multiple Images'),
              onTap: () => _handleImageSelection(addMultipleImages),
            ),
          ],
        ),
      ),
    );
  }

  void _handleImageSelection(Function imageFunction) async {
    // Close the bottom sheet first
    if (Get.isBottomSheetOpen ?? false) {
      Navigator.of(Get.context!).pop();
    }
    // Then call the image function
    imageFunction();
  }

  // Add a debug method to test button functionality
  void debugButtonPress() {
    
    
    
    
    
    
    
    
    
    
    
    
    
    if (currentStep.value == 2) {
      
      saveProduct();
    } else {
      
      nextStep();
    }
  }

  Future<void> saveProduct() async {
    
    // Check subscription before saving
    final hasSubscription = await _checkSellerSubscription();
    if (!hasSubscription) {
      _showSubscriptionRequiredDialog();
      return;
    }
    
    if (!_validateAllSteps()) {
      
      _showErrorMessage('Please fill in all required fields');
      return;
    }
    

    try {
      
      isSaving.value = true;
      
      
      _openSavingDialog();
      
      // Get current seller ID
      final sellerId = _authService.currentSeller?.sellerid;
      
      
      if (sellerId == null) {
        
        // _showErrorMessage('Seller not found. Please login again.');
        _closeSavingDialogIfOpen();
        return;
      }

      // Debug: Log request details
      
      
      
      
      
      

      // Prepare create request (without media; we'll upload images separately)
      final request = CreateProductRequest(
        sellerId: sellerId,
        productName: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: priceOnInquiry.value ? null : double.tryParse(priceController.text),
        priceOnInquiry: priceOnInquiry.value,
        isAvailable: isAvailable.value,
        categoryIds: selectedCategoryIds.map((id) => int.parse(id)).toList(),
        primaryCategoryId: selectedCategoryIds.isNotEmpty ? int.parse(selectedCategoryIds.first) : null,
        media: const [],
      );

      
      
      
    // Create product with timeout (match API timeout)
    final response = await _productService.createProduct(request)
      .timeout(const Duration(seconds: 35), onTimeout: () {
        
        throw Exception('Request timed out. Please check your connection and try again.');
      });
      
      // Minimal debug info without logging images
      
      
      if (response.isSuccess && response.data != null) {
        
        // Navigate back immediately after product creation
        final created = response.data!;
        final productId = int.tryParse(created.id);
        

        // Close dialog first and wait
        _closeSavingDialogIfOpen();

        
        // Navigate back immediately without snackbar to avoid interference
        Get.back(result: created);
        
        // Show success message after navigation
        _showSuccessMessage('Product created successfully!');

        // Upload images in background (do not block UI)
        if (productId != null && productImages.isNotEmpty) {
          final images = productImages.map((img) => ImageUploadData(
            base64Content: img.base64Content,
            fileName: img.fileName,
            mediaOrder: img.order,
            isPrimary: img.isPrimary,
            altText: img.altText,
            contentType: img.contentType,
          )).toList();

          Future(() async {
       
              
              final uploadResp = await _productService
                  .uploadMultipleImages(productId, images)
                  .timeout(const Duration(seconds: 45));
              if (!uploadResp.isSuccess) {
                
              } else {
                
              }
          
          });
        }
      } else {
        
        _closeSavingDialogIfOpen();
        
        
        
        String errorMsg = response.errorMessage ?? 'Failed to create product';
        if (response.statusCode == 500) {
          errorMsg = 'Server error. Please try again later.';
        } else if (response.statusCode == 400) {
          errorMsg = 'Invalid product data. Please check your inputs.';
        } else if (response.statusCode == 404) {
          errorMsg = 'Service not found. Please contact support.';
        }
        _showErrorMessage(errorMsg);
      }
    } catch (e) {
      
      _closeSavingDialogIfOpen();
      
      
      
      
      String errorMessage;
      if (e.toString().contains('timed out')) {
        errorMessage = 'Request timed out. Please check your internet connection and try again.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid server response. Please try again.';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = 'SSL connection error. Please try again.';
      } else {
        errorMessage = 'Error creating product: ${e.toString().length > 100 ? "${e.toString().substring(0, 100)}..." : e.toString()}';
      }
      _showErrorMessage(errorMessage);
    } finally {
      
      isSaving.value = false;
      
    }
  }

  // Add a debug method to test API connectivity
  Future<void> testApiConnection() async {
 
      
      // Test with a simple categories call
       await _categoryService.getCategories();
      
  
  }  void _openSavingDialog() {
    if (!(_savingDialogOpen)) {
      _savingDialogOpen = true;
      if (Get.context != null) {
        showDialog(
          context: Get.context!,
          barrierDismissible: false,
          // ignore: deprecated_member_use
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Saving product…',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        
        // Safety net: auto-close dialog after 90 seconds if something goes wrong
        Timer(const Duration(seconds: 90), () {
          if (_savingDialogOpen) {
            _closeSavingDialogIfOpen();
            _showErrorMessage('Operation timed out. Please try again.');
            isSaving.value = false;
          }
        });
      }
    }
  }

  void _closeSavingDialogIfOpen() {
    if (_savingDialogOpen) {
      _savingDialogOpen = false;
      try {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        // Additional check to ensure dialog is closed
        if (Navigator.canPop(Get.context!)) {
          Navigator.of(Get.context!).pop();
        }
      } catch (e) {
        
        // Force reset dialog state even if closing fails
        _savingDialogOpen = false;
      }
    }
  }

  bool _validateAllSteps() {
    final originalStep = currentStep.value;
    for (int i = 0; i <= 2; i++) {
      currentStep.value = i;
      if (!_validateCurrentStep()) {
        // Stay on the first failing step so the user sees what to fix
        notifyValidationChanged();
        return false;
      }
    }
    // Restore original step if everything is valid
    currentStep.value = originalStep;
    return true;
  }

  void _showSuccessMessage(String message) {
    try {
      Get.snackbar(
        'Success',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // If snackbar fails, try to show a dialog instead
      if (Get.context != null) {
        showDialog(
          context: Get.context!,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showErrorMessage(String message) {
    try {
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      // If snackbar fails, try to show a dialog instead
      if (Get.context != null) {
        showDialog(
          context: Get.context!,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class CategoryOption {
  final String id;
  final String name;

  CategoryOption({required this.id, required this.name});
}

class ProductImageData {
  final String fileName;
  final String base64Content;
  final String contentType;
  final int order;
  final bool isPrimary;
  final String? altText;
  final String? localPath;

  ProductImageData({
    required this.fileName,
    required this.base64Content,
    required this.contentType,
    required this.order,
    this.isPrimary = false,
    this.altText,
    this.localPath,
  });

  ProductImageData copyWith({
    String? fileName,
    String? base64Content,
    String? contentType,
    int? order,
    bool? isPrimary,
    String? altText,
    String? localPath,
  }) {
    return ProductImageData(
      fileName: fileName ?? this.fileName,
      base64Content: base64Content ?? this.base64Content,
      contentType: contentType ?? this.contentType,
      order: order ?? this.order,
      isPrimary: isPrimary ?? this.isPrimary,
      altText: altText ?? this.altText,
      localPath: localPath ?? this.localPath,
    );
  }
}
