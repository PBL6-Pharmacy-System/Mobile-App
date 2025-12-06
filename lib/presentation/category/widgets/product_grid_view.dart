import 'package:flutter/material.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/widgets/product_card.dart';
import 'package:pharmacy_app/configs/constant.dart';

class ProductGridView extends StatelessWidget {
  final List<ProductModel> products;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasMoreProducts;

  const ProductGridView({
    Key? key,
    required this.products,
    required this.scrollController,
    required this.isLoadingMore,
    required this.hasMoreProducts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: products.length + (isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return _buildLoadingIndicator();
          }

          return ProductCard(product: products[index]);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3),
      ),
    );
  }
}
