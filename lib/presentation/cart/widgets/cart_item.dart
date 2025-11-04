import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/formatter.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/detail_product/widgets/quantity_selector.dart';

class CartItem extends StatelessWidget {
  const CartItem(this.product, {super.key});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.3,
      child: Container(
        padding: EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: borderColor),
          borderRadius: radius12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Gap.sM,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: radius16,
                image: DecorationImage(image: NetworkImage(product.image)),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      product.category.name,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      Formatter.formatCurrency(product.price),
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: QuantitySelector(onChanged: (value) {}),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
