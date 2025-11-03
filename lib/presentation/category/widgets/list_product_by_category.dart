import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/home/widgets/production_item.dart';

class ListProductByCategory extends StatelessWidget {
  const ListProductByCategory(this.listProduct, {super.key});

  final List<ProductModel> listProduct;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Gap.sm,
        crossAxisSpacing: Gap.sm,
        childAspectRatio: 0.5,
      ),
      itemCount: listProduct.length,
      itemBuilder: (context, index) {
        return ProductionItem(listProduct[index]);
      },
    );
  }
}
