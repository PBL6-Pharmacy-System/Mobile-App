class VoucherModel {
  final int id;
  final String code;
  final String type; // PERCENTAGE, FIXED_AMOUNT
  final double value;
  final double? minOrderValue;
  final double? maxDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isUsedByCurrentUser; // Voucher đã được user hiện tại sử dụng

  VoucherModel({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    this.usageLimit,
    required this.usedCount,
    required this.isActive,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isUsedByCurrentUser = false,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      type: json['discount_type'] ?? json['type'] ?? 'percentage',
      value: _parseDouble(json['discount_value'] ?? json['value']),
      minOrderValue: json['min_order_value'] != null
          ? _parseDouble(json['min_order_value'])
          : null,
      maxDiscount: json['max_discount'] != null
          ? _parseDouble(json['max_discount'])
          : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 30)),
      usageLimit: json['usage_limit'],
      usedCount: json['used_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      isUsedByCurrentUser: json['is_used_by_user'] ?? false,
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
      'code': code,
      'type': type,
      'value': value,
      'min_order_value': minOrderValue,
      'max_discount': maxDiscount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'is_active': isActive,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_used_by_user': isUsedByCurrentUser,
    };
  }

  /// Voucher có thể sử dụng được hay không
  /// (còn hạn, còn lượt dùng, và user chưa dùng)
  bool get isAvailable {
    if (!isActive) return false;
    if (isUsedByCurrentUser) return false;

    final now = DateTime.now();
    if (now.isBefore(startDate) || now.isAfter(endDate)) return false;

    if (usageLimit != null && usedCount >= usageLimit!) return false;

    return true;
  }

  double calculateDiscount(double orderAmount) {
    // Bỏ qua check isAvailable vì voucher từ danh sách available đã valid
    if (minOrderValue != null && orderAmount < minOrderValue!) return 0.0;

    double discount = 0.0;

    // So sánh không phân biệt chữ hoa/thường
    final lowerType = type.toLowerCase();
    if (lowerType == 'percentage') {
      discount = orderAmount * (value / 100);
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else if (lowerType == 'fixed' || lowerType == 'fixed_amount') {
      discount = value;
    }

    return discount;
  }

  String get displayValue {
    final lowerType = type.toLowerCase();
    if (lowerType == 'percentage') {
      return '${value.toInt()}%';
    } else {
      return '${value.toInt()}đ';
    }
  }
}
