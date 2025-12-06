import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/formatter.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/cart/cart_page.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/provider/cart_provider.dart';
import 'package:pharmacy_app/services/product_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage(this.product, {super.key});
  final ProductModel product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  ProductUnit? _selectedUnit;
  bool _isAddingToCart = false;
  bool _isLoading = true;
  ProductModel? _productDetail;
  String? _error;
  int _currentImageIndex = 0;

  final ProductService _productService = ProductService();

  /// Loại bỏ các thẻ HTML và decode HTML entities, giữ lại format đoạn văn
  String _stripHtmlTags(String htmlString) {
    if (htmlString.isEmpty) return '';

    String result = htmlString;

    // Thay thế các thẻ block-level bằng xuống dòng để giữ format
    result = result
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</tr>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n');

    // Loại bỏ các thẻ HTML còn lại
    final RegExp htmlTagRegExp = RegExp(r'<[^>]*>', multiLine: true);
    result = result.replaceAll(htmlTagRegExp, '');

    // Decode các HTML entities phổ biến
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&ndash;', '–')
        .replaceAll('&mdash;', '—')
        .replaceAll('&hellip;', '...')
        .replaceAll('&bull;', '•')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™')
        .replaceAll('&deg;', '°')
        .replaceAll('&plusmn;', '±')
        .replaceAll('&times;', '×')
        .replaceAll('&divide;', '÷')
        .replaceAll('&frac12;', '½')
        .replaceAll('&frac14;', '¼')
        .replaceAll('&frac34;', '¾');

    // Decode numeric HTML entities (&#xxx;)
    final RegExp numericEntityRegExp = RegExp(r'&#(\d+);');
    result = result.replaceAllMapped(numericEntityRegExp, (match) {
      final code = int.tryParse(match.group(1) ?? '');
      if (code != null) {
        return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    });

    // Decode hex HTML entities (&#xXXX;)
    final RegExp hexEntityRegExp = RegExp(r'&#x([0-9a-fA-F]+);');
    result = result.replaceAllMapped(hexEntityRegExp, (match) {
      final code = int.tryParse(match.group(1) ?? '', radix: 16);
      if (code != null) {
        return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    });

    // Loại bỏ khoảng trắng thừa trong mỗi dòng (giữ lại xuống dòng)
    final lines = result.split('\n');
    result = lines
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .join('\n');

    // Thay thế nhiều dòng trống liên tiếp bằng một dòng
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Loại bỏ dòng trống ở đầu và cuối
    result = result.trim();

    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final product = await _productService.getProductById(widget.product.id);
      setState(() {
        _productDetail = product;
        _selectedUnit = product.defaultUnit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to passed product
        _productDetail = widget.product;
        _selectedUnit = widget.product.defaultUnit;
      });
    }
  }

  ProductModel get _product => _productDetail ?? widget.product;

  double get _currentPrice {
    if (_selectedUnit != null) {
      return double.tryParse(_selectedUnit!.price) ?? 0;
    }
    return double.tryParse(_product.price) ?? 0;
  }

  Future<bool> _addToCart({bool showSuccessMessage = true}) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (!authProvider.isLoggedIn ||
        authProvider.currentUser?.customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đơn vị sản phẩm'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    setState(() => _isAddingToCart = true);

    try {
      final success = await cartProvider.addItem(
        customerId: authProvider.currentUser!.customerId!,
        productId: _product.id,
        productUnitId: _selectedUnit!.id,
        quantity: _quantity,
        unitPrice: _currentPrice,
        // Thông tin để hiển thị ngay (Optimistic Update)
        productName: _product.name,
        productImage: _product.images.isNotEmpty ? _product.images.first : null,
        unitName: _selectedUnit!.unitName,
      );

      setState(() => _isAddingToCart = false);

      if (success && showSuccessMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${_product.name} vào giỏ hàng'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Xem giỏ',
              textColor: Colors.white,
              onPressed: () => _goToCart(),
            ),
          ),
        );
      } else if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cartProvider.error ?? 'Không thể thêm vào giỏ hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return success;
    } catch (e) {
      setState(() => _isAddingToCart = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : CustomScrollView(
              slivers: [
                // App Bar với hình ảnh
                _buildSliverAppBar(),

                // Nội dung chi tiết
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Thông tin cơ bản
                      _buildBasicInfo(),

                      // Chọn đơn vị
                      if (_product.productUnits.isNotEmpty)
                        _buildUnitSelector(),

                      // Thông tin chi tiết
                      _buildDetailSections(),

                      // FAQ
                      if (_product.faq.isNotEmpty) _buildFAQSection(),

                      // Khoảng trống cho bottom bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading ? null : _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    final images = _product.images.isNotEmpty
        ? _product.images
        : (_product.imageUrl?.isNotEmpty == true ? [_product.imageUrl!] : []);

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: primaryColor,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: primaryColor, size: 20),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: primaryColor, size: 20),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? Stack(
                children: [
                  // Image slider
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.medical_services,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  // Indicator
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          return Container(
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? primaryColor
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.medical_services,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Danh mục - hiển thị đầu tiên
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _product.category.name,
              style: TextStyle(color: primaryColor, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Tên sản phẩm
          Text(
            _product.name,
            style: context.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Giá
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatter.formatCurrency(_currentPrice),
                style: context.textTheme.titleLarge?.copyWith(
                  color: primaryColor,
                  fontSize: 22,
                ),
              ),
              if (_selectedUnit != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '/ ${_selectedUnit!.unitName}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Divider
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 16),

          // Thông tin thương hiệu, nhà sản xuất
          _buildInfoRow('Thương hiệu', _stripHtmlTags(_product.brand)),
          _buildInfoRow('Nhà sản xuất', _stripHtmlTags(_product.manufacturer)),
          _buildInfoRow('Nơi sản xuất', _stripHtmlTags(_product.producer)),
          _buildInfoRow('Số đăng ký', _stripHtmlTags(_product.registNum)),

          // Cần đơn thuốc
          if (_product.prescriptionRequired)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sản phẩm cần đơn thuốc từ bác sĩ',
                      style: TextStyle(color: Colors.orange[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    if (_product.productUnits.length <= 1) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn quy cách',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _product.productUnits.map((unit) {
              final isSelected = _selectedUnit?.id == unit.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedUnit = unit),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withOpacity(0.08)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        unit.unitName,
                        style: TextStyle(
                          color: isSelected ? primaryColor : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatter.formatCurrency(
                          double.tryParse(unit.price) ?? 0,
                        ),
                        style: TextStyle(
                          color: isSelected ? primaryColor : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSections() {
    return Column(
      children: [
        // Mô tả sản phẩm
        _buildExpandableSection(
          title: 'Mô tả sản phẩm',
          icon: Icons.description_outlined,
          content: _stripHtmlTags(_product.description),
          initiallyExpanded: true,
        ),

        // Thành phần
        _buildExpandableSection(
          title: 'Thành phần',
          icon: Icons.science_outlined,
          content: _stripHtmlTags(_product.specification),
        ),

        // Công dụng / Hướng dẫn sử dụng
        _buildExpandableSection(
          title: 'Công dụng',
          icon: Icons.medical_information_outlined,
          content: _stripHtmlTags(_product.usage),
        ),

        // Liều dùng
        _buildExpandableSection(
          title: 'Liều dùng',
          icon: Icons.schedule_outlined,
          content: _stripHtmlTags(_product.dosage),
        ),

        // Tác dụng phụ
        _buildExpandableSection(
          title: 'Tác dụng phụ',
          icon: Icons.warning_outlined,
          content: _stripHtmlTags(_product.adverseEffect),
        ),

        // Thông tin pháp lý
        if (_product.legalDeclaration?.isNotEmpty == true)
          _buildExpandableSection(
            title: 'Thông tin pháp lý',
            icon: Icons.gavel_outlined,
            content: _stripHtmlTags(_product.legalDeclaration ?? ''),
          ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required String content,
    bool initiallyExpanded = false,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: primaryColor, size: 20),
          title: Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildFormattedText(content),
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị text đã format với các đoạn văn và bullet points
  Widget _buildFormattedText(String content) {
    // Tách content thành các đoạn
    final paragraphs = content
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return Text(
        content,
        style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.6),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final index = entry.key;
        final paragraph = entry.value.trim();
        final isBullet = paragraph.startsWith('•') || paragraph.startsWith('-');

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < paragraphs.length - 1 ? 8 : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBullet) ...[
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7, right: 8),
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    paragraph.replaceFirst(RegExp(r'^[•\-]\s*'), ''),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: Text(
                    paragraph,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Câu hỏi thường gặp',
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._product.faq.map((faq) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _stripHtmlTags(faq.question),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      _stripHtmlTags(faq.answer),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.remove,
                        size: 18,
                        color: _quantity > 1
                            ? Colors.grey[700]
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$_quantity',
                      style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _quantity++),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.add, size: 18, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Nút thêm giỏ hàng
            Expanded(
              child: ButtonApp(
                onPressed: _isAddingToCart ? null : () => _addToCart(),
                child: _isAddingToCart
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text('Thêm vào giỏ'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
