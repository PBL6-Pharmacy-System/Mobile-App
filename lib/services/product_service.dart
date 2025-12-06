import 'package:dio/dio.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/services/api_service.dart';

/// Response model cho Best Sellers API
class BestSellersResponse {
  final List<ProductModel> products;
  final int currentPage;
  final int limit;
  final bool hasMore;
  final int total;
  final int totalPages;

  BestSellersResponse({
    required this.products,
    required this.currentPage,
    required this.limit,
    required this.hasMore,
    required this.total,
    required this.totalPages,
  });

  factory BestSellersResponse.fromJson(
    Map<String, dynamic> json,
    int page,
    int limit,
  ) {
    List<ProductModel> products = [];
    int total = 0;
    int totalPages = 1;
    bool hasMore = false;

    // Parse products từ response
    if (json['success'] == true && json['data'] != null) {
      final data = json['data'];
      if (data is List) {
        products = data.map((item) => ProductModel.fromJson(item)).toList();
      }
    }

    // Parse pagination info nếu có
    if (json['pagination'] != null) {
      final pagination = json['pagination'];
      total = pagination['total'] ?? products.length;
      totalPages = pagination['totalPages'] ?? 1;
      hasMore = pagination['hasMore'] ?? false;
    } else {
      // Fallback: hasMore = true nếu số products trả về = limit
      total = products.length;
      hasMore = products.length >= limit;
    }

    return BestSellersResponse(
      products: products,
      currentPage: page,
      limit: limit,
      hasMore: hasMore,
      total: total,
      totalPages: totalPages,
    );
  }
}

class ProductService {
  final Dio _dio = ApiService().dio;

  // Lấy tất cả sản phẩm
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await _dio.get('/products');

      if (response.statusCode == 200) {
        final data = response.data;

        // Xử lý response dựa trên cấu trúc Backend
        if (data is Map && data.containsKey('data')) {
          final innerData = data['data'];

          // Kiểm tra xem data có chứa products không
          if (innerData is Map && innerData.containsKey('products')) {
            // Response: { success: true, data: { products: [...] } }
            final List<dynamic> productList = innerData['products'];
            return productList
                .map((json) => ProductModel.fromJson(json))
                .toList();
          } else if (innerData is List) {
            // Response: { success: true, data: [...] }
            return innerData
                .map((json) => ProductModel.fromJson(json))
                .toList();
          }
        } else if (data is List) {
          // Nếu response là array trực tiếp: [...]
          return data.map((json) => ProductModel.fromJson(json)).toList();
        }
      }

