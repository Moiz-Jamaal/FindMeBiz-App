import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/enquiry.dart';
import '../../../../data/models/enquiry_response.dart';

class SellerEnquiryController extends GetxController {
  // Observables
  final isLoading = false.obs;
  final enquiries = <Enquiry>[].obs;
  final filteredEnquiries = <Enquiry>[].obs;
  final myResponses = <EnquiryResponse>[].obs;
  
  // Filters
  final selectedCategories = <String>[].obs;
  final selectedUrgency = <String>[].obs;
  final showOnlyUnresponded = false.obs;
  final searchQuery = ''.obs;
  
  // Response form
  final responseMessageController = TextEditingController();
  final quotedPriceController = TextEditingController();
  final deliveryTimeController = TextEditingController();
  final selectedAvailability = 'available'.obs;
  final selectedProducts = <String>[].obs;
  
  // Form validation
  final responseFormKey = GlobalKey<FormState>();
  
  // Seller categories (would be fetched from current seller profile)
  final sellerCategories = [
    'Jewelry',
    'Art & Crafts',
    'Fashion Accessories',
  ].obs;
  
  final availabilityOptions = [
    {'value': 'available', 'label': 'Available', 'description': 'In stock and ready'},
    {'value': 'limited', 'label': 'Limited Stock', 'description': 'Few items available'},
    {'value': 'custom_order', 'label': 'Custom Order', 'description': 'Made to order'},
    {'value': 'not_available', 'label': 'Not Available', 'description': 'Currently out of stock'},
  ];

  @override
  void onInit() {
    super.onInit();
    loadEnquiries();
    loadMyResponses();
  }

  @override
  void onClose() {
    responseMessageController.dispose();
    quotedPriceController.dispose();
    deliveryTimeController.dispose();
    super.onClose();
  }

  // Load enquiries from categories that match seller's categories
  Future<void> loadEnquiries() async {
    try {
      isLoading.value = true;
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock enquiries that match seller's categories
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
          buyerId: 'buyer2',
          title: 'Custom leather handbags',
          description: 'Looking for someone who can make custom leather handbags for my boutique.',
          categories: ['Fashion Accessories', 'Art & Crafts'],
          budgetMin: 50,
          budgetMax: 150,
          urgency: 'low',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
          responseCount: 1,
          interestedSellerIds: ['seller4'],
        ),
        Enquiry(
          id: '3',
          buyerId: 'buyer3',
          title: 'Traditional earrings for festival',
          description: 'Need traditional style earrings for upcoming festival. Looking for authentic designs.',
          categories: ['Jewelry'],
          budgetMin: 30,
          budgetMax: 100,
          urgency: 'high',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          responseCount: 0,
          interestedSellerIds: [],
        ),
      ];
      
      enquiries.value = mockEnquiries;
      applyFilters();
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

