import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/fake_data.dart';
import 'package:pharmacy_app/presentation/home/widgets/production_item.dart';

class OutstandingProduct extends StatelessWidget {
  const OutstandingProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.md,
        children: [
          Text('Sản phẩm nổi bật', style: context.textTheme.titleSmall),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: Gap.sm,
              crossAxisSpacing: Gap.sm,
              childAspectRatio: 0.5,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductionItem(products[index]);
            },
          ),
        ],
      ),
    );
  }
}
