import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/sub_category_model.dart';
import 'package:pharmacy_app/presentation/category/subitem_products_page.dart';

class SubcategoryDetailPage extends StatefulWidget {
  final SubCategoryModel subCategory;
  final String mainCategoryName;

  const SubcategoryDetailPage({
    super.key,
    required this.subCategory,
    required this.mainCategoryName,
  });

  @override
  State<SubcategoryDetailPage> createState() => _SubcategoryDetailPageState();
}

class _SubcategoryDetailPageState extends State<SubcategoryDetailPage> {
  String? selectedSubItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.mainCategoryName,
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.subCategory.name,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: widget.subCategory.subItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header với gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      Gap.md,
                      Gap.md,
                      Gap.md,
                      Gap.lg,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Gap.md,
                            vertical: Gap.sm,
                          ),
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
                                      'Danh mục sản phẩm',
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${widget.subCategory.subItems.length} loại sản phẩm',
                                      style: context.textTheme.titleSmall
                                          ?.copyWith(
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
                      ],
                    ),
                  ),
                ),

                // List of subcategories
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: Gap.md,
                      vertical: Gap.sm,
                    ),
                    itemCount: widget.subCategory.subItems.length,
                    itemBuilder: (context, index) {
                      final subItem = widget.subCategory.subItems[index];
                      final isSelected = selectedSubItem == subItem;

                      return Padding(
                        padding: EdgeInsets.only(bottom: Gap.sm),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedSubItem = isSelected ? null : subItem;
                            });

                            // Navigate to subitem products page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubitemProductsPage(
                                  subitemName: subItem,
                                  subcategoryName: widget.subCategory.name,
                                  mainCategoryName: widget.mainCategoryName,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(Gap.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey[200]!,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? primaryColor.withOpacity(0.15)
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: Offset(0, isSelected ? 3 : 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Số thứ tự
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              primaryColor,
                                              primaryColor.withOpacity(0.7),
                                            ],
                                          )
                                        : null,
                                    color: isSelected ? null : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.1)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.medical_services,
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.grey[500],
                                    size: 20,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Text
                                Expanded(
                                  child: Text(
                                    subItem,
                                    style: context.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 14,
                                          height: 1.3,
                                        ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Arrow or check icon
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_ios_rounded,
                                    key: ValueKey(isSelected),
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.grey[400],
                                    size: isSelected ? 24 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Note ở bottom
                Container(
                  padding: EdgeInsets.all(Gap.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chọn danh mục để xem sản phẩm',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[300]),
          Gap.mdHeight,
          Text(
            'Chưa có danh mục con',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Gap.smHeight,
          Text(
            'Danh mục này chưa có phân loại chi tiết',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
