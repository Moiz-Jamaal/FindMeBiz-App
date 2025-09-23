import 'package:get/get.dart';
import '../app/services/api/api_exception.dart';
import '../app/data/models/sponsored_content.dart';
import '../app/core/config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class DailyOfferService extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = ApiConfig.fullApiUrl;
    httpClient.timeout = ApiConfig.requestTimeout;
    httpClient.defaultContentType = 'application/json';
    super.onInit();
  }

  /// Generate QR token for current user and today's date
  String generateQRToken(int userId) {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'FindMeBiz_${userId}_${date}';
  }

  /// Get user's daily offer redemption status
  Future<ApiResponse<DailyOfferStatus>> getUserRedemptionStatus(int userId) async {
    try {
  // baseUrl already includes '/FMB'
  final response = await get('/GetUserRedemptionStatus/$userId');
      if (ApiConfig.enableLogging && kDebugMode) {
final bodyPreview = response.bodyString != null && response.bodyString!.length > 400
            ? response.bodyString!.substring(0, 400) + '...'
            : response.bodyString;
}
      
      if (response.hasError) {
        return ApiResponse<DailyOfferStatus>(
          success: false,
          message: response.statusText ?? 'Failed to get redemption status',
          statusCode: response.statusCode,
        );
      }

    final body = response.body is Map<String, dynamic>
      ? response.body as Map<String, dynamic>
      : <String, dynamic>{};
    final status = DailyOfferStatus.fromJson(body);
      return ApiResponse<DailyOfferStatus>(
        success: true,
        data: status,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<DailyOfferStatus>(
        success: false,
        message: 'Failed to get daily offer status: $e',
        statusCode: 500,
      );
    }
  }

  /// Get today's daily offer campaign using TopCampaigns API
  Future<ApiResponse<List<SponsoredContent>>> getTodaysOffer({required int userId}) async {
    try {
  // baseUrl already includes '/FMB'
  final response = await post('/TopCampaigns', {
        'userId': userId,
        'campGroup': 'daily_offer',
        'campaignCount': 1,
      });
      if (ApiConfig.enableLogging && kDebugMode) {
debugPrint('[DailyOfferService] payload: {userId: $userId, campGroup: daily_offer, campaignCount: 1}');
        final bodyPreview = response.bodyString != null && response.bodyString!.length > 400
            ? '${response.bodyString!.substring(0, 400)}...'
            : response.bodyString;
}
      
      if (response.hasError) {
        return ApiResponse<List<SponsoredContent>>(
          success: false,
          message: response.statusText ?? 'Failed to load daily offer',
          statusCode: response.statusCode,
        );
      }
      // Parse response body
      final body = response.body is Map
          ? Map<String, dynamic>.from(response.body as Map)
          : <String, dynamic>{};

      // Handle both camelCase and PascalCase from backend
      final dynamic listDyn = body['campaigns'] ?? body['Campaigns'];
      final List<dynamic> rawList = listDyn is List ? listDyn : const <dynamic>[];
      final campaigns = <SponsoredContent>[];
      for (final item in rawList) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final inner = map['campaign'] ?? map['Campaign'] ?? map;
          if (inner is Map) {
            campaigns.add(SponsoredContent.fromJson(Map<String, dynamic>.from(inner)));
          }
        }
      }

      return ApiResponse<List<SponsoredContent>>(
        success: true,
        data: campaigns,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<SponsoredContent>>(
        success: false,
        message: 'Failed to load daily offer: $e',
        statusCode: 500,
      );
    }
  }
  /// Validate QR token
  Future<ApiResponse<ValidateQRResponse>> validateQRToken({
    required String qrToken,
    int? sellerId,
    String? location,
  }) async {
    try {
  // baseUrl already includes '/FMB'
  final response = await post('/ValidateQRToken', {
        'qrToken': qrToken,
        'sellerId': sellerId,
        'location': location,
      });
      
      if (response.hasError) {
        return ApiResponse<ValidateQRResponse>(
          success: false,
          message: response.statusText ?? 'Failed to validate QR code',
          statusCode: response.statusCode,
        );
      }

      final validation = ValidateQRResponse.fromJson(response.body);
      return ApiResponse<ValidateQRResponse>(
        success: true,
        data: validation,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<ValidateQRResponse>(
        success: false,
        message: 'Failed to validate QR code: $e',
        statusCode: 500,
      );
    }
  }

  /// Check if user has redeemed today's offer
  Future<bool> hasRedeemedToday(int userId) async {
    try {
  // baseUrl already includes '/FMB'
  final response = await get('/HasRedeemedToday/$userId');
      if (ApiConfig.enableLogging && kDebugMode) {
}
      final b = response.body;
      if (b is bool) return b;
      if (b is String) return b.toLowerCase() == 'true';
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get time remaining until offer expires
  Duration getTimeUntilExpiry() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return endOfDay.difference(now);
  }

  /// Format countdown timer display
  String formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
}

// ============================================
// DAILY OFFER MODELS (matching backend)
// ============================================

class DailyOfferStatus {
  final bool hasTodaysOffer;
  final bool isRedeemed;
  final SponsoredContent? todaysOffer;
  final String? qrToken;
  final DateTime? redemptionDeadline;

  DailyOfferStatus({
    required this.hasTodaysOffer,
    required this.isRedeemed,
    this.todaysOffer,
    this.qrToken,
    this.redemptionDeadline,
  });

  factory DailyOfferStatus.fromJson(Map<String, dynamic> json) {
    bool _getBool(String a, String b) {
      final v = json[a] ?? json[b];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      if (v is num) return v != 0;
      return false;
    }

    dynamic _get(String a, String b) => json[a] ?? json[b];

    return DailyOfferStatus(
      hasTodaysOffer: _getBool('hasTodaysOffer', 'HasTodaysOffer'),
      isRedeemed: _getBool('isRedeemed', 'IsRedeemed'),
      todaysOffer: _get('todaysOffer', 'TodaysOffer') != null 
          ? SponsoredContent.fromJson((_get('todaysOffer', 'TodaysOffer')) as Map<String, dynamic>) 
          : null,
      qrToken: (_get('qrToken', 'QrToken')) as String?,
      redemptionDeadline: _get('redemptionDeadline', 'RedemptionDeadline') != null 
          ? DateTime.parse(_get('redemptionDeadline', 'RedemptionDeadline')) 
          : null,
    );
  }
}

class ValidateQRResponse {
  final bool isValid;
  final String message;
  final SponsoredContent? offer;
  final bool alreadyRedeemed;

  ValidateQRResponse({
    required this.isValid,
    required this.message,
    this.offer,
    required this.alreadyRedeemed,
  });

  factory ValidateQRResponse.fromJson(Map<String, dynamic> json) {
    return ValidateQRResponse(
      isValid: json['isValid'] ?? false,
      message: json['message'] ?? '',
      offer: json['offer'] != null 
          ? SponsoredContent.fromJson(json['offer']) 
          : null,
      alreadyRedeemed: json['alreadyRedeemed'] ?? false,
    );
  }
}
