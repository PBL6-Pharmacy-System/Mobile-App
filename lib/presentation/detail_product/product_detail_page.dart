import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/dialog.dart';
import 'package:pharmacy_app/common/widgets/outline_button_app.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/formatter.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/detail_product/widgets/quantity_selector.dart';
import 'package:pharmacy_app/provider/app_state.dart';
import 'package:provider/provider.dart';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
                        image: DecorationImage(
                          image: NetworkImage(product.image),
                        ),
                      ),
                    ),
                  ),

                  Text(product.name, style: context.textTheme.titleMedium),
                  Text(
                    product.category.name,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
                  ),
                  Text(
                    Formatter.formatCurrency(product.price),
                    style: context.textTheme.titleMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Divider(height: 1),
                  Text('Mô tả sản phẩm', style: context.textTheme.titleMedium),
                  Text(
                    product.description,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
                  ),
                  Divider(height: 1),
                  Text(
                    'Hướng dẫn sử dụng',
                    style: context.textTheme.titleMedium,
                  ),
                  Text(
                    product.usage,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
                  ),
                  Divider(height: 1),
                  Text('Thành phần', style: context.textTheme.titleMedium),
                  Text(
                    product.ingredients,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Gap.md),
              child: IntrinsicHeight(
                child: Row(
                  spacing: Gap.sm,
                  children: [
                    Expanded(child: QuantitySelector(onChanged: (value) {})),
                    Expanded(
                      child: OutlineButtonApp(
                        child: Text('Thêm vào giỏ'),
                        onPressed: () {
                          showAddToCartSuccess(context, product.name);
                          context.read<AppState>().addToCart(product);
                        },
                      ),
                    ),
                    Expanded(
                      child: ButtonApp(
                        child: Text('Mua ngay'),
                        onPressed: () {},
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
