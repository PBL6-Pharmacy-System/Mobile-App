import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  final Dio _dio = ApiService().dio;

  static const String _categoryCacheKey = 'cached_categories';
  static const String _categoryCacheTimeKey = 'cached_categories_time';
  static const Duration _cacheExpiration = Duration(hours: 24);

  /// Lấy toàn bộ cây categories với caching support
  /// Cache expires sau 24 giờ để tối ưu hiệu suất
  /// Backend API: GET /categories/tree
  Future<List<CategoryModel>> getAllCategories({
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache trước nếu không force refresh
      if (!forceRefresh) {
        final cachedData = await _getCachedCategories();
        if (cachedData != null) {
          print('📦 Loaded categories from cache');
          return cachedData;
        }
      }

      print('🌐 Fetching category tree from API...');

      final response = await _dio.get('/categories/tree');

      print('🔵 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        List<CategoryModel> categories = [];

        // Xử lý cấu trúc response từ backend
        if (data is Map && data.containsKey('data')) {
          final List<dynamic> categoryList = data['data'];
          print('✅ Found ${categoryList.length} categories');
          categories = categoryList
              .map((json) => CategoryModel.fromJson(json))
              .toList();
        } else if (data is List) {
          // Nếu backend trả về array trực tiếp
          print('✅ Found ${data.length} categories (direct array)');
          categories = data
              .map((json) => CategoryModel.fromJson(json))
              .toList();
        }

        // Cache dữ liệu
        await _cacheCategories(categories);

        return categories;
      }

      throw Exception('Không thể tải danh mục');
    } on DioException catch (e) {
      print('❌ Error loading categories: ${e.message}');

      // Thử trả về cached data kể cả khi hết hạn nếu có lỗi
      final cachedData = await _getCachedCategories(ignoreExpiration: true);
      if (cachedData != null) {
        print('📦 Returning expired cache due to error');
        return cachedData;
      }

      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');

      // Thử trả về cached data
      final cachedData = await _getCachedCategories(ignoreExpiration: true);
      if (cachedData != null) {
        return cachedData;
      }

      throw Exception('Lỗi không xác định: $e');
    }
  }

  /// Lấy thông tin chi tiết của 1 category theo ID
  /// Backend API: GET /categories/:id
  Future<CategoryModel> getCategoryById(int id) async {
    try {
      print('🔵 Fetching category ID: $id');

      final response = await _dio.get('/categories/$id');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data.containsKey('data')) {
          return CategoryModel.fromJson(data['data'] as Map<String, dynamic>);
        } else if (data is Map) {
          return CategoryModel.fromJson(data as Map<String, dynamic>);
        }
      }

      throw Exception('Không thể tải danh mục');
    } on DioException catch (e) {
      print('❌ Error loading category: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  /// Lấy sản phẩm của một category
  /// Backend API: GET /categories/:id/products
  /// Parameters:
  /// - categoryId: ID của category
  /// - page: Số trang (mặc định = 1)
  /// - limit: Số sản phẩm mỗi trang (mặc định = 20)
  /// - includeChildren: Có bao gồm sản phẩm của subcategories không (mặc định = true)
  Future<Map<String, dynamic>> getCategoryProducts(
    int categoryId, {
    int page = 1,
    int limit = 20,
    bool includeChildren = true,
  }) async {
    try {
      print('🔵 Fetching products for category ID: $categoryId');

      final response = await _dio.get(
        '/categories/$categoryId/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          'includeChildren': includeChildren,
        },
      );

      print('🔵 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Không thể tải sản phẩm');
    } on DioException catch (e) {
      print('❌ Error loading category products: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  String _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Kết nối quá thời gian chờ';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến server. Kiểm tra kết nối mạng.';
    } else if (error.type == DioExceptionType.badResponse) {
      return 'Lỗi từ server: ${error.response?.statusCode}';
    }
    return 'Đã có lỗi xảy ra: ${error.message}';
  }

  /// Cache categories to SharedPreferences
  Future<void> _cacheCategories(List<CategoryModel> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        categories.map((cat) => cat.toJson()).toList(),
      );

      await prefs.setString(_categoryCacheKey, jsonString);
      await prefs.setInt(
        _categoryCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      print('💾 Categories cached successfully');
    } catch (e) {
      print('⚠️ Failed to cache categories: $e');
    }
  }

  /// Get cached categories from SharedPreferences
  Future<List<CategoryModel>?> _getCachedCategories({
    bool ignoreExpiration = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_categoryCacheKey);
      final cacheTime = prefs.getInt(_categoryCacheTimeKey);

      if (jsonString == null || cacheTime == null) {
        return null;
      }

      // Check expiration
      if (!ignoreExpiration) {
        final cachedDate = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final now = DateTime.now();

        if (now.difference(cachedDate) > _cacheExpiration) {
          print('⏰ Cache expired');
          return null;
        }
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('⚠️ Failed to read cache: $e');
      return null;
    }
  }

  /// Clear category cache (hữu ích cho manual refresh)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_categoryCacheKey);
      await prefs.remove(_categoryCacheTimeKey);
      print('🗑️ Category cache cleared');
    } catch (e) {
      print('⚠️ Failed to clear cache: $e');
    }
  }

  /// Check if cache exists and is valid
  Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoryCacheKey);
    final cacheTime = prefs.getInt(_categoryCacheTimeKey);

    if (jsonString == null || cacheTime == null) {
      return false;
    }

    final cachedDate = DateTime.fromMillisecondsSinceEpoch(cacheTime);
    final now = DateTime.now();

    return now.difference(cachedDate) <= _cacheExpiration;
  }
}
