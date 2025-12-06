import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/formatter.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/cart_model.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/provider/cart_provider.dart';
import 'package:provider/provider.dart';

class CartItem extends StatelessWidget {
  const CartItem(this.item, {super.key});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final productName =
        item.productUnit?.product?.name ?? 'Sản phẩm #${item.productId}';
    final productImage = item.productUnit?.product?.primaryImage ?? '';
    final unitName = item.productUnit?.unitName ?? '';
    final price = item.discountPrice ?? item.price;
    final originalPrice = item.discountPrice != null ? item.price : null;

    return Container(
      margin: const EdgeInsets.only(bottom: Gap.sm),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1, color: borderColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[100],
              child: productImage.isNotEmpty
                  ? Image.network(
                      productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.medication,
                          size: 40,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(Icons.medication, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(width: Gap.md),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  productName,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Unit Name
                if (unitName.isNotEmpty)
                  Text(
                    unitName,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
                  ),
                const SizedBox(height: 8),

                // Price Row
                Row(
                  children: [
                    Text(
                      Formatter.formatCurrency(price),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (originalPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        Formatter.formatCurrency(originalPrice),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Quantity Controls and Delete Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls
                    _QuantityControls(item: item),

                    // Delete Button
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final productName =
        item.productUnit?.product?.name ?? 'Sản phẩm #${item.productId}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "$productName" khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeItem(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _removeItem(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final customerId = authProvider.currentUser?.customerId;

    print(
      '🗑️ [CartItem] Removing item: id=${item.id}, customerId=$customerId',
    );

    if (customerId == null) {
      print('❌ [CartItem] Cannot remove - customerId is null');
      return;
    }

    final success = await cartProvider.removeItem(
      customerId: customerId,
      itemId: item.id,
    );

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa sản phẩm khỏi giỏ hàng'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class _QuantityControls extends StatelessWidget {
  final CartItemModel item;

  const _QuantityControls({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease Button
          _QuantityButton(
            icon: Icons.remove,
            onPressed: item.quantity > 1
                ? () => _updateQuantity(context, item.quantity - 1)
                : null,
          ),

          // Quantity Display
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),

          // Increase Button
          _QuantityButton(
            icon: Icons.add,
            onPressed: () => _updateQuantity(context, item.quantity + 1),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(BuildContext context, int newQuantity) async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final customerId = authProvider.currentUser?.customerId;

    if (customerId == null) return;

    await cartProvider.updateItemQuantity(
      customerId: customerId,
      itemId: item.id,
      quantity: newQuantity,
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? primaryColor : Colors.grey[400],
        ),
      ),
    );
  }
}
