import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/formatter.dart';
import 'package:pharmacy_app/models/flash_sale_product_model.dart';
import 'package:pharmacy_app/presentation/detail_product/product_detail_page.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/provider/cart_provider.dart';
import 'package:pharmacy_app/home_screen.dart';
import 'package:provider/provider.dart';

class FlashSaleItem extends StatefulWidget {
  const FlashSaleItem(this.product, {super.key});

  final FlashSaleProductModel product;

  @override
  State<FlashSaleItem> createState() => _FlashSaleItemState();
}

class _FlashSaleItemState extends State<FlashSaleItem> {
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

    // Lấy product info
    final productId = widget.product.productId ?? widget.product.id;
    if (productId == null) {
      _showErrorSnackbar('Không tìm thấy thông tin sản phẩm');
      return;
    }

    // Lấy đơn vị sản phẩm mặc định
    final defaultUnit = widget.product.defaultUnit;
    final productUnitId = widget.product.productUnitId ?? defaultUnit?.id;

    if (productUnitId == null) {
      _showErrorSnackbar('Sản phẩm không có đơn vị giá bán');
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final success = await cartProvider.addItem(
        customerId: customerId,
        productId: productId,
        productUnitId: productUnitId,
        quantity: 1,
        unitPrice: widget.product.salePrice,
        // Thông tin để hiển thị ngay (Optimistic Update)
        productName: widget.product.name,
        productImage: widget.product.image,
        unitName: defaultUnit?.unitName ?? '',
      );

      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });

        if (success) {
          _showSuccessSnackbar();
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

  void _showSuccessSnackbar() {
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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(initialIndex: 2),
              ),
              (route) => false,
            );
          },
        ),
      ),
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

  void _openProductDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailPage(widget.product.toProductModel()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openProductDetail,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm với badge giảm giá
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: widget.product.image.isNotEmpty
                        ? Image.network(
                            widget.product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.medical_services,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.medical_services,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                  ),
                ),
                // Badge giảm giá
                Positioned(
                  top: 8,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      '-${widget.product.discountPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Thông tin sản phẩm
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên sản phẩm
                    Flexible(
                      child: Text(
                        widget.product.name,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Giá gốc (gạch ngang)
                    Text(
                      Formatter.formatCurrency(widget.product.originalPrice),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 10,
                      ),
                    ),

                    // Giá khuyến mãi
                    Text(
                      Formatter.formatCurrency(widget.product.salePrice),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Nút mua với API
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: _isAddingToCart ? null : _handleAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isAddingToCart
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Mua ngay',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
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
