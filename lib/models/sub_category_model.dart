class SubCategoryModel {
  final int? id;
  final String name;
  final String icon;
  final List<String> subItems; // Danh mục cấp 3

  SubCategoryModel(this.name, this.icon, {this.subItems = const [], this.id});

  /// Factory constructor to create SubCategoryModel from JSON
  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      json['name'] as String? ?? '',
      json['icon'] as String? ?? '',
      id: json['id'] as int?,
      subItems: json['sub_items'] != null && json['sub_items'] is List
          ? (json['sub_items'] as List).map((item) => item.toString()).toList()
          : const [],
    );
  }

  /// Convert SubCategoryModel to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'sub_items': subItems};
  }
}