      throw Exception('Không thể tải sản phẩm');
    } on DioException catch (e) {
      print('Error loading products: ${e.message}');
      print('Response: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Lấy sản phẩm theo category ID với pagination
  /// Backend API: GET /products?categoryId=X&page=Y&limit=Z&includeChildren=true/false
  Future<ProductListResponse> getProductsByCategoryWithPagination({
    required int categoryId,
    int page = 1,
    int limit = 6,
    bool includeChildren =
        true, // true: bao gồm subcategories, false: chỉ category này
  }) async {
    try {
      print(
        '🌐 Fetching products for category $categoryId (page $page, limit $limit, includeChildren: $includeChildren)',
      );

      final response = await _dio.get(
        '/products',
        queryParameters: {
          'categoryId': categoryId,
          'page': page,
          'limit': limit,
          'includeChildren': includeChildren.toString(),
        },
      );

      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        return ProductListResponse.fromJson(data);
      }

      throw Exception('Không thể tải sản phẩm');
    } on DioException catch (e) {
      print('❌ Error loading products: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Lấy sản phẩm theo category ID
  /// Backend API: GET /categories/:categoryId/products
  Future<List<ProductModel>> getProductsByCategoryId(
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
      print('🔵 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Backend trả về: { products: [...], total: 123, page: 1, limit: 20 }
        if (data is Map && data.containsKey('products')) {
          final List<dynamic> productList = data['products'];
          print('🔵 Found ${productList.length} products');
          return productList
              .map((json) => ProductModel.fromJson(json))
              .toList();
        } else if (data is Map && data.containsKey('data')) {
          final innerData = data['data'];
          if (innerData is Map && innerData.containsKey('products')) {
            final List<dynamic> productList = innerData['products'];
            return productList
                .map((json) => ProductModel.fromJson(json))
                .toList();
          }
        }
      }

      throw Exception('Không thể tải sản phẩm của category');
    } on DioException catch (e) {
      print('❌ Error loading products by category ID: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Lấy sản phẩm theo danh mục (by category ID)
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _dio.get(
        '/products',
        queryParameters: {'category_id': categoryId},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data.containsKey('data')) {
          final List<dynamic> productList = data['data'];
          return productList
              .map((json) => ProductModel.fromJson(json))
              .toList();
        } else if (data is List) {
          return data.map((json) => ProductModel.fromJson(json)).toList();
        }
      }

      throw Exception('Không thể tải sản phẩm');
    } on DioException catch (e) {
      print('Error loading products by category: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Lấy sản phẩm theo tên danh mục (từ backend API: /products/category/:categoryName)
  Future<List<ProductModel>> getProductsByCategoryName(
    String categoryName, {
    int page = 1,
    int limit = 100,
  }) async {
    try {
      print('🔵 Fetching products for category: $categoryName');

      final response = await _dio.get(
        '/products/category/$categoryName',
        queryParameters: {'page': page, 'limit': limit},
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Backend trả về: { category: {...}, products: [...], total: 123 }
        if (data.containsKey('products')) {
          final List<dynamic> productList = data['products'];
          print('🔵 Found ${productList.length} products');
          return productList
              .map((json) => ProductModel.fromJson(json))
              .toList();
        } else if (data.containsKey('data') && data['data'] is Map) {
          // Trường hợp có wrapper 'data'
          final innerData = data['data'] as Map<String, dynamic>;
          if (innerData.containsKey('products')) {
            final List<dynamic> productList = innerData['products'];
            print('🔵 Found ${productList.length} products (nested)');
            return productList
                .map((json) => ProductModel.fromJson(json))
                .toList();
          }
        }
      }

      throw Exception('Không thể tải sản phẩm của danh mục $categoryName');
    } on DioException catch (e) {
      print('❌ Error loading products by category name: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy danh mục "$categoryName"');
      }

      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Tìm kiếm sản phẩm với pagination
  /// Backend API: GET /products/search?keyword=X&page=Y&limit=Z
  Future<ProductListResponse> searchProductsWithPagination({
    required String keyword,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('🔍 Searching products: "$keyword" (page $page, limit $limit)');

      final response = await _dio.get(
        '/products/search',
        queryParameters: {'keyword': keyword, 'page': page, 'limit': limit},
      );

      print('✅ Search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        return ProductListResponse.fromJson(data);
      }

      throw Exception('Không thể tìm kiếm sản phẩm');
    } on DioException catch (e) {
      print('❌ Error searching products: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Tìm kiếm sản phẩm (legacy - không pagination)
  Future<List<ProductModel>> searchProducts(String keyword) async {
    try {
      final response = await _dio.get(
        '/products/search',
        queryParameters: {'q': keyword},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data.containsKey('data')) {
          final List<dynamic> productList = data['data'];
          return productList
              .map((json) => ProductModel.fromJson(json))
              .toList();
        } else if (data is List) {
          return data.map((json) => ProductModel.fromJson(json)).toList();
        }
      }

      throw Exception('Không thể tìm kiếm');
    } on DioException catch (e) {
      print('Error searching products: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Lấy sản phẩm theo subcategory/subitem name
  Future<List<ProductModel>> getProductsBySubcategory(
    String subcategoryName, {
    String? mainCategoryName,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      print(
        '🔵 Fetching products for subcategory: $subcategoryName (main: $mainCategoryName)',
      );

      // Encode subcategoryName để tránh lỗi với ký tự đặc biệt
      final encodedSubcategoryName = Uri.encodeComponent(subcategoryName);

      final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

      if (mainCategoryName != null) {
        queryParams['mainCategory'] = mainCategoryName;
      }

      final response = await _dio.get(
        '/products/subcategory/$encodedSubcategoryName',
        queryParameters: queryParams,
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Backend trả về: { products: [...], total: 123 }
        if (data.containsKey('products')) {
          final List<dynamic> productList = data['products'];
          print('🔵 Found ${productList.length} products');
          return productList
              .map((json) => ProductModel.fromJson(json))
              .toList();
        } else if (data.containsKey('data') && data['data'] is Map) {
          // Trường hợp có wrapper 'data'
          final innerData = data['data'] as Map<String, dynamic>;
          if (innerData.containsKey('products')) {
            final List<dynamic> productList = innerData['products'];
            print('🔵 Found ${productList.length} products (nested)');
            return productList
                .map((json) => ProductModel.fromJson(json))
                .toList();
          }
        }
      }

      throw Exception(
        'Không thể tải sản phẩm của danh mục con $subcategoryName',
      );
    } on DioException catch (e) {
      print('❌ Error loading products by subcategory: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy sản phẩm cho "$subcategoryName"');
      }

      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Lấy sản phẩm nổi bật (best sellers) với pagination
  /// Backend API: GET /products/best-sellers?limit=X&page=Y
  Future<BestSellersResponse> getBestSellers({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print('🔥 Fetching best sellers (page $page, limit $limit)');

      final response = await _dio.get(
        '/products/best-sellers',
        queryParameters: {'page': page, 'limit': limit},
      );

      print('✅ Best sellers response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        return BestSellersResponse.fromJson(data, page, limit);
      }

      throw Exception('Không thể tải sản phẩm nổi bật');
    } on DioException catch (e) {
      print('❌ Error loading best sellers: ${e.message}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Chi tiết sản phẩm
  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _dio.get('/products/$id');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('data')) {
          // Có vẻ như dữ liệu nằm trong một key 'data'
          return ProductModel.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // Trường hợp dữ liệu trả về là Map chứa ProductModel
          return ProductModel.fromJson(data);
        }
      }

      throw Exception('Không thể tải sản phẩm');
    } on DioException catch (e) {
      print('Error loading product detail: ${e.message}');
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
}
