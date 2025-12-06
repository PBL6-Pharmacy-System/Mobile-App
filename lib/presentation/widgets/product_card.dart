import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/configs/api_config.dart';
import 'package:pharmacy_app/presentation/detail_product/product_detail_page.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/provider/cart_provider.dart';
import 'package:pharmacy_app/home_screen.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAddingToCart = false;

  Future<void> _handleAddToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Kiểm tra đăng nhập
    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      _showLoginRequiredDialog();
      return;
    }

    // Kiểm tra customerId
    final customerId = authProvider.currentUser?.customerId;
    if (customerId == null) {
      _showErrorSnackbar(
        'Không tìm thấy thông tin khách hàng. Vui lòng đăng nhập lại.',
      );
      return;
    }

    // Lấy đơn vị sản phẩm mặc định
    final defaultUnit = widget.product.defaultUnit;
    if (defaultUnit == null) {
      _showErrorSnackbar('Sản phẩm không có đơn vị giá bán');
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final success = await cartProvider.addItem(
        customerId: customerId,
        productId: widget.product.id,
        productUnitId: defaultUnit.id,
        quantity: 1,
        unitPrice: double.tryParse(defaultUnit.price),
        // Thông tin để hiển thị ngay (Optimistic Update)
        productName: widget.product.name,
        productImage: widget.product.images.isNotEmpty
            ? widget.product.images.first
            : null,
        unitName: defaultUnit.unitName,
      );

      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });

        if (success) {
          _showSuccessAndNavigateToCart();
          // Tự động chuyển đến giỏ hàng sau khi thêm thành công
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _navigateToCart();
            }
          });
        } else {
          _showErrorSnackbar(
            cartProvider.error ?? 'Không thể thêm vào giỏ hàng',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
        _showErrorSnackbar(e.toString());
      }
    }
  }

  void _showSuccessAndNavigateToCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã thêm "${widget.product.name}" vào giỏ hàng',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Xem giỏ hàng',
          textColor: Colors.white,
          onPressed: () {
            _navigateToCart();
          },
        ),
      ),
    );
  }

  void _navigateToCart() {
    // Navigate to HomeScreen with cart tab selected (index 2)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(initialIndex: 2),
      ),
      (route) => false,
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: primaryColor),
            SizedBox(width: 8),
            Text('Yêu cầu đăng nhập', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text('Bạn cần đăng nhập để thêm sản phẩm vào giỏ hàng'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle image URL - check if it's already a complete URL or needs baseUrl prefix
    String imageUrl = '';
    if (widget.product.images.isNotEmpty) {
      final firstImage = widget.product.images[0];
      // If image starts with http, it's already complete
      if (firstImage.startsWith('http')) {
        imageUrl = firstImage;
      } else {
        imageUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}$firstImage';
      }
    } else if (widget.product.imageUrl != null &&
        widget.product.imageUrl!.isNotEmpty) {
      if (widget.product.imageUrl!.startsWith('http')) {
        imageUrl = widget.product.imageUrl!;
      } else {
        imageUrl =
            '${ApiConfig.baseUrl.replaceAll('/api', '')}${widget.product.imageUrl}';
      }
    }

    final displayPrice =
        widget.product.defaultUnit?.price ?? widget.product.price;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(widget.product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[50],
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[50],
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 30,
                              color: Colors.grey[300],
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[50],
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 30,
                            color: Colors.grey[300],
                          ),
                        ),
                ),
              ),

              // Product Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Unit Type
                      if (widget.product.defaultUnit != null)
                        Text(
                          widget.product.defaultUnit!.unitName,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const Spacer(),

                      // Price and Cart Button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatPrice(displayPrice),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Add to cart button với API
                          InkWell(
                            onTap: _isAddingToCart ? null : _handleAddToCart,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isAddingToCart
                                    ? primaryColor.withOpacity(0.5)
                                    : primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _isAddingToCart
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(String price) {
    try {
      final numPrice = double.parse(price);
      final formatter = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      );
      return formatter.format(numPrice);
    } catch (e) {
      return price;
    }
  }
}
