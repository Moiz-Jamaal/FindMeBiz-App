import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/enquiry.dart';
import '../../../../data/models/enquiry_response.dart';

class EnquiryController extends GetxController {
  // Observables
  final isLoading = false.obs;
  final enquiries = <Enquiry>[].obs;
  final selectedEnquiry = Rxn<Enquiry>();
  final enquiryResponses = <EnquiryResponse>[].obs;
  
  // Form data
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final selectedCategories = <String>[].obs;
  final budgetMinController = TextEditingController();
  final budgetMaxController = TextEditingController();
  final selectedUrgency = 'medium'.obs;
  final locationController = TextEditingController();
  final additionalImages = <String>[].obs;
  
  // Form validation
  final formKey = GlobalKey<FormState>();
  
  // Predefined categories (could be fetched from API)
  final availableCategories = [
    'Apparel',
    'Jewelry',
    'Food & Beverages',
    'Art & Crafts',
    'Home Decor',
    'Electronics',
    'Books & Stationery',
    'Beauty & Personal Care',
    'Sports & Fitness',
    'Toys & Games',
    'Automotive',
    'Garden & Plants',
    'Pet Supplies',
    'Musical Instruments',
    'Furniture',
    'Kitchen & Dining',
    'Health & Wellness',
    'Office Supplies',
    'Technology',
    'Photography',
    'Fashion Accessories',
    'Footwear',
    'Bags & Luggage',
    'Other'
  ].obs;
  
  final urgencyLevels = [
    {'value': 'low', 'label': 'Low Priority', 'description': 'No rush, flexible timing'},
    {'value': 'medium', 'label': 'Medium Priority', 'description': 'Looking for within a week'},
    {'value': 'high', 'label': 'High Priority', 'description': 'Need within 2-3 days'},
    {'value': 'urgent', 'label': 'Urgent', 'description': 'Need immediately'},
  ];

  @override
  void onInit() {
    super.onInit();
    loadEnquiries();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    budgetMinController.dispose();
    budgetMaxController.dispose();
    locationController.dispose();
    super.onClose();
  }

  // Load user's enquiries
  Future<void> loadEnquiries() async {
    try {
      isLoading.value = true;
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock data
      final mockEnquiries = [
        Enquiry(
          id: '1',
          buyerId: 'buyer1',
          title: 'Looking for handmade jewelry',
          description: 'I need some custom handmade jewelry for a wedding. Looking for gold and silver pieces.',
          categories: ['Jewelry', 'Art & Crafts'],
          budgetMin: 100,
          budgetMax: 500,
          urgency: 'medium',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          responseCount: 3,
          interestedSellerIds: ['seller1', 'seller2', 'seller3'],
        ),
        Enquiry(
          id: '2',
          buyerId: 'buyer1',
          title: 'Fresh organic vegetables',
          description: 'Looking for fresh organic vegetables for my restaurant. Need regular supply.',
          categories: ['Food & Beverages'],
          budgetMin: 50,
          budgetMax: 200,
          urgency: 'high',
          preferredLocation: 'Near Main Market',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
          responseCount: 5,
          interestedSellerIds: ['seller4', 'seller5'],
        ),
      ];
      
      enquiries.value = mockEnquiries;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load enquiries: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Create new enquiry
  Future<void> createEnquiry() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedCategories.isEmpty) {
      Get.snackbar(
        'Categories Required',
        'Please select at least one category',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Create enquiry object
      final enquiry = Enquiry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        buyerId: 'current_buyer_id', // Get from auth service
        title: titleController.text,
        description: descriptionController.text,
        categories: selectedCategories.toList(),
        budgetMin: budgetMinController.text.isNotEmpty 
            ? double.tryParse(budgetMinController.text) 
            : null,
        budgetMax: budgetMaxController.text.isNotEmpty 
            ? double.tryParse(budgetMaxController.text) 
            : null,
        urgency: selectedUrgency.value,
        preferredLocation: locationController.text.isNotEmpty 
            ? locationController.text 
            : null,
        images: additionalImages.toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));

      // Add to list
      enquiries.insert(0, enquiry);

      // Clear form
      clearForm();

      Get.back();
      Get.snackbar(
        'Success',
        'Your enquiry has been posted! Sellers will be notified.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create enquiry: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load responses for an enquiry
  Future<void> loadEnquiryResponses(String enquiryId) async {
    try {
      isLoading.value = true;
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock responses
      final mockResponses = [
        EnquiryResponse(
          id: '1',
          enquiryId: enquiryId,
          sellerId: 'seller1',
          message: 'I have beautiful handmade jewelry perfect for your wedding! Check out my collection.',
          productIds: ['product1', 'product2'],
          quotedPrice: 350,
          availability: 'available',
          deliveryTime: '3-5 days',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        EnquiryResponse(
          id: '2',
          enquiryId: enquiryId,
          sellerId: 'seller2',
          message: 'Hello! I specialize in custom wedding jewelry. I can create exactly what you need.',
          quotedPrice: 450,
          availability: 'custom_order',
          deliveryTime: '7-10 days',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];
      
      enquiryResponses.value = mockResponses;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load responses: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle category selection
  void toggleCategory(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
  }

  // Add image
  void addImage(String imagePath) {
    additionalImages.add(imagePath);
  }

  // Remove image
  void removeImage(int index) {
    additionalImages.removeAt(index);
  }

  // Set urgency
  void setUrgency(String urgency) {
    selectedUrgency.value = urgency;
  }

  // Clear form
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    budgetMinController.clear();
    budgetMaxController.clear();
    locationController.clear();
    selectedCategories.clear();
    additionalImages.clear();
    selectedUrgency.value = 'medium';
  }

  // View enquiry details
  void viewEnquiryDetails(Enquiry enquiry) {
    selectedEnquiry.value = enquiry;
    loadEnquiryResponses(enquiry.id);
    Get.toNamed('/buyer-enquiry-details', arguments: enquiry);
  }

  // Delete enquiry
  Future<void> deleteEnquiry(String enquiryId) async {
    try {
      isLoading.value = true;
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      enquiries.removeWhere((e) => e.id == enquiryId);
      
      Get.snackbar(
        'Success',
        'Enquiry deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete enquiry: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mark enquiry as inactive
  Future<void> markEnquiryInactive(String enquiryId) async {
    try {
      final index = enquiries.indexWhere((e) => e.id == enquiryId);
      if (index != -1) {
        enquiries[index] = enquiries[index].copyWith(isActive: false);
        Get.snackbar(
          'Success',
          'Enquiry marked as inactive',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update enquiry: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadEnquiries();
  }

  // Form validators
  String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    if (value.length < 5) {
      return 'Title must be at least 5 characters';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    if (value.length < 20) {
      return 'Description must be at least 20 characters';
    }
    return null;
  }

  String? validateBudget(String? value) {
    if (value != null && value.isNotEmpty) {
      final budget = double.tryParse(value);
      if (budget == null || budget <= 0) {
        return 'Please enter a valid budget amount';
      }
    }
    return null;
  }

  // Helper methods
  int getActiveEnquiriesCount() {
    return enquiries.where((e) => e.isActive).length;
  }

  int getTotalResponsesCount() {
    return enquiries.fold(0, (sum, e) => sum + e.responseCount);
  }
}