  // Load seller's responses
  Future<void> loadMyResponses() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));
      
      final mockResponses = [
        EnquiryResponse(
          id: '1',
          enquiryId: '1',
          sellerId: 'current_seller_id',
          message: 'I have beautiful handmade jewelry perfect for your wedding!',
          quotedPrice: 350,
          availability: 'available',
          deliveryTime: '3-5 days',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
          status: 'pending',
        ),
      ];
      
      myResponses.value = mockResponses;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load responses: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Apply filters to enquiries
  void applyFilters() {
    var filtered = enquiries.where((enquiry) {
      // Category filter
      if (selectedCategories.isNotEmpty) {
        bool hasMatchingCategory = enquiry.categories
            .any((cat) => selectedCategories.contains(cat));
        if (!hasMatchingCategory) return false;
      }
      
      // Urgency filter
      if (selectedUrgency.isNotEmpty) {
        if (!selectedUrgency.contains(enquiry.urgency)) return false;
      }
      
      // Unresponded filter
      if (showOnlyUnresponded.value) {
        bool hasResponded = myResponses.any((r) => r.enquiryId == enquiry.id);
        if (hasResponded) return false;
      }
      
      // Search query filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        if (!enquiry.title.toLowerCase().contains(query) &&
            !enquiry.description.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    filteredEnquiries.value = filtered;
  }

  // Respond to an enquiry
  Future<void> respondToEnquiry(String enquiryId) async {
    if (!responseFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final response = EnquiryResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        enquiryId: enquiryId,
        sellerId: 'current_seller_id', // Get from auth service
        message: responseMessageController.text,
        quotedPrice: quotedPriceController.text.isNotEmpty 
            ? double.tryParse(quotedPriceController.text)
            : null,
        availability: selectedAvailability.value,
        deliveryTime: deliveryTimeController.text.isNotEmpty 
            ? deliveryTimeController.text 
            : null,
        productIds: selectedProducts.toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));

      // Add to responses
      myResponses.add(response);

      // Update enquiry response count
      final enquiryIndex = enquiries.indexWhere((e) => e.id == enquiryId);
      if (enquiryIndex != -1) {
        enquiries[enquiryIndex] = enquiries[enquiryIndex].copyWith(
          responseCount: enquiries[enquiryIndex].responseCount + 1,
          interestedSellerIds: [
            ...enquiries[enquiryIndex].interestedSellerIds,
            'current_seller_id'
          ],
        );
      }

      // Clear form
      clearResponseForm();
      
      // Reapply filters
      applyFilters();

      Get.back();
      Get.snackbar(
        'Success',
        'Your response has been sent to the buyer!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send response: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle category filter
  void toggleCategoryFilter(String category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    applyFilters();
  }

  // Toggle urgency filter
  void toggleUrgencyFilter(String urgency) {
    if (selectedUrgency.contains(urgency)) {
      selectedUrgency.remove(urgency);
    } else {
      selectedUrgency.add(urgency);
    }
    applyFilters();
  }

  // Set unresponded filter
  void setUnrespondedFilter(bool value) {
    showOnlyUnresponded.value = value;
    applyFilters();
  }

  // Search enquiries
  void searchEnquiries(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  // Set availability
  void setAvailability(String availability) {
    selectedAvailability.value = availability;
  }

  // Clear response form
  void clearResponseForm() {
    responseMessageController.clear();
    quotedPriceController.clear();
    deliveryTimeController.clear();
    selectedAvailability.value = 'available';
    selectedProducts.clear();
  }

  // Clear all filters
  void clearFilters() {
    selectedCategories.clear();
    selectedUrgency.clear();
    showOnlyUnresponded.value = false;
    searchQuery.value = '';
    applyFilters();
  }

  // View enquiry details
  void viewEnquiryDetails(Enquiry enquiry) {
    Get.toNamed('/seller-enquiry-details', arguments: enquiry);
  }

  // Check if seller has responded to enquiry
  bool hasRespondedToEnquiry(String enquiryId) {
    return myResponses.any((r) => r.enquiryId == enquiryId);
  }

  // Get response for enquiry
  EnquiryResponse? getResponseForEnquiry(String enquiryId) {
    try {
      return myResponses.firstWhere((r) => r.enquiryId == enquiryId);
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await Future.wait([
      loadEnquiries(),
      loadMyResponses(),
    ]);
  }

  // Form validators
  String? validateMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Message is required';
    }
    if (value.length < 10) {
      return 'Message must be at least 10 characters';
    }
    return null;
  }

  String? validatePrice(String? value) {
    if (value != null && value.isNotEmpty) {
      final price = double.tryParse(value);
      if (price == null || price <= 0) {
        return 'Please enter a valid price';
      }
    }
    return null;
  }

  // Helper methods
  int getNewEnquiriesCount() {
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    return filteredEnquiries.where((e) => e.createdAt.isAfter(oneDayAgo)).length;
  }

  int getUnrespondedCount() {
    return filteredEnquiries.where((e) => !hasRespondedToEnquiry(e.id)).length;
  }

  int getMyResponsesCount() {
    return myResponses.length;
  }
}
