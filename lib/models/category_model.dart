class CategoryModel {
  final int id;
  final String name;
  final int? parentId;
  final int productCount;
  final List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.productCount,
    required this.children,
  });

  /// Factory constructor to create CategoryModel from /categories/tree API response
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      parentId: json['parent_id'] as int?,
      productCount: json['product_count'] as int? ?? 0,
      children:
          (json['children'] as List<dynamic>?)
              ?.map(
                (child) =>
                    CategoryModel.fromJson(child as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Convert CategoryModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'product_count': productCount,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  /// Get all descendant categories (flattened list)
  List<CategoryModel> getAllDescendants() {
    List<CategoryModel> descendants = [];
    for (var child in children) {
      descendants.add(child);
      descendants.addAll(child.getAllDescendants());
    }
    return descendants;
  }

  /// Check if category has children
  bool get hasChildren => children.isNotEmpty;

  /// Get total product count including all descendants
  int get totalProductCount {
    int total = productCount;
    for (var child in children) {
      total += child.totalProductCount;
    }
    return total;
  }
}

/// Response model for /categories/tree API
class CategoryTreeResponse {
  final bool success;
  final List<CategoryModel> data;

  CategoryTreeResponse({required this.success, required this.data});

  factory CategoryTreeResponse.fromJson(Map<String, dynamic> json) {
    return CategoryTreeResponse(
      success: json['success'] as bool? ?? true,
      data:
          (json['data'] as List<dynamic>?)
              ?.map(
                (category) =>
                    CategoryModel.fromJson(category as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
