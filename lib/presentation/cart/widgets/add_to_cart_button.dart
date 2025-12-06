import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/provider/cart_provider.dart';
import 'package:pharmacy_app/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';

class AddToCartButton extends StatefulWidget {
  final ProductModel product;
  final int quantity;
  final int? selectedUnitId; // ID của đơn vị được chọn
  final double? unitPrice; // Giá của đơn vị được chọn
  final VoidCallback? onSuccess;
  final VoidCallback? onLoginRequired;
  final bool
  navigateToCartOnSuccess; // Có chuyển đến giỏ hàng sau khi thêm không

  const AddToCartButton({
    super.key,
    required this.product,
    this.quantity = 1,
    this.selectedUnitId,
    this.unitPrice,
    this.onSuccess,
    this.onLoginRequired,
    this.navigateToCartOnSuccess = false,
  });

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> {
  bool _isLoading = false;

  Future<void> _handleAddToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Kiểm tra đăng nhập
    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      print('⚠️ User not logged in');
      if (widget.onLoginRequired != null) {
        widget.onLoginRequired!();
      } else {
        _showLoginRequiredDialog();
      }
      return;
    }

    // Kiểm tra customerId
    final customerId = authProvider.currentUser?.customerId;
    print(
      '📦 Current user: ${authProvider.currentUser?.username}, customerId: $customerId',
    );

    if (customerId == null) {
      print('❌ No customerId found for user');
      _showErrorDialog(
        'Không tìm thấy thông tin khách hàng. Vui lòng đăng xuất và đăng nhập lại.',
      );
      return;
    }

    // Lấy đơn vị sản phẩm (product unit hoặc đơn vị được chọn)
    final ProductUnit? defaultUnit = widget.product.defaultUnit;

    if (defaultUnit == null) {
      print('❌ No product units available for product ${widget.product.id}');
      _showErrorDialog(
        'Sản phẩm chưa có đơn vị giá bán. Vui lòng thử lại sau.',
      );
      return;
    }

    final productUnitId = widget.selectedUnitId ?? defaultUnit.id;

    // Lấy giá (từ unitPrice hoặc giá của unit)
    final price = widget.unitPrice ?? double.tryParse(defaultUnit.price);

    print(
      '📦 Adding to cart: productId=${widget.product.id}, productUnitId=$productUnitId, price=$price, defaultUnit.id=${defaultUnit.id}',
    );

    // Kiểm tra productUnitId = 0 (virtual unit - không có trong DB)
    if (productUnitId == 0) {
      print(
        '⚠️ Product ${widget.product.id} has virtual unit (id=0), cannot add to cart',
      );
      _showErrorDialog(
        'Sản phẩm chưa được cấu hình đơn vị giá. Vui lòng liên hệ hỗ trợ.',
      );
      return;
    }

    if (price == null || price <= 0) {
      _showErrorDialog('Giá sản phẩm không hợp lệ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await cartProvider.addItem(
        customerId: customerId,
        productId: widget.product.id,
        productUnitId: productUnitId,
        quantity: widget.quantity,
        unitPrice: price,
        // Thông tin để hiển thị ngay (Optimistic Update)
        productName: widget.product.name,
        productImage: widget.product.images.isNotEmpty
            ? widget.product.images.first
            : null,
        unitName: widget.product.defaultUnit?.unitName,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _showSuccessSnackbar();
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        } else {
          _showErrorDialog(
            cartProvider.error ?? 'Không thể thêm sản phẩm vào giỏ hàng',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã thêm "${widget.product.name}" vào giỏ hàng',
                style: const TextStyle(fontSize: 14),
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

    // Tự động chuyển đến giỏ hàng nếu được cấu hình
    if (widget.navigateToCartOnSuccess) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateToCart();
        }
      });
    }
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Yêu cầu đăng nhập'),
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
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleAddToCart,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 36),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Thêm giỏ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}
