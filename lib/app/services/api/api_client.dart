import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';

class ApiClient extends GetxService {
  // Use API URL from configuration
  static String get baseUrl => ApiConfig.baseUrl;
  static String get apiPath => ApiConfig.apiPath;
  
  final http.Client _httpClient = http.Client();
  
  // HTTP headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // GET request
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    
    try {
    final response = await _httpClient
      .get(uri, headers: _headers)
      .timeout(ApiConfig.requestTimeout);
      _logRequest('GET', uri.toString(), null, response);
      return response;
    } catch (e) {
      _logError('GET', uri.toString(), e);
      rethrow;
    }
  }

  // POST request
  Future<http.Response> post(String endpoint, {dynamic body, Map<String, String>? queryParams, Map<String, String>? customHeaders}) async {
    final uri = _buildUri(endpoint, queryParams);
    final jsonBody = body != null ? jsonEncode(body) : null;
    final headers = {..._headers};
    if (customHeaders != null) headers.addAll(customHeaders);
    
    try {
    final response = await _httpClient
      .post(uri, headers: headers, body: jsonBody)
      .timeout(ApiConfig.requestTimeout);
      _logRequest('POST', uri.toString(), jsonBody, response);
      return response;
    } catch (e) {
      _logError('POST', uri.toString(), e);
      rethrow;
    }
  }

  // PUT request
  Future<http.Response> put(String endpoint, {dynamic body, Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    final jsonBody = body != null ? jsonEncode(body) : null;
    
    try {
    final response = await _httpClient
      .put(uri, headers: _headers, body: jsonBody)
      .timeout(ApiConfig.requestTimeout);
      _logRequest('PUT', uri.toString(), jsonBody, response);
      return response;
    } catch (e) {
      _logError('PUT', uri.toString(), e);
      rethrow;
    }
  }

  // DELETE request
  Future<http.Response> delete(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    
    try {
    final response = await _httpClient
      .delete(uri, headers: _headers)
      .timeout(ApiConfig.requestTimeout);
      _logRequest('DELETE', uri.toString(), null, response);
      return response;
    } catch (e) {
      _logError('DELETE', uri.toString(), e);
      rethrow;
    }
  }

  // Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final path = '$apiPath$endpoint';
    return Uri.parse(baseUrl + path).replace(queryParameters: queryParams);
  }

  // Request logging
  void _logRequest(String method, String url, String? body, http.Response response) {
    if (ApiConfig.enableLogging && kDebugMode) {
      // Lightweight debug log to console
if (body != null && body.isNotEmpty) {
}
// Print small preview of response
      final preview = response.body.length > 300
          ? response.body.substring(0, 300) + '...'
          : response.body;
}
  }

  // Error logging
  void _logError(String method, String url, dynamic error) {
    if (ApiConfig.enableLogging && kDebugMode) {
}
  }

  // Dispose
  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }
}
