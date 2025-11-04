import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/fake_data.dart';
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/category/widgets/category_list.dart';
import 'package:pharmacy_app/presentation/category/widgets/list_product_by_category.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  CategoryModel category = categories[0];
  List<ProductModel> listProduct = [];

  @override
  void initState() {
    initData();
    super.initState();
  }

  initData() {
    listProduct = products
        .where((e) => e.category.name == category.name)
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: SizedBox.shrink(),
        centerTitle: true,
        title: Text(
          'Danh mục sản phẩm',
          style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: paddingApp,
          child: Column(
            spacing: Gap.md,
            children: [
              CategoryList(
                onTap: (value) {
                  category = value;
                  initData();
                },
              ),
              Expanded(child: ListProductByCategory(listProduct)),
            ],
          ),
        ),
      ),
    );
  }
}
