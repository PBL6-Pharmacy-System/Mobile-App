import 'package:flutter/material.dart';
import 'package:pharmacy_app/models/product_model.dart';

class AppState extends ChangeNotifier {
  List<ProductModel> carts = [];

  void addToCart(ProductModel product) {
    carts.add(product);
    notifyListeners();
  }

  void clearCart(ProductModel product) {
    carts.clear();
    notifyListeners();
  }
}
