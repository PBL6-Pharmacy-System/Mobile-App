import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/services/product_service.dart';
import 'package:pharmacy_app/presentation/detail_product/product_detail_page.dart';
import 'package:pharmacy_app/presentation/cart/widgets/add_to_cart_button.dart';

/// Page hiển thị chi tiết một danh mục chính với các subcategories
class MainCategoryDetailPage extends StatefulWidget {
  final CategoryModel category;
  final bool embedded; // Khi embedded = true, không hiển thị AppBar

  const MainCategoryDetailPage({
    super.key,
    required this.category,
    this.embedded = false,
  });

  @override
  State<MainCategoryDetailPage> createState() => _MainCategoryDetailPageState();
}

class _MainCategoryDetailPageState extends State<MainCategoryDetailPage> {
  final ProductService _productService = ProductService();

  CategoryModel? _selectedSubCategory;
  CategoryModel? _selectedItem;

  // Products cho category chính (hiện mặc định)
  List<ProductModel> _mainCategoryProducts = [];
  bool _isLoadingMainProducts = false;
  bool _isLoadingMoreMainProducts = false;
  int _mainProductPage = 1;
  bool _hasMoreMainProducts = true;

  // Products cho subcategory/item đã chọn
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;
  bool _isLoadingMore = false;
  String? _productError;
  int _currentPage = 1;
  bool _hasMoreProducts = true;

