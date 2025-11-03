import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/formatter.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/product_model.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage(this.product, {super.key});
  final ProductModel product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: Text(
          'Chi tiết sản phẩm',
          style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Gap.lg),
          child: Column(
            spacing: Gap.sM,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius16,
                    image: DecorationImage(image: NetworkImage(product.image)),
                  ),
                ),
              ),

              Text(product.name, style: context.textTheme.titleMedium),
              Text(
                product.category.name,
                style: context.textTheme.bodySmall?.copyWith(color: textColor),
              ),
              Text(
                Formatter.formatCurrency(product.price),
                style: context.textTheme.titleMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
