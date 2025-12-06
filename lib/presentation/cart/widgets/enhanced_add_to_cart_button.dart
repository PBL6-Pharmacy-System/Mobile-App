import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/cart/cart_screen.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/provider/cart_provider.dart';
import 'package:provider/provider.dart';

/// Enhanced Add to Cart Button với animations và quantity selector
class EnhancedAddToCartButton extends StatefulWidget {
  final ProductModel product;
  final int? selectedUnitId;
  final double? unitPrice;
  final VoidCallback? onSuccess;
  final bool showQuantitySelector;
  final int initialQuantity;

  const EnhancedAddToCartButton({
    super.key,
    required this.product,
    this.selectedUnitId,
    this.unitPrice,
    this.onSuccess,
    this.showQuantitySelector = false,
    this.initialQuantity = 1,
  });

  @override
  State<EnhancedAddToCartButton> createState() =>
      _EnhancedAddToCartButtonState();
}

class _EnhancedAddToCartButtonState extends State<EnhancedAddToCartButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _showSuccess = false;
  int _quantity = 1;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleAddToCart() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    // Check login
    if (!authProvider.isLoggedIn || authProvider.currentUser == null) {
      _showLoginDialog();
      return;
    }

    final customerId = authProvider.currentUser?.customerId;
    if (customerId == null) {
      _showError('Không tìm thấy thông tin khách hàng');
      return;
    }

    // Get product unit
    final defaultUnit = widget.product.defaultUnit;
    if (defaultUnit == null) {
      _showError('Sản phẩm không có đơn vị giá bán');
      return;
    }

    final productUnitId = widget.selectedUnitId ?? defaultUnit.id;
    final price = widget.unitPrice ?? double.tryParse(defaultUnit.price);

    if (price == null) {
      _showError('Thông tin giá không hợp lệ');
      return;
    }

    // Animate button press
    _animationController.forward().then((_) => _animationController.reverse());

    setState(() => _isLoading = true);

    try {
      final success = await cartProvider.addItem(
        customerId: customerId,
        productId: widget.product.id,
        productUnitId: productUnitId,
        quantity: _quantity,
        unitPrice: price,
        // Thông tin để hiển thị ngay (Optimistic Update)
        productName: widget.product.name,
        productImage: widget.product.images.isNotEmpty
            ? widget.product.images.first
            : null,
        unitName: defaultUnit.unitName,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuccess = success;
        });

        if (success) {
          _showSuccessAnimation();
          widget.onSuccess?.call();
        } else {
          _showError(
            cartProvider.error ?? 'Không thể thêm sản phẩm vào giỏ hàng',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  void _showSuccessAnimation() {
    // Show checkmark animation
    setState(() => _showSuccess = true);

    // Show snackbar with cart action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đã thêm vào giỏ hàng',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.product.name} (x$_quantity)',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Xem giỏ',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
        ),
      ),
    );

    // Reset success state after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showSuccess = false);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_cart, color: primaryColor),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Yêu cầu đăng nhập', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: const Text(
          'Bạn cần đăng nhập để thêm sản phẩm vào giỏ hàng',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Để sau', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Đăng nhập ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: () {
              if (_quantity > 1) {
                setState(() => _quantity--);
              }
            },
            enabled: _quantity > 1,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '$_quantity',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: () {
              if (_quantity < 99) {
                setState(() => _quantity++);
              }
            },
            enabled: _quantity < 99,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? primaryColor : Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showQuantitySelector) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantitySelector(),
          const SizedBox(height: 12),
          _buildAddButton(),
        ],
      );
    }

    return _buildAddButton();
  }

  Widget _buildAddButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: _isLoading || _showSuccess ? null : _handleAddToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: _showSuccess ? Colors.green : primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _showSuccess ? Colors.green : Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (_isLoading) {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_showSuccess) {
      return const Row(
        key: ValueKey('success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 20),
          SizedBox(width: 8),
          Text(
            'Đã thêm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Row(
      key: const ValueKey('idle'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.shopping_cart_outlined, size: 20),
        const SizedBox(width: 8),
        Text(
          widget.showQuantitySelector
              ? 'Thêm vào giỏ ($_quantity)'
              : 'Thêm vào giỏ hàng',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Simple Add to Cart Icon Button (for product cards)
class AddToCartIconButton extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onSuccess;

  const AddToCartIconButton({super.key, required this.product, this.onSuccess});

  @override
  State<AddToCartIconButton> createState() => _AddToCartIconButtonState();
}

class _AddToCartIconButtonState extends State<AddToCartIconButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAddToCart() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập')));
      return;
    }

    final customerId = authProvider.currentUser?.customerId;
    if (customerId == null) return;

    final defaultUnit = widget.product.defaultUnit;
    if (defaultUnit == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await cartProvider.addItem(
        customerId: customerId,
        productId: widget.product.id,
        productUnitId: defaultUnit.id,
        quantity: 1,
        unitPrice: double.tryParse(defaultUnit.price) ?? 0,
        // Thông tin để hiển thị ngay (Optimistic Update)
        productName: widget.product.name,
        productImage: widget.product.images.isNotEmpty
            ? widget.product.images.first
            : null,
        unitName: defaultUnit.unitName,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          // Animate icon
          _controller.forward().then((_) => _controller.reverse());

          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm ${widget.product.name}'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );

          widget.onSuccess?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: _isLoading ? null : _handleAddToCart,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                  size: 20,
                ),
          tooltip: 'Thêm vào giỏ hàng',
        ),
      ),
    );
  }
}
