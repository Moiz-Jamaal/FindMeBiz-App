import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'api_client.dart';
import 'api_exception.dart';

abstract class BaseApiService extends GetxService {
  ApiClient? _apiClient;

  ApiClient get apiClient {
    _apiClient ??= Get.find<ApiClient>();
    return _apiClient!;
  }

  @override
  void onInit() {
    super.onInit();
    try {
      _apiClient = Get.find<ApiClient>();
      print('✅ ApiClient initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize ApiClient: $e');
    }
  }

  // Handle HTTP response and convert to ApiResponse
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return ApiResponse.success(null as T, statusCode: response.statusCode);
        }

        final dynamic jsonResponse = jsonDecode(response.body);
        
        if (fromJson != null) {
          final data = fromJson(jsonResponse);
          return ApiResponse.success(data, statusCode: response.statusCode);
        } else {
          return ApiResponse.success(jsonResponse as T, statusCode: response.statusCode);
        }
      } catch (e) {
        return ApiResponse.error(
          'Failed to parse response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorJson = jsonDecode(response.body);
        errorMessage = errorJson['message'] ?? errorJson.toString();
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Request failed';
      }
      
      return ApiResponse.error(
        errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  // Handle list responses
  ApiResponse<List<T>> _handleListResponse<T>(
    http.Response response,
    T Function(dynamic json) fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) {
          return ApiResponse.success(<T>[], statusCode: response.statusCode);
        }

        final dynamic jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse is List) {
          final List<T> data = jsonResponse.map((json) => fromJson(json)).toList();
          return ApiResponse.success(data, statusCode: response.statusCode);
        } else {
          return ApiResponse.error(
            'Expected list response but got: ${jsonResponse.runtimeType}',
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        return ApiResponse.error(
          'Failed to parse list response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      String errorMessage = 'Request failed';
      try {
        final errorJson = jsonDecode(response.body);
        errorMessage = errorJson['message'] ?? errorJson.toString();
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Request failed';
      }
      
      return ApiResponse.error(
        errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  // Protected methods for subclasses
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await apiClient.get(endpoint, queryParams: queryParams);
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<T>>> getList<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await apiClient.get(endpoint, queryParams: queryParams);
      return _handleListResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      print('🚀 POST Request starting: $endpoint');
      final response = await apiClient.post(endpoint, body: body, queryParams: queryParams);
      print('✅ POST Response received: ${response.statusCode}');
      return _handleResponse(response, fromJson);
    } catch (e) {
      print('❌ POST Request failed: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final response = await apiClient.put(endpoint, body: body, queryParams: queryParams);
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<void>> delete(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final response = await apiClient.delete(endpoint, queryParams: queryParams);
      return _handleResponse<void>(response, null);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}
