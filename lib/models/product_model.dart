import 'package:pharmacy_app/models/category_model.dart';

class ProductModel {
  final String name;
  final CategoryModel category;
  final String image;
  final double price;

  const ProductModel({
    required this.category,
    required this.image,
    required this.name,
    required this.price,
  });
}
