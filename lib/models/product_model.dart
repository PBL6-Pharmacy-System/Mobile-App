import 'dart:convert';
import 'package:pharmacy_app/models/category_model.dart';

ProductModel productModelFromJson(String str) =>
    ProductModel.fromJson(json.decode(str));

String productModelToJson(ProductModel data) => json.encode(data.toJson());

class ProductModel {
  int id;
  String name;
  String description;
  String price;
  int stock;
  int categoryId;
  int supplierId;
  String? imageUrl;
  bool prescriptionRequired;
  DateTime createdAt;
  DateTime updatedAt;
  String taxFee;
  int baseUnitId;
  List<String> images;
  String manufacturer;
  String usage;
  String dosage;
  String specification;
  String adverseEffect;
  String registNum;
  String brand;
  String producer;
  String manufactor;
  String? legalDeclaration;
  List<Faq> faq;
  Categories categories;
  Suppliers suppliers;
  Unittype unittype;
  List<ProductUnit> productUnits;
  bool inStock; // Trạng thái còn hàng từ API

  // Helper getter để kiểm tra hết hàng
  bool get isOutOfStock => !inStock;

  // Helper getters để tương thích với code cũ
  String get image => images.isNotEmpty ? images[0] : (imageUrl ?? '');
  CategoryModel get category => CategoryModel(
    id: categoryId,
    name: categories.name,
    productCount: 0,
    children: [],
  );

  // Lấy product unit mặc định (base unit)
  ProductUnit? get defaultUnit {
    // Nếu có productUnits, tìm unit có conversion_factor = 1 (base unit)
    if (productUnits.isNotEmpty) {
      try {
        return productUnits.firstWhere((unit) => unit.conversionFactor == 1);
      } catch (e) {
        // Nếu không tìm thấy, trả về unit đầu tiên
        return productUnits.first;
      }
    }

    // Fallback: Tạo default unit từ price và unittype khi không có productunits
    // Điều này xảy ra khi database chưa có bản ghi productunits cho sản phẩm
    if (price.isNotEmpty && unittype.name.isNotEmpty) {
      return ProductUnit(
        id: 0, // Virtual ID
        productId: id,
        unitId: baseUnitId,
        unitName: unittype.name,
        conversionFactor: 1,
        price: price,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }

    return null;
  }

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.supplierId,
    required this.imageUrl,
    required this.prescriptionRequired,
    required this.createdAt,
    required this.updatedAt,
    required this.taxFee,
    required this.baseUnitId,
    required this.images,
    required this.manufacturer,
    required this.usage,
    required this.dosage,
    required this.specification,
    required this.adverseEffect,
    required this.registNum,
    required this.brand,
    required this.producer,
    required this.manufactor,
    required this.legalDeclaration,
    required this.faq,
    required this.categories,
    required this.suppliers,
    required this.unittype,
    required this.productUnits,
    this.inStock = true, // Mặc định còn hàng
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse productunits với fallback an toàn
      List<ProductUnit> units = [];
      if (json["productunits"] != null) {
        try {
          units = List<ProductUnit>.from(
            json["productunits"].map((x) => ProductUnit.fromJson(x)),
          );
          print('✅ Parsed ${units.length} product units for ${json["name"]}');
        } catch (e) {
          print('⚠️ Error parsing productunits for ${json["name"]}: $e');
        }
      } else {
        print('⚠️ No productunits in response for ${json["name"]}');
      }

      return ProductModel(
        id: json["id"] ?? 0,
        name: json["name"] ?? '',
        description: json["description"] ?? '',
        price: json["price"]?.toString() ?? '0',
        stock: json["stock"] ?? 0,
        categoryId: json["category_id"] ?? 0,
        supplierId: json["supplier_id"] ?? 0,
        imageUrl: json["image_url"],
        prescriptionRequired: json["prescription_required"] ?? false,
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : DateTime.now(),
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : DateTime.now(),
        taxFee: json["tax_fee"]?.toString() ?? '0',
        baseUnitId: json["base_unit_id"] ?? 0,
        images: json["images"] != null
            ? List<String>.from(json["images"].map((x) => x.toString()))
            : [],
        manufacturer: json["manufacturer"] ?? '',
        usage: json["usage"] ?? '',
        dosage: json["dosage"] ?? '',
        specification: json["specification"] ?? '',
        adverseEffect: json["adverseEffect"] ?? '',
        registNum: json["registNum"] ?? '',
        brand: json["brand"] ?? '',
        producer: json["producer"] ?? '',
        manufactor: json["manufactor"] ?? '',
        legalDeclaration: json["legalDeclaration"],
        faq: json["faq"] != null
            ? List<Faq>.from(json["faq"].map((x) => Faq.fromJson(x)))
            : [],
        categories: json["categories"] != null
            ? Categories.fromJson(json["categories"])
            : Categories.empty(),
        suppliers: json["suppliers"] != null
            ? Suppliers.fromJson(json["suppliers"])
            : Suppliers.empty(),
        unittype: json["unittype"] != null
            ? Unittype.fromJson(json["unittype"])
            : Unittype.empty(),
        productUnits: units,
        inStock: (json["in_stock"] ?? 1) == 1, // 1 = còn hàng, 0 = hết hàng
      );
    } catch (e) {
      print('❌ Error parsing ProductModel: $e');
      print('📦 JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "price": price,
    "stock": stock,
    "category_id": categoryId,
    "supplier_id": supplierId,
    "image_url": imageUrl,
    "prescription_required": prescriptionRequired,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "tax_fee": taxFee,
    "base_unit_id": baseUnitId,
    "images": List<dynamic>.from(images.map((x) => x)),
    "manufacturer": manufacturer,
    "usage": usage,
    "dosage": dosage,
    "specification": specification,
    "adverseEffect": adverseEffect,
    "registNum": registNum,
    "brand": brand,
    "producer": producer,
    "manufactor": manufactor,
    "legalDeclaration": legalDeclaration,
    "faq": List<dynamic>.from(faq.map((x) => x.toJson())),
    "categories": categories.toJson(),
    "suppliers": suppliers.toJson(),
    "unittype": unittype.toJson(),
    "productunits": List<dynamic>.from(productUnits.map((x) => x.toJson())),
    "in_stock": inStock ? 1 : 0,
  };
}

class Categories {
  int id;
  String name;
  String? description;
  int? parentId;
  DateTime createdAt;
  DateTime updatedAt;

