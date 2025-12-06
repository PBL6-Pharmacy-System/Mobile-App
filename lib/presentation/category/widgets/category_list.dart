import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
// import 'package:pharmacy_app/fake_data.dart'; // REMOVED - Using API now
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/services/category_service.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key, required this.onTap});

  final Function(CategoryModel category) onTap;

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _categories = categories;
        _selectedCategory = categories.isNotEmpty ? categories[0] : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function để chọn icon phù hợp với category
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Thực phẩm chức năng':
        return Icons.food_bank;
      case 'Dược mỹ phẩm':
        return Icons.face;
      case 'Thuốc':
        return Icons.medication;
      case 'Chăm sóc cá nhân':
        return Icons.self_improvement;
      case 'Thiết bị y tế':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(child: Text('Không có danh mục'));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _categories
            .map(
              (e) => Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () {
                    widget.onTap.call(e);
                    setState(() {
                      _selectedCategory = e;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius16,
                      color: e.id == _selectedCategory?.id
                          ? primaryColor
                          : Colors.transparent,
                    ),
                    padding: EdgeInsets.all(Gap.sm),
                    child: Column(
                      spacing: Gap.md,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          _getCategoryIcon(e.name),
                          size: Gap.xl,
                          color: e.id == _selectedCategory?.id
                              ? Colors.white
                              : primaryColor,
                        ),
                        Text(
                          e.name,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: e.id == _selectedCategory?.id
                                ? Colors.white
                                : Colors.black,
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
    );
  }
}
