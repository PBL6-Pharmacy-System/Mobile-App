import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/category/widgets/list_product_by_category.dart';
import 'package:pharmacy_app/services/product_service.dart';

class SubitemProductsPage extends StatefulWidget {
  final String subitemName;
  final String subcategoryName;
  final String mainCategoryName;

  const SubitemProductsPage({
    super.key,
    required this.subitemName,
    required this.subcategoryName,
    required this.mainCategoryName,
  });

  @override
  State<SubitemProductsPage> createState() => _SubitemProductsPageState();
}

class _SubitemProductsPageState extends State<SubitemProductsPage> {
  final ProductService _productService = ProductService();
  List<ProductModel> listProduct = [];
  bool isLoading = true;
  String? errorMessage;
  String sortBy = 'Bán chạy'; // Bán chạy, Giá thấp, Giá cao

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('🔵 Loading products for subitem: ${widget.subitemName}');

      // Gọi API để lấy sản phẩm theo subitem
      // Không cần truyền mainCategory vì subitem name đã đủ specific
      final products = await _productService.getProductsBySubcategory(
        widget.subitemName,
        // mainCategoryName: widget.mainCategoryName, // Bỏ filter này
        page: 1,
        limit: 100,
      );

      print('🔵 Loaded ${products.length} products');

      setState(() {
        listProduct = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('❌ Error loading products: $e');
    }
  }

  void _sortProducts() {
    setState(() {
      if (sortBy == 'Giá thấp') {
        listProduct.sort(
          (a, b) => double.parse(a.price).compareTo(double.parse(b.price)),
        );
      } else if (sortBy == 'Giá cao') {
        listProduct.sort(
          (a, b) => double.parse(b.price).compareTo(double.parse(a.price)),
        );
      } else if (sortBy == 'Bán chạy') {
        // Sắp xếp theo tên sản phẩm nếu không có trường sold_count
        listProduct.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }

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
              widget.subitemName,
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
      body: Column(
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
              padding: EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.lg),
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
                            Icons.inventory_2_rounded,
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
                                widget.subcategoryName,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isLoading
                                    ? 'Đang tải...'
                                    : '${listProduct.length} sản phẩm',
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
                ],
              ),
            ),
          ),

          // Bộ lọc và sắp xếp
          if (!isLoading && listProduct.isNotEmpty) _buildFilterSort(),

          // Danh sách sản phẩm
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Gap.md),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : errorMessage != null
                    ? Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            Gap.mdHeight,
                            Text(
                              'Đã có lỗi xảy ra',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Gap.smHeight,
                            Text(
                              errorMessage!,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Gap.mdHeight,
                            ElevatedButton(
                              onPressed: _loadProducts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : listProduct.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              Gap.mdHeight,
                              Text(
                                'Không tìm thấy sản phẩm',
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Gap.smHeight,
                              Text(
                                'Không có sản phẩm nào thuộc danh mục "${widget.subitemName}"',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Gap.mdHeight,
                          ListProductByCategory(listProduct),
                          Gap.mLHeight,
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSort() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      color: Colors.white,
      margin: EdgeInsets.only(top: Gap.sm),
      child: Row(
        children: [
          Text(
            'Sắp xếp:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          _buildSortButton('Bán chạy'),
          const SizedBox(width: 6),
          _buildSortButton('Giá thấp'),
          const SizedBox(width: 6),
          _buildSortButton('Giá cao'),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label) {
    final isSelected = sortBy == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          sortBy = label;
          _sortProducts();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
