import 'api/base_api_service.dart';
import 'api/api_exception.dart';
import '../data/models/api/index.dart';

class CategoryService extends BaseApiService {
  
  // Get all categories
  Future<ApiResponse<List<CategoryMaster>>> getCategories() async {
    final response = await getList<CategoryMaster>(
      '/Categories',
      fromJson: (json) => CategoryMaster.fromJson(json),
    );
    
    return response;
  }

  // Create new category
  Future<ApiResponse<CategoryMaster>> createCategory(CategoryMaster category) async {
    final response = await post<CategoryMaster>(
      '/Category',
      body: category.toJson(),
      fromJson: (json) => CategoryMaster.fromJson(json),
    );
    
    return response;
  }

  // Get category hierarchy
  Future<ApiResponse<List<dynamic>>> getCategoryHierarchy() async {
    final response = await getList<dynamic>(
      '/CategoryHierarchy',
      fromJson: (json) => json,
    );
    
    return response;
  }

  // Get social media list
  Future<ApiResponse<List<SocialMediaPlatform>>> getSocialMediaList() async {
    final response = await getList<SocialMediaPlatform>(
      '/SocialMediaList',
      fromJson: (json) => SocialMediaPlatform.fromJson(json),
    );
    
    return response;
  }

  // Ensure social media defaults
  Future<ApiResponse<void>> ensureSocialMediaDefaults() async {
    final response = await post<void>('/EnsureSocialMediaDefaults');
    return response;
  }
}
