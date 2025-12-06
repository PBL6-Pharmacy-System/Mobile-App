import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/models/product_model.dart';

class FlashSaleProductModel {
  final int? id;
  final CategoryModel? category;
  final String name;
  final double originalPrice;
  final double salePrice;
  final String image;
  final String description;
  final String usage;
  final String ingredients;
  final int discountPercent;
  final DateTime? saleStartTime;
  final DateTime? saleEndTime;
  final int? stockQuantity;

  // Product unit info for cart
  final int? productId;
  final int? productUnitId;
  final List<ProductUnit>? productUnits;

  FlashSaleProductModel({
    this.id,
    this.category,
    required this.name,
    required this.originalPrice,
    required this.salePrice,
    required this.image,
    required this.description,
    required this.usage,
    required this.ingredients,
    this.saleStartTime,
    this.saleEndTime,
    this.stockQuantity,
    this.productId,
    this.productUnitId,
    this.productUnits,
  }) : discountPercent = originalPrice > 0
           ? (((originalPrice - salePrice) / originalPrice) * 100).round()
           : 0;

  /// Factory constructor to create FlashSaleProductModel from JSON
  factory FlashSaleProductModel.fromJson(Map<String, dynamic> json) {
    // Parse productunits if available
    List<ProductUnit>? units;
    if (json['productunits'] != null) {
      units = (json['productunits'] as List)
          .map((u) => ProductUnit.fromJson(u))
          .toList();
    }

    // Get default product unit id
    int? defaultUnitId;
    if (units != null && units.isNotEmpty) {
      try {
        defaultUnitId = units.firstWhere((u) => u.conversionFactor == 1).id;
      } catch (e) {
        defaultUnitId = units.first.id;
      }
    }

    return FlashSaleProductModel(
      id: json['id'] as int?,
      productId: json['product_id'] as int? ?? json['id'] as int?,
      productUnitId: json['product_unit_id'] as int? ?? defaultUnitId,
      productUnits: units,
      name: json['name'] as String? ?? '',
      originalPrice: _parseDouble(json['price'] ?? json['original_price']),
      salePrice: _parseDouble(json['sale_price'] ?? json['salePrice']),
      image: json['image_url'] as String? ?? json['image'] as String? ?? '',
      description: json['description'] as String? ?? '',
      usage: json['usage'] as String? ?? '',
      ingredients: json['ingredients'] as String? ?? '',
      saleStartTime: json['sale_start_time'] != null
          ? DateTime.parse(json['sale_start_time'] as String)
          : null,
      saleEndTime: json['sale_end_time'] != null
          ? DateTime.parse(json['sale_end_time'] as String)
          : null,
      stockQuantity: json['stock_quantity'] as int? ?? json['stock'] as int?,
      category: json['category'] != null && json['category'] is Map
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Get default product unit
  ProductUnit? get defaultUnit {
    if (productUnits == null || productUnits!.isEmpty) return null;
    try {
      return productUnits!.firstWhere((unit) => unit.conversionFactor == 1);
    } catch (e) {
      return productUnits!.first;
    }
  }

  /// Convert FlashSaleProductModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_unit_id': productUnitId,
      'name': name,
      'price': originalPrice,
      'sale_price': salePrice,
      'image_url': image,
      'description': description,
      'usage': usage,
      'ingredients': ingredients,
      'sale_start_time': saleStartTime?.toIso8601String(),
      'sale_end_time': saleEndTime?.toIso8601String(),
      'stock_quantity': stockQuantity,
      'category': category?.toJson(),
      'productunits': productUnits?.map((u) => u.toJson()).toList(),
    };
  }

  /// Helper method to parse double from dynamic value
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Check if flash sale is currently active
  bool get isActive {
    final now = DateTime.now();
    if (saleStartTime != null && now.isBefore(saleStartTime!)) return false;
    if (saleEndTime != null && now.isAfter(saleEndTime!)) return false;
    return true;
  }

  /// Get remaining time for the flash sale
  Duration? get remainingTime {
    if (saleEndTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(saleEndTime!)) return Duration.zero;
    return saleEndTime!.difference(now);
  }

  /// Convert to ProductModel for detail page
  ProductModel toProductModel() {
    return ProductModel(
      id: productId ?? id ?? 0,
      name: name,
      description: description,
      price: salePrice.toString(),
      stock: stockQuantity ?? 0,
      categoryId: category?.id ?? 0,
      supplierId: 0,
      imageUrl: image,
      prescriptionRequired: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      taxFee: '0',
      baseUnitId: productUnitId ?? 0,
      images: image.isNotEmpty ? [image] : [],
      manufacturer: '',
      usage: usage,
      dosage: '',
      specification: ingredients,
      adverseEffect: '',
      registNum: '',
      brand: '',
      producer: '',
      manufactor: '',
      legalDeclaration: null,
      faq: [],
      categories: category != null
          ? Categories(
              id: category!.id,
              name: category!.name,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : Categories.empty(),
      suppliers: Suppliers.empty(),
      unittype: Unittype.empty(),
      productUnits: productUnits ?? [],
    );
  }
}
