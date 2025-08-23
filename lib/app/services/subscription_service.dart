import 'api/base_api_service.dart';
import 'api/api_exception.dart';
import '../data/models/api/index.dart';

class SubscriptionService extends BaseApiService {
  
  // Get all subscriptions
  Future<ApiResponse<List<SubscriptionMaster>>> getSubscriptions() async {
    final response = await getList<SubscriptionMaster>(
      '/Subscriptions',
      fromJson: (json) => SubscriptionMaster.fromJson(json),
    );
    
    return response;
  }

  // Get subscription by ID
  Future<ApiResponse<SubscriptionMaster>> getSubscription(int id) async {
    final response = await get<SubscriptionMaster>(
      '/Subscription/$id',
      fromJson: (json) => SubscriptionMaster.fromJson(json),
    );
    
    return response;
  }

  // Create new subscription
  Future<ApiResponse<SubscriptionMaster>> createSubscription(SubscriptionMaster subscription) async {
    final response = await post<SubscriptionMaster>(
      '/Subscription',
      body: subscription.toJson(),
      fromJson: (json) => SubscriptionMaster.fromJson(json),
    );
    
    return response;
  }

  // Update subscription
  Future<ApiResponse<void>> updateSubscription(SubscriptionMaster subscription) async {
    if (subscription.subid == null) {
      return ApiResponse.error('Subscription ID is required for update');
    }
    
    final response = await put<void>(
      '/Subscription/${subscription.subid}',
      body: subscription.toJson(),
    );
    
    return response;
  }

  // Delete subscription
  Future<ApiResponse<void>> deleteSubscription(int id) async {
    final response = await delete('/Subscription/$id');
    return response;
  }

  // Ensure basic subscription exists
  Future<ApiResponse<SubscriptionMaster>> ensureBasicSubscription() async {
    final response = await post<SubscriptionMaster>(
      '/EnsureBasicSubscription',
      fromJson: (json) => SubscriptionMaster.fromJson(json),
    );
    
    return response;
  }
}
