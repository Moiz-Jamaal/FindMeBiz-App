import 'package:get/get.dart';
import '../app/services/api/api_exception.dart';
import '../app/data/models/product.dart';
import '../app/core/config/api_config.dart';

class ProductService extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ApiConfig.fullApiUrl;
    httpClient.timeout = ApiConfig.requestTimeout;
    
    // Add default headers
    httpClient.defaultContentType = 'application/json';
    super.onInit();
  }

  // Update product
  Future<ApiResponse<Product>> updateProduct(UpdateProductRequest request) async {
    try {
      final response = await put('/Product/${request.productId}', request.toJson());
      
      if (response.hasError) {
        return ApiResponse<Product>(
          success: false,
          message: response.statusText ?? 'Update failed',
          statusCode: response.statusCode,
        );
      }

      final product = Product.fromJson(response.body);
      return ApiResponse<Product>(
        success: true,
        data: product,
        message: 'Product updated successfully',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<Product>(
        success: false,
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  // Delete product
  Future<ApiResponse<void>> deleteProduct(int productId) async {
    try {
      final response = await delete('/Product/$productId');
      
      return ApiResponse<void>(
        success: !response.hasError,
        message: response.hasError ? response.statusText ?? 'Delete failed' : 'Product deleted successfully',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }
}

class UpdateProductRequest {
  final int productId;
  final String productName;
  final String? description;
  final double? price;
  final bool priceOnInquiry;
  final bool isAvailable;
  final List<int> categoryIds;
  final int? primaryCategoryId;
  final String? customAttributes;

  UpdateProductRequest({
    required this.productId,
    required this.productName,
    this.description,
    this.price,
    this.priceOnInquiry = false,
    this.isAvailable = true,
    required this.categoryIds,
    this.primaryCategoryId,
    this.customAttributes,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'description': description,
      'price': price,
      'priceOnInquiry': priceOnInquiry,
      'isAvailable': isAvailable,
      'categoryIds': categoryIds,
      'primaryCategoryId': primaryCategoryId,
      'customAttributes': customAttributes,
    };
  }
}
