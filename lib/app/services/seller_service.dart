import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';
import 'api/api_client.dart';
import '../data/models/api/index.dart';

class SellerService extends BaseApiService {
  
  // Get seller details by user ID
  Future<ApiResponse<SellerDetailsExtended>> getSellerByUserId(int userId) async {
    final response = await get<SellerDetailsExtended>(
      '/Seller/$userId',
      fromJson: (json) => SellerDetailsExtended.fromJson(json),
    );
    
    return response;
  }

  // Get seller details by seller ID
  Future<ApiResponse<SellerDetailsExtended>> getSellerBySellerId(int sellerId) async {
    final response = await get<SellerDetailsExtended>(
      '/SellerBySellerId/$sellerId',
      fromJson: (json) => SellerDetailsExtended.fromJson(json),
    );
    
    return response;
  }

  // Create new seller profile
  Future<ApiResponse<SellerDetails>> createSeller(SellerDetails seller) async {
    final response = await post<SellerDetails>(
      '/Seller',
      body: seller.toJson(),
      fromJson: (json) => SellerDetails.fromJson(json),
    );
    
    return response;
  }

  // Update seller profile
  Future<ApiResponse<void>> updateSeller(SellerDetails seller) async {
    if (seller.sellerid == null) {
      return ApiResponse.error('Seller ID is required for update');
    }
    
    final response = await put<void>(
      '/Seller/${seller.sellerid}',
      body: seller.toJson(),
    );
    
    return response;
  }

  // Delete seller profile
  Future<ApiResponse<void>> deleteSeller(int sellerId) async {
    final response = await delete('/Seller/$sellerId');
    return response;
  }

  // Get seller settings
  Future<ApiResponse<SellerSettings>> getSellerSettings(int sellerId) async {
    final response = await get<SellerSettings>(
      '/SellerSettings/$sellerId',
      fromJson: (json) => SellerSettings.fromJson(json),
    );
    
    return response;
  }

  // Create seller settings
  Future<ApiResponse<SellerSettings>> createSellerSettings(SellerSettings settings) async {
    final response = await post<SellerSettings>(
      '/SellerSettings',
      body: settings.toJson(),
      fromJson: (json) => SellerSettings.fromJson(json),
    );
    
    return response;
  }

  // Update seller settings
  Future<ApiResponse<void>> updateSellerSettings(SellerSettings settings) async {
    if (settings.sellerid == null) {
      return ApiResponse.error('Seller ID is required for update');
    }
    
    final response = await put<void>(
      '/SellerSettings/${settings.sellerid}',
      body: settings.toJson(),
    );
    
    return response;
  }

  // Get seller categories
  Future<ApiResponse<List<SellerCategory>>> getSellerCategories(int sellerId) async {
    final response = await getList<SellerCategory>(
      '/SellerCategories/$sellerId',
      fromJson: (json) => SellerCategory.fromJson(json),
    );
    
    return response;
  }

  // Add category to seller
  Future<ApiResponse<SellerCategory>> addSellerCategory(SellerCategory sellerCategory) async {
    final response = await post<SellerCategory>(
      '/SellerCategory',
      body: sellerCategory.toJson(),
      fromJson: (json) => SellerCategory.fromJson(json),
    );
    
    return response;
  }

  // Remove category from seller
  Future<ApiResponse<void>> removeSellerCategory(int bindId) async {
    final response = await delete('/SellerCategory/$bindId');
    return response;
  }

  // Get seller URLs
  Future<ApiResponse<List<SellerUrl>>> getSellerUrls(int sellerId) async {
    final response = await getList<SellerUrl>(
      '/SellerUrls/$sellerId',
      fromJson: (json) => SellerUrl.fromJson(json),
    );
    
    return response;
  }

  // Add seller URL
  Future<ApiResponse<SellerUrl>> addSellerUrl(SellerUrl sellerUrl) async {
    final response = await post<SellerUrl>(
      '/SellerUrl',
      body: sellerUrl.toJson(),
      fromJson: (json) => SellerUrl.fromJson(json),
    );
    
    return response;
  }

