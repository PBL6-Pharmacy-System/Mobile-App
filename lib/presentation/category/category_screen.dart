import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/services/category_service.dart';
import 'package:pharmacy_app/presentation/category/widgets/category_shimmer_loading.dart';
import 'package:pharmacy_app/presentation/category/main_category_detail_page.dart';
import 'package:pharmacy_app/presentation/search/search_page.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/home_screen.dart';

class CategoryScreen extends StatefulWidget {
  final int? initialCategoryId;

  const CategoryScreen({Key? key, this.initialCategoryId}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryService _categoryService = CategoryService();

  List<CategoryModel> _mainCategories = [];
  bool _isLoadingCategories = true;
  String? _categoryError;
  int _selectedCategoryIndex = 0;

  // Colors theo thiết kế
  static const Color _activeTextColor = Color(0xFF1A73E8);
  static const Color _inactiveTextColor = Color(0xFF333333);
  static const Color _tabBarBgColor = Color(0xFFF5F5F8);

  @override
  void initState() {
    super.initState();
    // Force refresh lần đầu để lấy dữ liệu mới nhất
    _loadCategories(forceRefresh: true);
  }

  /// Load categories from API /categories/tree
  Future<void> _loadCategories({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      // Force refresh để lấy dữ liệu mới nhất từ API
      var categories = await _categoryService.getAllCategories(
        forceRefresh: forceRefresh,
      );

      // Nếu cache rỗng, force refresh từ API
      if (categories.isEmpty) {
        print('📦 Cache empty, forcing refresh...');
        categories = await _categoryService.getAllCategories(
          forceRefresh: true,
        );
      }

      setState(() {
        _mainCategories = categories;
        _isLoadingCategories = false;
      });

      // Xử lý initialCategoryId nếu được truyền vào
      if (widget.initialCategoryId != null) {
        final index = _mainCategories.indexWhere(
          (cat) => cat.id == widget.initialCategoryId,
        );
        if (index != -1) {
          _selectedCategoryIndex = index;
        }
      }

      // Log tên các danh mục để debug
      for (var cat in _mainCategories) {
        print('📂 Category: ${cat.name} (ID: ${cat.id})');
      }

      print(
        '✅ CategoryScreen loaded ${_mainCategories.length} main categories',
      );
    } catch (e) {
      print('❌ CategoryScreen error: $e');
      setState(() {
        _isLoadingCategories = false;
        _categoryError = e.toString();
      });
    }
  }

  /// Navigate to main category detail page to see subcategories
  void _onMainCategoryTap(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
  }

  void _openSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: GestureDetector(
          onTap: _openSearchPage,
          child: Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search, color: Colors.grey[400], size: 18),
                const SizedBox(width: 10),
                Text(
                  'Tìm kiếm sản phẩm...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              // Navigate to cart tab
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialIndex: 2),
                ),
                (route) => false,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SvgPicture.asset(
                'assets/images/shopping-cart.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color.fromARGB(255, 26, 115, 232),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingCategories
          ? const CategoryShimmerLoading()
          : _categoryError != null
          ? _buildErrorView(_categoryError!)
          : _buildCategoryContent(),
    );
  }

  /// Build main category content - tab bar + detail content
  Widget _buildCategoryContent() {
    return Column(
      children: [
        // Category Tab Bar - thanh danh mục ngang
        _buildCategoryTabBar(),
        // Content area - hiển thị subcategories của category được chọn
        Expanded(
          child: _mainCategories.isNotEmpty
              ? MainCategoryDetailPage(
                  key: ValueKey(_mainCategories[_selectedCategoryIndex].id),
                  category: _mainCategories[_selectedCategoryIndex],
                  embedded: true,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Build category tab bar - thanh ngang scroll được
  Widget _buildCategoryTabBar() {
    return Container(
      color: _tabBarBgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Tính chiều rộng mỗi tab bằng nhau
          final tabWidth = constraints.maxWidth / _mainCategories.length;
          // Đảm bảo chiều rộng tối thiểu 100, tối đa 150
          final adjustedWidth = tabWidth.clamp(100.0, 150.0);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_mainCategories.length, (index) {
                final category = _mainCategories[index];
                final isSelected = index == _selectedCategoryIndex;
                return _buildCategoryTab(
                  category,
                  index,
                  isSelected,
                  adjustedWidth,
                );
              }),
            ),
          );
        },
      ),
    );
  }

  /// Build single category tab
  Widget _buildCategoryTab(
    CategoryModel category,
    int index,
    bool isSelected,
    double width,
  ) {
    return GestureDetector(
      onTap: () => _onMainCategoryTap(index),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? _activeTextColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          category.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? _activeTextColor : _inactiveTextColor,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _loadCategories();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
