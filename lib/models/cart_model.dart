class CartItemModel {
  final int id;
  final int cartId;
  final int productId;
  final int productUnitId;
  final int quantity;
  final double price;
  final double? discountPrice;
  final double? subtotalAmount;
  final int? flashsaleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated fields from joins
  final ProductUnitInfo? productUnit;

  CartItemModel({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.productUnitId,
    required this.quantity,
    required this.price,
    this.discountPrice,
    this.subtotalAmount,
    this.flashsaleId,
    required this.createdAt,
    required this.updatedAt,
    this.productUnit,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Parse product info from nested products object
    ProductUnitInfo? unitInfo;

    print('📦 [CartItemModel] ============================');
    print('📦 [CartItemModel] Raw JSON keys: ${json.keys.toList()}');
    print(
      '📦 [CartItemModel] id value: ${json['id']} (type: ${json['id']?.runtimeType})',
    );
    print('📦 [CartItemModel] Full JSON: $json');

    // Backend returns: products { id, name, image_url, images } and productunits { id, unit_name, conversion_factor, price }
    if (json['products'] != null || json['productunits'] != null) {
      Map<String, dynamic>? productData;
      Map<String, dynamic>? unitData;

      if (json['products'] != null) {
        productData = json['products'] is Map
            ? Map<String, dynamic>.from(json['products'])
            : null;
      }

      if (json['productunits'] != null) {
        unitData = json['productunits'] is Map
            ? Map<String, dynamic>.from(json['productunits'])
            : null;
      }

      print('📦 [CartItemModel] productData: $productData');
      print('📦 [CartItemModel] unitData: $unitData');

      // Use orderitems.price as the main price (snapshot at time of adding to cart)
      // productunits.price is the current price for reference
      unitInfo = ProductUnitInfo(
        id: unitData?['id'] ?? json['unit_id'] ?? 0,
        productId: productData?['id'] ?? json['product_id'] ?? 0,
        unitName: unitData?['unit_name'] ?? '',
        conversionRate: _parseDouble(unitData?['conversion_factor']),
        price: _parseDouble(
          unitData?['price'] ?? json['price'],
        ), // Use unit price or fallback to orderitem price
        product: productData != null
            ? ProductBasicInfo.fromJson(productData)
            : null,
      );
    } else if (json['product_unit'] != null) {
      final puData = json['product_unit'] is Map
          ? Map<String, dynamic>.from(json['product_unit'])
          : null;
      if (puData != null) {
        unitInfo = ProductUnitInfo.fromJson(puData);
      }
    }

    final parsedId = json['id'] ?? 0;
    print('📦 [CartItemModel] Parsed item id: $parsedId');

    return CartItemModel(
      id: parsedId,
      cartId: json['cart_id'] ?? json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productUnitId: json['unit_id'] ?? json['product_unit_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: _parseDouble(json['price']),
      subtotalAmount: json['subtotal'] != null
          ? _parseDouble(json['subtotal'])
          : null,
      discountPrice: json['discount_price'] != null
          ? _parseDouble(json['discount_price'])
          : null,
      flashsaleId: json['flashsale_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      productUnit: unitInfo,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'product_id': productId,
      'unit_id': productUnitId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotalAmount,
      'discount_price': discountPrice,
      'flashsale_id': flashsaleId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'product_unit': productUnit?.toJson(),
    };
  }

  /// Copy with new values (for optimistic updates)
  CartItemModel copyWith({
    int? id,
    int? cartId,
    int? productId,
    int? productUnitId,
    int? quantity,
    double? price,
    double? discountPrice,
    double? subtotalAmount,
    int? flashsaleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProductUnitInfo? productUnit,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      productUnitId: productUnitId ?? this.productUnitId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      flashsaleId: flashsaleId ?? this.flashsaleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productUnit: productUnit ?? this.productUnit,
    );
  }

  double get subtotal =>
      subtotalAmount ?? ((discountPrice ?? price) * quantity);
}

class ProductUnitInfo {
  final int id;
  final int productId;
  final String unitName;
  final double conversionRate;
  final double price;
  final String? barcode;
  final ProductBasicInfo? product;

  ProductUnitInfo({
    required this.id,
    required this.productId,
    required this.unitName,
    required this.conversionRate,
    required this.price,
    this.barcode,
    this.product,
  });

  factory ProductUnitInfo.fromJson(Map<String, dynamic> json) {
    return ProductUnitInfo(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      unitName: json['unit_name'] ?? '',
      conversionRate: CartItemModel._parseDouble(json['conversion_rate']),
      price: CartItemModel._parseDouble(json['price']),
      barcode: json['barcode'],
      product: json['product'] != null
          ? ProductBasicInfo.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'unit_name': unitName,
      'conversion_rate': conversionRate,
      'price': price,
      'barcode': barcode,
      'product': product?.toJson(),
    };
  }
}

class ProductBasicInfo {
  final int id;
  final String name;
  final String? imageUrl;
  final List<String> images;

  ProductBasicInfo({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.images,
  });

  factory ProductBasicInfo.fromJson(Map<String, dynamic> json) {
    return ProductBasicInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
      images: json['images'] != null ? List<String>.from(json['images']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image_url': imageUrl, 'images': images};
  }

  String get primaryImage => images.isNotEmpty ? images[0] : (imageUrl ?? '');
}

class CartModel {
  final int id;
  final int customerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CartItemModel> items;

  // Voucher information (if applied)
  final int? voucherId;
  final String? voucherCode;
  final double? voucherDiscount;

  CartModel({
    required this.id,
    required this.customerId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.voucherId,
    this.voucherCode,
    this.voucherDiscount,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    // Backend returns orderitems, but we might also receive items for backward compatibility
    final rawItemsList = json['orderitems'] ?? json['items'];

    print('📦 [CartModel] Parsing cart from JSON');
    print('📦 [CartModel] Cart ID: ${json['id']}');
    print('📦 [CartModel] Has orderitems: ${json['orderitems'] != null}');
    print('📦 [CartModel] Has items: ${json['items'] != null}');
    print('📦 [CartModel] rawItemsList: $rawItemsList');

    List<CartItemModel> parsedItems = [];

    if (rawItemsList != null && rawItemsList is List) {
      print('📦 [CartModel] rawItemsList length: ${rawItemsList.length}');
      for (var item in rawItemsList) {
        try {
          print('📦 [CartModel] Parsing item: $item');
          if (item is Map<String, dynamic>) {
            parsedItems.add(CartItemModel.fromJson(item));
          } else if (item is Map) {
            parsedItems.add(
              CartItemModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        } catch (e) {
          print('❌ [CartModel] Error parsing item: $e');
        }
      }
    }

    print('📦 [CartModel] Parsed ${parsedItems.length} items');

    return CartModel(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['order_date'] != null
                ? DateTime.parse(json['order_date'])
                : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      items: parsedItems,
      voucherId: json['voucher_id'],
      voucherCode: json['voucher_code'],
      voucherDiscount: json['voucher_discount'] != null
          ? CartItemModel._parseDouble(json['voucher_discount'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'voucher_id': voucherId,
      'voucher_code': voucherCode,
      'voucher_discount': voucherDiscount,
    };
  }

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get voucherAmount => voucherDiscount ?? 0.0;
  double get total => subtotal - voucherAmount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
