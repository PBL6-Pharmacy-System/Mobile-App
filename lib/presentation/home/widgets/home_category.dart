import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/services/category_service.dart';
import 'package:pharmacy_app/home_screen.dart';

class HomeCategory extends StatefulWidget {
  const HomeCategory({super.key});

  @override
  State<HomeCategory> createState() => _HomeCategoryState();
}

class _HomeCategoryState extends State<HomeCategory> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  CategoryModel? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Thử load từ cache trước
      var categories = await _categoryService.getAllCategories();

      // Nếu cache rỗng, force refresh từ API
      if (categories.isEmpty) {
        print('📦 Cache empty, forcing refresh...');
        categories = await _categoryService.getAllCategories(
          forceRefresh: true,
        );
      }

      setState(() {
        _categories = categories
            .take(4)
            .toList(); // Lấy 4 main categories từ API
        _isLoading = false;
      });

      print('✅ HomeCategory loaded ${_categories.length} categories');
    } catch (e) {
      print('❌ HomeCategory error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function để chọn icon phù hợp với category
  // 4 main categories từ API: Thực phẩm chức năng, Dược mỹ phẩm, Chăm sóc cá nhân, Thiết bị y tế
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Thực phẩm chức năng':
        return Icons.local_pharmacy_rounded;
      case 'Dược mỹ phẩm':
        return Icons.face_retouching_natural_rounded;
      case 'Chăm sóc cá nhân':
        return Icons.self_improvement_rounded;
      case 'Thiết bị y tế':
        return Icons.medical_services_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // Helper function để chọn màu cho icon
  // 4 main categories từ API: Thực phẩm chức năng, Dược mỹ phẩm, Chăm sóc cá nhân, Thiết bị y tế
  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'Thực phẩm chức năng':
        return const Color(0xFF4CAF50); // Xanh lá
      case 'Dược mỹ phẩm':
        return const Color(0xFFE91E63); // Hồng
      case 'Chăm sóc cá nhân':
        return const Color(0xFFFF9800); // Cam
      case 'Thiết bị y tế':
        return const Color(0xFF2196F3); // Xanh dương
      default:
        return primaryColor;
    }
  }

  void _navigateToCategory(CategoryModel category) {
    setState(() {
      selectedCategory = category;
    });

    // Delay nhỏ để người dùng thấy hiệu ứng selected
    Future.delayed(const Duration(milliseconds: 200), () {
      // Chuyển đến HomeScreen với tab Danh mục và category được chọn
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            initialIndex: 1, // Index của tab Danh mục
            initialCategoryId: category.id,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: Gap.md),
        height: 120,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Gap.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh mục sản phẩm'),
              IconButton(
                onPressed: () {
                  // Chuyển đến HomeScreen tab Danh mục
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(initialIndex: 1),
                    ),
                  );
                },
                icon: Icon(Icons.arrow_forward_ios_rounded, size: Gap.md),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _categories
                .map(
                  (e) => Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () => _navigateToCategory(e),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: selectedCategory?.name == e.name
                              ? primaryColor.withOpacity(0.15)
                              : _getCategoryColor(e.name).withOpacity(0.08),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon container - clean design
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  e.name,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getCategoryIcon(e.name),
                                size: 18,
                                color: _getCategoryColor(e.name),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Text
                            SizedBox(
                              height: 26,
                              child: Text(
                                e.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  color: selectedCategory?.name == e.name
                                      ? primaryColor
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
