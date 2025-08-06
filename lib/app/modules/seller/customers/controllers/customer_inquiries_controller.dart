import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CustomerInquiry {
  final String id;
  final String customerName;
  final String customerPhone;
  final String message;
  final DateTime timestamp;
  final String productId;
  final String productName;
  final String status; // 'new', 'contacted', 'resolved'
  final String? sellerResponse;

  CustomerInquiry({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.message,
    required this.timestamp,
    required this.productId,
    required this.productName,
    this.status = 'new',
    this.sellerResponse,
  });

  CustomerInquiry copyWith({
    String? status,
    String? sellerResponse,
  }) {
    return CustomerInquiry(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      message: message,
      timestamp: timestamp,
      productId: productId,
      productName: productName,
      status: status ?? this.status,
      sellerResponse: sellerResponse ?? this.sellerResponse,
    );
  }
}

class CustomerInquiriesController extends GetxController {
  final RxList<CustomerInquiry> inquiries = <CustomerInquiry>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'all'.obs;

  final List<String> filterOptions = ['all', 'new', 'contacted', 'resolved'];

  @override
  void onInit() {
    super.onInit();
    loadInquiries();
  }

  void loadInquiries() {
    isLoading.value = true;
    
    // Simulate API call with mock data
    Future.delayed(const Duration(seconds: 1), () {
      inquiries.addAll(_getMockInquiries());
      isLoading.value = false;
    });
  }

  void refreshInquiries() {
    isLoading.value = true;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      isLoading.value = false;
    });
  }

  List<CustomerInquiry> get filteredInquiries {
    if (selectedFilter.value == 'all') {
      return inquiries;
    }
    return inquiries.where((inquiry) => inquiry.status == selectedFilter.value).toList();
  }

  void updateFilter(String filter) {
    selectedFilter.value = filter;
  }

  void markAsContacted(CustomerInquiry inquiry) {
    final index = inquiries.indexWhere((i) => i.id == inquiry.id);
    if (index != -1) {
      inquiries[index] = inquiry.copyWith(status: 'contacted');
      
      Get.snackbar(
        'Updated',
        'Marked as contacted',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    }
  }

  void markAsResolved(CustomerInquiry inquiry) {
    final index = inquiries.indexWhere((i) => i.id == inquiry.id);
    if (index != -1) {
      inquiries[index] = inquiry.copyWith(status: 'resolved');
      
      Get.snackbar(
        'Updated',
        'Marked as resolved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    }
  }

  void contactCustomer(CustomerInquiry inquiry) {
    // In a real app, this would launch WhatsApp or phone dialer
    Get.snackbar(
      'Contacting Customer',
      'Opening WhatsApp to contact ${inquiry.customerName}...\nNumber: ${inquiry.customerPhone}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    
    // Automatically mark as contacted
    markAsContacted(inquiry);
  }

  void addResponse(CustomerInquiry inquiry, String response) {
    final index = inquiries.indexWhere((i) => i.id == inquiry.id);
    if (index != -1) {
      inquiries[index] = inquiry.copyWith(
        sellerResponse: response,
        status: 'contacted',
      );
      
      Get.snackbar(
        'Response Added',
        'Your response has been saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.successColor,
        colorText: Colors.white,
      );
    }
  }

  void showResponseDialog(CustomerInquiry inquiry) {
    final responseController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: Text('Respond to ${inquiry.customerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original Message:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              inquiry.message,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Your Response',
                hintText: 'Type your response here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (responseController.text.trim().isNotEmpty) {
                addResponse(inquiry, responseController.text.trim());
                Get.back();
              }
            },
            child: const Text('Send Response'),
          ),
        ],
      ),
    );
  }

  int get newInquiriesCount {
    return inquiries.where((inquiry) => inquiry.status == 'new').length;
  }

  int get totalInquiriesCount {
    return inquiries.length;
  }

  List<CustomerInquiry> _getMockInquiries() {
    return [
      CustomerInquiry(
        id: 'inq_1',
        customerName: 'Priya Sharma',
        customerPhone: '+91 98765 43210',
        message: 'Hi! I\'m interested in your silk saree. Is it available in red color?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        productId: '1',
        productName: 'Beautiful Silk Saree',
        status: 'new',
      ),
      CustomerInquiry(
        id: 'inq_2',
        customerName: 'Rahul Patel',
        customerPhone: '+91 87654 32109',
        message: 'What is the price for bulk order of 10 pieces of the jewelry set?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        productId: '2',
        productName: 'Handcrafted Jewelry Set',
        status: 'new',
      ),
      CustomerInquiry(
        id: 'inq_3',
        customerName: 'Sneha Desai',
        customerPhone: '+91 76543 21098',
        message: 'Do you deliver to Ahmedabad? I want to order the Gujarati thali.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        productId: '3',
        productName: 'Gujarati Thali Special',
        status: 'contacted',
        sellerResponse: 'Yes, we deliver to Ahmedabad. Delivery charge is ₹50.',
      ),
      CustomerInquiry(
        id: 'inq_4',
        customerName: 'Amit Kumar',
        customerPhone: '+91 65432 10987',
        message: 'Is the wall art available? Can I see more pictures?',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        productId: '4',
        productName: 'Handwoven Wall Art',
        status: 'resolved',
        sellerResponse: 'Yes available. I have sent additional pictures via WhatsApp.',
      ),
      CustomerInquiry(
        id: 'inq_5',
        customerName: 'Kavya Shah',
        customerPhone: '+91 54321 09876',
        message: 'What material are the brass items made of? Are they pure brass?',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        productId: '5',
        productName: 'Decorative Brass Items',
        status: 'new',
      ),
    ];
  }
}
