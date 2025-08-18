import 'package:get/get.dart';
import 'api/base_api_service.dart';
import 'api/api_exception.dart';
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
    final response = await delete(
      '/SellerUrl',
      // Note: This endpoint expects body in DELETE, which is unusual but matches the API
    );
    
    return response;
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
}