  Categories({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Categories.fromJson(Map<String, dynamic> json) => Categories(
    id: json["id"] ?? 0,
    name: json["name"] ?? '',
    description: json["description"],
    parentId: json["parent_id"],
    createdAt: json["created_at"] != null
        ? DateTime.parse(json["created_at"])
        : DateTime.now(),
    updatedAt: json["updated_at"] != null
        ? DateTime.parse(json["updated_at"])
        : DateTime.now(),
  );

  factory Categories.empty() => Categories(
    id: 0,
    name: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "parent_id": parentId,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}

class Faq {
  String answer;
  String question;

  Faq({required this.answer, required this.question});

  factory Faq.fromJson(Map<String, dynamic> json) =>
      Faq(answer: json["answer"] ?? '', question: json["question"] ?? '');

  Map<String, dynamic> toJson() => {"answer": answer, "question": question};
}

class Suppliers {
  int id;
  String name;
  String? contactInfo;
  DateTime createdAt;
  DateTime updatedAt;

  Suppliers({
    required this.id,
    required this.name,
    this.contactInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Suppliers.fromJson(Map<String, dynamic> json) => Suppliers(
    id: json["id"] ?? 0,
    name: json["name"] ?? '',
    contactInfo: json["contact_info"],
    createdAt: json["created_at"] != null
        ? DateTime.parse(json["created_at"])
        : DateTime.now(),
    updatedAt: json["updated_at"] != null
        ? DateTime.parse(json["updated_at"])
        : DateTime.now(),
  );

  factory Suppliers.empty() => Suppliers(
    id: 0,
    name: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "contact_info": contactInfo,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}

class Unittype {
  int id;
  String name;

  Unittype({required this.id, required this.name});

  factory Unittype.fromJson(Map<String, dynamic> json) =>
      Unittype(id: json["id"] ?? 0, name: json["name"] ?? '');

  factory Unittype.empty() => Unittype(id: 0, name: '');

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class ProductUnit {
  int id;
  int productId;
  int unitId;
  String unitName;
  int conversionFactor;
  String price;
  DateTime createdAt;
  DateTime updatedAt;

  ProductUnit({
    required this.id,
    required this.productId,
    required this.unitId,
    required this.unitName,
    required this.conversionFactor,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    // Parse conversion_factor safely - handle both int and String
    int parsedConversionFactor = 1;
    if (json["conversion_factor"] != null) {
      if (json["conversion_factor"] is int) {
        parsedConversionFactor = json["conversion_factor"];
      } else if (json["conversion_factor"] is String) {
        parsedConversionFactor = int.tryParse(json["conversion_factor"]) ?? 1;
      }
    }

    return ProductUnit(
      id: json["id"] ?? 0,
      productId: json["product_id"] ?? 0,
      unitId: json["unit_id"] ?? 0,
      unitName: json["unit_name"] ?? '',
      conversionFactor: parsedConversionFactor,
      price: json["price"]?.toString() ?? '0',
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : DateTime.now(),
      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "product_id": productId,
    "unit_id": unitId,
    "unit_name": unitName,
    "conversion_factor": conversionFactor,
    "price": price,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}

/// Response model for product list API with pagination
class ProductListResponse {
  final bool success;
  final List<ProductModel> data;
  final PaginationInfo? pagination;

  ProductListResponse({
    required this.success,
    required this.data,
    this.pagination,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    // Backend trả về: { success: true, data: { products: [...], pagination: {...} } }
    final dataObject = json['data'];

    // Nếu data là object chứa products + pagination
    if (dataObject is Map<String, dynamic> &&
        dataObject.containsKey('products')) {
      return ProductListResponse(
        success: json['success'] as bool? ?? true,
        data:
            (dataObject['products'] as List<dynamic>?)
                ?.map(
                  (product) =>
                      ProductModel.fromJson(product as Map<String, dynamic>),
                )
                .toList() ??
            [],
        pagination: dataObject['pagination'] != null
            ? PaginationInfo.fromJson(
                dataObject['pagination'] as Map<String, dynamic>,
              )
            : null,
      );
    }

    // Fallback: data là array trực tiếp (backward compatibility)
    return ProductListResponse(
      success: json['success'] as bool? ?? true,
      data:
          (dataObject as List<dynamic>?)
              ?.map(
                (product) =>
                    ProductModel.fromJson(product as Map<String, dynamic>),
              )
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Pagination information model
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    // Backend format: { page, limit, totalPages, totalRecords }
    final currentPage = (json['page'] ?? json['currentPage']) as int? ?? 1;
    final totalPages = json['totalPages'] as int? ?? 1;
    final totalItems =
        (json['totalRecords'] ?? json['totalItems'] ?? json['total']) as int? ??
        0;
    final itemsPerPage = (json['limit'] ?? json['itemsPerPage']) as int? ?? 10;

    return PaginationInfo(
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      itemsPerPage: itemsPerPage,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );
  }
}
