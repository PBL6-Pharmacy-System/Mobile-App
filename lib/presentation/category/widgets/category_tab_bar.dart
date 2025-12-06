import 'package:flutter/material.dart';
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/configs/constant.dart';

/// Widget hiển thị thanh tab danh mục với style underline
///
/// Tính năng:
/// - Scroll ngang nếu có nhiều danh mục
/// - Trạng thái active: underline màu xanh + font đậm
/// - Callback trả về category được chọn
/// - Dễ dàng tùy chỉnh màu sắc
class CategoryTabBar extends StatefulWidget {
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final Function(CategoryModel) onCategorySelected;
  final int? initialCategoryId;

  // Styling properties - dễ dàng tùy chỉnh
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final double? indicatorHeight;

  const CategoryTabBar({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.initialCategoryId,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.indicatorHeight,
  }) : super(key: key);

  @override
  State<CategoryTabBar> createState() => _CategoryTabBarState();
}

class _CategoryTabBarState extends State<CategoryTabBar> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _tabKeys = {};

  // Default styling values
  Color get _activeColor => widget.activeColor ?? primaryColor;
  Color get _inactiveColor => widget.inactiveColor ?? Colors.grey.shade600;
  Color get _backgroundColor => widget.backgroundColor ?? Colors.white;
  double get _indicatorHeight => widget.indicatorHeight ?? 3.0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo keys cho mỗi tab
    for (var category in widget.categories) {
      _tabKeys[category.id] = GlobalKey();
    }

    // Auto scroll đến tab được chọn ban đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTab();
    });
  }

  @override
  void didUpdateWidget(CategoryTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll đến tab mới khi selection thay đổi
    if (oldWidget.selectedCategory?.id != widget.selectedCategory?.id) {
      _scrollToSelectedTab();
    }
  }

  void _scrollToSelectedTab() {
    if (widget.selectedCategory == null) return;

    final key = _tabKeys[widget.selectedCategory!.id];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the tab
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: widget.categories.map((category) {
              return _buildTabItem(category);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(CategoryModel category) {
    final isSelected = widget.selectedCategory?.id == category.id;

    return GestureDetector(
      key: _tabKeys[category.id],
      onTap: () => widget.onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tab text
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? _activeColor : _inactiveColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: isSelected ? 0.3 : 0,
                    ),
                    child: Text(category.name),
                  ),
                  // Product count badge
                  if (category.productCount > 0) ...[
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _activeColor.withOpacity(0.15)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${category.productCount}',
                        style: TextStyle(
                          color: isSelected
                              ? _activeColor
                              : Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Underline indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: _indicatorHeight,
              width: isSelected ? 40 : 0,
              decoration: BoxDecoration(
                color: _activeColor,
                borderRadius: BorderRadius.circular(_indicatorHeight / 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
