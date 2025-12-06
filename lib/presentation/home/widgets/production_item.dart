import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/optimized_image.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/formatter.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/detail_product/product_detail_page.dart';
import 'package:pharmacy_app/presentation/cart/widgets/add_to_cart_button.dart';
import 'package:pharmacy_app/provider/app_state.dart';
import 'package:provider/provider.dart';

class ProductionItem extends StatelessWidget {
  const ProductionItem(this.product, {super.key});

  final ProductModel product;

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        color: Colors.grey[200],
      ),
      child: Center(
        child: Icon(Icons.medical_services, size: 48, color: Colors.grey[400]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailPage(product)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: product.image.isNotEmpty
                ? OptimizedImage(
                    imageUrl: product.image,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    errorWidget: _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: context.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.category.name,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatter.formatCurrency(double.tryParse(product.price) ?? 0),
                  style: context.textTheme.titleMedium?.copyWith(
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Sử dụng AddToCartButton thực với API backend
                SizedBox(
                  width: double.infinity,
                  child: AddToCartButton(
                    product: product,
                    quantity: 1,
                    onSuccess: () {
                      // Vẫn giữ behavior cũ để tương thích
                      context.read<AppState>().addToCart(product);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
