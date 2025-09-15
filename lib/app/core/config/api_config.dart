// API Configuration
// Update this file with your actual API URLs

import 'package:flutter/foundation.dart';

class ApiConfig {
  // *** UPDATE THIS WITH YOUR ACTUAL API URL ***
  // Example: 'https://your-domain.com' or 'http://localhost:5000' for local development
  static const String baseUrl = kDebugMode ? 'http://localhost:5002' : 'https://gaqyd2vyo7.execute-api.us-east-1.amazonaws.com/Prod/';

  // If you're running the API locally for development, use:
  // static const String baseUrl = 'http://localhost:5000'; 
  // or whatever port your .NET API is running on
  
  // For production, use your deployed API URL:
  // static const String baseUrl = 'https://your-production-api.com';
  
  // The API path (this matches your controller route)
  static const String apiPath = '/FMB';
  
  // Full API base URL
  static String get fullApiUrl => baseUrl + apiPath;
  
  // Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 45);
  
  // Enable/disable API logging for debugging
  static const bool enableLogging = true;
}

// Usage Notes:
// 1. Update the baseUrl above with your actual API URL
// 2. For local development, you might use: http://localhost:5000
// 3. For production, use your deployed domain
// 4. Make sure your API is running and accessible from the Flutter app