  // Trạng thái hiển thị tất cả subcategory/item
  bool _showAllSubCategories = false;
  bool _showAllItems = false;
  static const int _maxVisibleItems = 6;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load sản phẩm của category chính ngay khi vào trang
    _loadMainCategoryProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Nếu đang xem sản phẩm của subcategory/item
      if (_selectedSubCategory != null || _selectedItem != null) {
        _loadMoreProducts();
      } else {
        // Nếu đang xem sản phẩm của category chính
        _loadMoreMainCategoryProducts();
      }
    }
  }

  /// Load sản phẩm của category chính
  Future<void> _loadMainCategoryProducts({bool refresh = false}) async {
    if (_isLoadingMainProducts) return;

    if (refresh) {
      setState(() {
        _mainProductPage = 1;
        _mainCategoryProducts = [];
        _hasMoreMainProducts = true;
      });
    }

    setState(() {
      _isLoadingMainProducts = true;
    });

    try {
      print(
        '🔵 Loading products for main category: ${widget.category.name} (ID: ${widget.category.id})',
      );

      final response = await _productService
          .getProductsByCategoryWithPagination(
            categoryId: widget.category.id,
            page: _mainProductPage,
            limit: 6,
            includeChildren:
                true, // Category chính: bao gồm tất cả subcategories
          );

      print('✅ Loaded ${response.data.length} products for main category');

      setState(() {
        if (refresh || _mainProductPage == 1) {
          _mainCategoryProducts = response.data;
        } else {
          _mainCategoryProducts.addAll(response.data);
        }
        _hasMoreMainProducts = response.pagination?.hasNextPage ?? false;
        _isLoadingMainProducts = false;
      });
    } catch (e) {
      print('❌ Error loading main category products: $e');
      setState(() {
        _isLoadingMainProducts = false;
      });
    }
  }

  /// Load thêm sản phẩm category chính khi scroll
  Future<void> _loadMoreMainCategoryProducts() async {
    if (_isLoadingMoreMainProducts || !_hasMoreMainProducts) return;

    setState(() {
      _isLoadingMoreMainProducts = true;
      _mainProductPage++;
    });

    try {
      final response = await _productService
          .getProductsByCategoryWithPagination(
            categoryId: widget.category.id,
            page: _mainProductPage,
            limit: 6,
            includeChildren:
                true, // Category chính: bao gồm tất cả subcategories
          );

      setState(() {
        _mainCategoryProducts.addAll(response.data);
        _hasMoreMainProducts = response.pagination?.hasNextPage ?? false;
        _isLoadingMoreMainProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMoreMainProducts = false;
        _mainProductPage--;
      });
    }
  }

  /// Handle subcategory selection
  void _onSubCategorySelected(CategoryModel subCategory) {
    if (_selectedSubCategory?.id == subCategory.id) {
      // Toggle: đóng subcategory
      setState(() {
        _selectedSubCategory = null;
        _selectedItem = null;
        _products = [];
        _showAllItems = false; // Reset trạng thái items
      });
    } else {
      setState(() {
        _selectedSubCategory = subCategory;
        _selectedItem = null;
        _products = [];
        _currentPage = 1;
        _hasMoreProducts = true;
        _showAllItems =
            false; // Reset trạng thái items khi chọn subcategory mới
      });

      // Luôn load sản phẩm khi chọn subcategory
      _loadProductsFromSubcategory();
    }
  }

  /// Handle item selection (level 3)
  void _onItemSelected(CategoryModel item) {
    if (_selectedItem?.id == item.id) return;

    setState(() {
      _selectedItem = item;
      _currentPage = 1;
      _products = [];
      _hasMoreProducts = true;
    });

    _loadProducts();
  }

  /// Load products for selected item (level 3)
  Future<void> _loadProducts({bool refresh = false}) async {
    if (_selectedItem == null) return;

    final categoryId = _selectedItem!.id;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _products = [];
        _hasMoreProducts = true;
      });
    }

    setState(() {
      _isLoadingProducts = refresh || _currentPage == 1;
      _productError = null;
    });

    try {
      print(
        '🔵 Loading products for item: ${_selectedItem!.name} (ID: $categoryId)',
      );

      final response = await _productService.getProductsByCategoryWithPagination(
        categoryId: categoryId,
        page: _currentPage,
        limit: 6,
        includeChildren:
            false, // Item (level 3): chỉ lấy sản phẩm thuộc đúng category này
      );

      print('✅ Loaded ${response.data.length} products');

      setState(() {
        if (refresh || _currentPage == 1) {
          _products = response.data;
        } else {
          _products.addAll(response.data);
        }

        _hasMoreProducts = response.pagination?.hasNextPage ?? false;
        _isLoadingProducts = false;
      });
    } catch (e) {
      print('❌ Error loading products: $e');
      setState(() {
        _isLoadingProducts = false;
        _productError = e.toString();
      });
    }
  }

  /// Load products directly from subcategory (when no level 3 items)
  Future<void> _loadProductsFromSubcategory({bool refresh = false}) async {
    if (_selectedSubCategory == null) return;

    final categoryId = _selectedSubCategory!.id;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _products = [];
        _hasMoreProducts = true;
      });
    }

    setState(() {
      _isLoadingProducts = refresh || _currentPage == 1;
      _productError = null;
    });

    try {
      print(
        '🔵 Loading products for subcategory: ${_selectedSubCategory!.name} (ID: $categoryId)',
      );

      final response = await _productService
          .getProductsByCategoryWithPagination(
            categoryId: categoryId,
            page: _currentPage,
            limit: 6,
            includeChildren:
                true, // Subcategory (tầng 2): bao gồm cả items bên trong
          );

      print('✅ Loaded ${response.data.length} products from subcategory');

      setState(() {
        if (refresh || _currentPage == 1) {
          _products = response.data;
        } else {
          _products.addAll(response.data);
        }

        _hasMoreProducts = response.pagination?.hasNextPage ?? false;
        _isLoadingProducts = false;
      });
    } catch (e) {
      print('❌ Error loading products: $e');
      setState(() {
        _isLoadingProducts = false;
        _productError = e.toString();
      });
    }
  }

  /// Load more products when scrolling
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    // Xác định đang load từ item hay subcategory
    final bool loadFromItem = _selectedItem != null;
    final bool loadFromSubcategory = _selectedSubCategory != null;

    if (!loadFromItem && !loadFromSubcategory) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final categoryId = loadFromItem
          ? _selectedItem!.id
          : _selectedSubCategory!.id;

      final response = await _productService
          .getProductsByCategoryWithPagination(
            categoryId: categoryId,
            page: _currentPage,
            limit: 6,
            // Item (tầng 3): false, Subcategory (tầng 2): true
            includeChildren: !loadFromItem,
          );

      setState(() {
        _products.addAll(response.data);
        _hasMoreProducts = response.pagination?.hasNextPage ?? false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải thêm sản phẩm: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra có đang xem sản phẩm từ subcategory/item không
    // Hiện sản phẩm khi đã chọn subcategory hoặc item
    final bool isViewingSubProducts =
        _selectedSubCategory != null || _selectedItem != null;

    final content = SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category info (chỉ hiện khi không embedded)
          if (!widget.embedded) _buildHeader(),

          // Hiển thị subcategories HOẶC items (thay thế nhau)
          if (widget.category.children.isNotEmpty) _buildCategorySection(),

          // Products grid từ subcategory/item đã chọn
          if (isViewingSubProducts) _buildProductsSection(),

          // Products grid từ category chính (hiện khi chưa chọn subcategory/item)
          if (!isViewingSubProducts) _buildMainCategoryProductsSection(),
        ],
      ),
    );

    // Khi embedded, chỉ trả về content (không có Scaffold)
    if (widget.embedded) {
      return Container(color: Colors.grey[50], child: content);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: content,
    );
  }

  /// Section hiển thị subcategories hoặc items (thay thế nhau)
  Widget _buildCategorySection() {
    // Nếu đã chọn subcategory và subcategory có children -> hiển thị items
    if (_selectedSubCategory != null &&
        _selectedSubCategory!.children.isNotEmpty) {
      return _buildItemsSection();
    }
    // Ngược lại hiển thị subcategories
    return _buildSubCategoriesSection();
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, primaryColor.withOpacity(0.8), Colors.white],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.lg),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh mục con',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.category.children.length} loại sản phẩm',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoriesSection() {
    final allSubCategories = widget.category.children;
    final displayedSubCategories = _showAllSubCategories
        ? allSubCategories
        : allSubCategories.take(_maxVisibleItems).toList();
    final hasMore = allSubCategories.length > _maxVisibleItems;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subdirectory_arrow_right_rounded,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Chọn loại sản phẩm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grid 2 cột với các ô bằng nhau
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4.0, // Tăng tỷ lệ để giảm chiều cao
              crossAxisSpacing: 10,
              mainAxisSpacing: 8,
            ),
            itemCount: displayedSubCategories.length,
            itemBuilder: (context, index) {
              final subCat = displayedSubCategories[index];
              final isSelected = _selectedSubCategory?.id == subCat.id;
              return _buildSubCategoryChip(subCat, isSelected);
            },
          ),
          // Nút xem thêm
          if (hasMore && !_showAllSubCategories)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAllSubCategories = true;
                    });
                  },
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(
                    'Xem thêm (${allSubCategories.length - _maxVisibleItems})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                ),
              ),
            ),
          // Nút thu gọn
          if (_showAllSubCategories && hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAllSubCategories = false;
                    });
                  },
                  icon: const Icon(Icons.expand_less, size: 18),
                  label: const Text('Thu gọn', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryChip(CategoryModel subCategory, bool isSelected) {
    return GestureDetector(
      onTap: () => _onSubCategorySelected(subCategory),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[400]!,
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              subCategory.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    final allItems = _selectedSubCategory!.children;
    final displayedItems = _showAllItems
        ? allItems
        : allItems.take(_maxVisibleItems).toList();
    final hasMore = allItems.length > _maxVisibleItems;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với nút quay lại
          Row(
            children: [
              // Nút quay lại subcategories
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSubCategory = null;
                    _selectedItem = null;
                    _products = [];
                    _showAllItems = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedSubCategory!.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grid 2 cột với các ô bằng nhau
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4.0, // Tăng tỷ lệ để giảm chiều cao
              crossAxisSpacing: 10,
              mainAxisSpacing: 8,
            ),
            itemCount: displayedItems.length,
            itemBuilder: (context, index) {
              final item = displayedItems[index];
              final isSelected = _selectedItem?.id == item.id;
              return _buildItemChip(item, isSelected);
            },
          ),
          // Nút xem thêm
          if (hasMore && !_showAllItems)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAllItems = true;
                    });
                  },
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(
                    'Xem thêm (${allItems.length - _maxVisibleItems})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                ),
              ),
            ),
          // Nút thu gọn
          if (_showAllItems && hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAllItems = false;
                    });
                  },
                  icon: const Icon(Icons.expand_less, size: 18),
                  label: const Text('Thu gọn', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemChip(CategoryModel item, bool isSelected) {
    return GestureDetector(
      onTap: () => _onItemSelected(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[400]!,
            width: isSelected ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    final String categoryName;
    if (_selectedItem != null) {
      categoryName = _selectedItem!.name;
    } else if (_selectedSubCategory != null) {
      categoryName = _selectedSubCategory!.name;
    } else {
      categoryName = 'Sản phẩm';
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.inventory_2_rounded, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sản phẩm - $categoryName',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildProductsContent(),
        ],
      ),
    );
  }

  /// Section hiển thị sản phẩm của category chính
  Widget _buildMainCategoryProductsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.inventory_2_rounded, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sản phẩm - ${widget.category.name}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildMainCategoryProductsContent(),
        ],
      ),
    );
  }

  /// Nội dung sản phẩm của category chính
  Widget _buildMainCategoryProductsContent() {
    if (_isLoadingMainProducts && _mainCategoryProducts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_mainCategoryProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Không có sản phẩm nào',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _mainCategoryProducts.length,
          itemBuilder: (context, index) {
            return _buildProductCard(_mainCategoryProducts[index]);
          },
        ),
        if (_isLoadingMoreMainProducts)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (!_hasMoreMainProducts && _mainCategoryProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Đã hiển thị tất cả sản phẩm',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductsContent() {
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_productError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Đã xảy ra lỗi',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                _productError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Không có sản phẩm nào',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio:
                0.55, // Giảm để có thêm không gian cho nút thêm giỏ hàng
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(_products[index]);
          },
        ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (!_hasMoreProducts && _products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Đã hiển thị tất cả sản phẩm',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final bool isOutOfStock = product.isOutOfStock;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailPage(product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Opacity(
              opacity: isOutOfStock ? 0.5 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: Colors.grey[300],
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.medication_rounded,
                              size: 40,
                              color: Colors.grey[300],
                            ),
                    ),
                  ),
                  // Product info + Add to cart button
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Price
                          Text(
                            _formatPrice(product.price),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isOutOfStock ? Colors.grey : primaryColor,
                            ),
                          ),
                          if (product.unittype.name.isNotEmpty)
                            Text(
                              '/${product.unittype.name}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          const Spacer(),
                          // Add to cart button hoặc Out of stock
                          SizedBox(
                            width: double.infinity,
                            child: isOutOfStock
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Hết hàng',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : AddToCartButton(
                                    product: product,
                                    quantity: 1,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Out of stock badge
            if (isOutOfStock)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Hết hàng',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(String priceString) {
    final price = double.tryParse(priceString) ?? 0;
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '${formatted}đ';
  }
}
