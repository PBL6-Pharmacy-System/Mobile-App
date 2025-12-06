import 'package:flutter/material.dart';
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  // State
  List<ProductModel> _products = [];
  List<ProductModel> _bestSellers = [];
  List<CategoryModel> _categories = [];
  ProductModel? _selectedProduct;

  bool _isLoading = false;
  bool _isLoadingBestSellers = false;
  bool _isLoadingMoreBestSellers = false;
  bool _isLoadingCategories = false;
  String? _error;

  // Pagination state for best sellers
  int _bestSellersPage = 1;
  bool _hasMoreBestSellers = true;
  static const int _bestSellersLimit = 10;

  // Cache management - tránh gọi API lặp lại
  DateTime? _lastBestSellersLoadTime;
  DateTime? _lastProductsLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get bestSellers => _bestSellers;
  List<CategoryModel> get categories => _categories;
  ProductModel? get selectedProduct => _selectedProduct;

  bool get isLoading => _isLoading;
  bool get isLoadingBestSellers => _isLoadingBestSellers;
  bool get isLoadingMoreBestSellers => _isLoadingMoreBestSellers;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get hasMoreBestSellers => _hasMoreBestSellers;
  String? get error => _error;

  /// Kiểm tra cache còn valid không
  bool _isCacheValid(DateTime? lastLoadTime) {
    if (lastLoadTime == null) return false;
    return DateTime.now().difference(lastLoadTime) < _cacheValidDuration;
  }

  /// Fetch all products
  Future<void> fetchProducts({String? categoryId, String? search}) async {
    // Nếu không có filter và cache còn valid, không gọi API lại
    if (categoryId == null &&
        search == null &&
        _products.isNotEmpty &&
        _isCacheValid(_lastProductsLoadTime)) {
      print(
        '📦 [ProductProvider] Using cached products (${_products.length} items)',
      );
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (search != null && search.isNotEmpty) {
        _products = await _productService.searchProducts(search);
      } else if (categoryId != null) {
        _products = await _productService.getProductsByCategory(categoryId);
      } else {
        _products = await _productService.getAllProducts();
        _lastProductsLoadTime =
            DateTime.now(); // Cập nhật cache time cho all products
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ [ProductProvider] Fetch products error: $e');
      _error = 'Không thể tải sản phẩm';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch best sellers (sản phẩm bán chạy) - Load trang đầu tiên
  Future<void> fetchBestSellers({bool refresh = false}) async {
    // Nếu không refresh và cache còn valid, không gọi API lại
    if (!refresh &&
        _bestSellers.isNotEmpty &&
        _isCacheValid(_lastBestSellersLoadTime)) {
      print(
        '📦 [ProductProvider] Using cached best sellers (${_bestSellers.length} items)',
      );
      return;
    }

    if (refresh) {
      _bestSellersPage = 1;
      _hasMoreBestSellers = true;
      _bestSellers = [];
    }

    _isLoadingBestSellers = true;
    _error = null;
    notifyListeners();

    try {
      print(
        '🔥 [ProductProvider] Fetching best sellers page $_bestSellersPage',
      );

      final response = await _productService.getBestSellers(
        page: _bestSellersPage,
        limit: _bestSellersLimit,
      );

      _bestSellers = response.products;
      _hasMoreBestSellers = response.hasMore;
      _bestSellersPage = 1;
      _lastBestSellersLoadTime = DateTime.now(); // Cập nhật cache time

      print(
        '✅ [ProductProvider] Loaded ${_bestSellers.length} best sellers, hasMore: $_hasMoreBestSellers',
      );

      _isLoadingBestSellers = false;
      notifyListeners();
    } catch (e) {
      print('❌ [ProductProvider] Fetch best sellers error: $e');
      _error = 'Không thể tải sản phẩm nổi bật';
      _isLoadingBestSellers = false;
      notifyListeners();
    }
  }

  /// Load more best sellers (tải thêm khi cuộn)
  Future<void> loadMoreBestSellers() async {
    // Không load nếu đang loading hoặc không còn data
    if (_isLoadingMoreBestSellers || !_hasMoreBestSellers) {
      print(
        '⏸️ [ProductProvider] Skip loadMore: loading=$_isLoadingMoreBestSellers, hasMore=$_hasMoreBestSellers',
      );
      return;
    }

    _isLoadingMoreBestSellers = true;
    notifyListeners();

    try {
      final nextPage = _bestSellersPage + 1;
      print('🔥 [ProductProvider] Loading more best sellers page $nextPage');

      final response = await _productService.getBestSellers(
        page: nextPage,
        limit: _bestSellersLimit,
      );

      if (response.products.isNotEmpty) {
        // Lọc duplicate products
        final existingIds = _bestSellers.map((p) => p.id).toSet();
        final newProducts = response.products
            .where((p) => !existingIds.contains(p.id))
            .toList();

        _bestSellers = [..._bestSellers, ...newProducts];
        _bestSellersPage = nextPage;
        _hasMoreBestSellers = response.hasMore && newProducts.isNotEmpty;

        print(
          '✅ [ProductProvider] Added ${newProducts.length} new products, total: ${_bestSellers.length}',
        );
      } else {
        _hasMoreBestSellers = false;
        print('✅ [ProductProvider] No more best sellers');
      }

      _isLoadingMoreBestSellers = false;
      notifyListeners();
    } catch (e) {
      print('❌ [ProductProvider] Load more best sellers error: $e');
      _isLoadingMoreBestSellers = false;
      notifyListeners();
    }
  }

  /// Fetch categories
  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    notifyListeners();

    try {
      // TODO: Implement CategoryService to fetch categories from backend
      // Tạm thời để trống
      _categories = [];

      _isLoadingCategories = false;
      notifyListeners();
    } catch (e) {
      print('❌ [ProductProvider] Fetch categories error: $e');
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// Search products
  Future<void> searchProducts(String keyword) async {
    if (keyword.isEmpty) {
      await fetchProducts();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.searchProducts(keyword);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ [ProductProvider] Search products error: $e');
      _error = 'Không thể tìm kiếm sản phẩm';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get product detail by ID
  Future<void> fetchProductById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _productService.getProductById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ [ProductProvider] Fetch product detail error: $e');
      _error = 'Không thể tải chi tiết sản phẩm';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }
}
