import 'package:pharmacy_app/models/category_model.dart';

class ProductModel {
  final CategoryModel category;
  final String name;
  final double price;
  final String image;
  final String description;
  final String usage;
  final String ingredients;

  ProductModel({
    required this.category,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.usage,
    required this.ingredients,
  });
}