  // Update seller URL
  Future<ApiResponse<void>> updateSellerUrl(SellerUrl sellerUrl) async {
    final response = await put<void>(
      '/SellerUrl',
      body: sellerUrl.toJson(),
    );
    
    return response;
  }

  // Delete seller URL
  Future<ApiResponse<void>> deleteSellerUrl(SellerUrl sellerUrl) async {
    try {
      // Use http client directly since we need to send body with DELETE request
      final uri = Uri.parse('${ApiClient.baseUrl}${ApiClient.apiPath}/SellerUrl');
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(sellerUrl.toJson()),
      );
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to delete seller URL');
      }
    } catch (e) {
      return ApiResponse.error('Error deleting seller URL: ${e.toString()}');
    }
  }

  // Search sellers
  Future<ApiResponse<List<SellerDetails>>> searchSellers({
    String? businessName,
    String? city,
    String? area,
    int? categoryId,
  }) async {
    final queryParams = <String, String>{};
    
    if (businessName != null) queryParams['businessName'] = businessName;
    if (city != null) queryParams['city'] = city;
    if (area != null) queryParams['area'] = area;
    if (categoryId != null) queryParams['categoryId'] = categoryId.toString();
    
    final response = await getList<SellerDetails>(
      '/SearchSellers',
      queryParams: queryParams,
      fromJson: (json) => SellerDetails.fromJson(json),
    );
    
    return response;
  }

  // Set seller subscription
  Future<ApiResponse<void>> setSellerSubscription({
    required int sellerId,
    int? planId,
    String? planName,
    double? amount,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    String? razorpayPaymentId,
    String? subscriptionDetailsJson,
  }) async {
    final body = <String, dynamic>{};
    
    if (planId != null) body['planId'] = planId;
    if (planName != null) body['planName'] = planName;
    if (amount != null) body['amount'] = amount;
    if (currency != null) body['currency'] = currency;
    if (startDate != null) body['startDate'] = startDate.toIso8601String();
    if (endDate != null) body['endDate'] = endDate.toIso8601String();
    if (razorpayPaymentId != null) body['razorpayPaymentId'] = razorpayPaymentId;
    if (subscriptionDetailsJson != null) body['subscriptionDetailsJson'] = subscriptionDetailsJson;
    
    final response = await put<void>(
      '/SellerSubscription/$sellerId',
      body: body,
    );
    
    return response;
  }

  // Publish seller profile
  Future<ApiResponse<void>> publishSellerProfile({required int sellerId}) async {
    final response = await put<void>(
      '/PublishSeller/$sellerId',
    );
    return response;
  }

  // Razorpay payment methods
  Future<ApiResponse<Map<String, dynamic>>> createRazorpayOrder({
    required int sellerId,
    required int subscriptionId,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/CreateRazorpayOrder',
      body: {
        'sellerId': sellerId,
        'subscriptionId': subscriptionId,
      },
      fromJson: (json) => json,
    );
    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyRazorpayPayment({
    required int sellerId,
    required int subscriptionId,
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    final response = await post<Map<String, dynamic>>(
      '/VerifyRazorpayPayment',
      body: {
        'sellerId': sellerId,
        'subscriptionId': subscriptionId,
        'paymentId': paymentId,
        'orderId': orderId,
        'signature': signature,
      },
      fromJson: (json) => json,
    );
    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> checkSubscription(int sellerId) async {
    return await get<Map<String, dynamic>>(
      '/CheckSubscription/$sellerId',
      fromJson: (json) => json,
    );
  }

  // Review Management
  Future<ApiResponse<Map<String, dynamic>>> getSellerReviews(int sellerId) async {
    return await get<Map<String, dynamic>>(
      '/SellerManagement/MyReviews/$sellerId',
      fromJson: (json) => json,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteSellerReview(int reviewId, int sellerId) async {
    final response = await delete('/SellerManagement/DeleteSellerReview/$reviewId?sellerId=$sellerId');
    return ApiResponse.success({'success': true}, statusCode: response.statusCode);
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteProductReview(int reviewId, int sellerId) async {
    final response = await delete('/SellerManagement/DeleteProductReview/$reviewId?sellerId=$sellerId');
    return ApiResponse.success({'success': true}, statusCode: response.statusCode);
  }
}
