class AddressModel {
  final int id;
  final int customerId;
  final String? recipientName;
  final String? recipientPhone;
  final String addressLine;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  AddressModel({
    required this.id,
    required this.customerId,
    this.recipientName,
    this.recipientPhone,
    required this.addressLine,
    required this.city,
    this.state,
    this.postalCode,
    required this.country,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      recipientName: json['recipient_name'],
      recipientPhone: json['recipient_phone'],
      addressLine: json['address_line'] ?? '',
      city: json['city'] ?? '',
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'] ?? 'Vietnam',
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullAddress {
    List<String> parts = [];

    // Address line (số nhà, tên đường)
    if (addressLine.isNotEmpty) {
      parts.add(addressLine);
    }

    // State/District (quận/huyện)
    if (state != null && state!.isNotEmpty) {
      parts.add(state!);
    }

    // City (thành phố)
    if (city.isNotEmpty) {
      parts.add(city);
    }

    // Postal code (mã bưu điện) - ẩn nếu không cần
    // if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);

    // Country - chỉ hiện nếu khác Vietnam
    if (country.isNotEmpty && country != 'Vietnam' && country != 'Việt Nam') {
      parts.add(country);
    }

    return parts.join(', ');
  }

  /// Địa chỉ ngắn gọn (chỉ address line và city)
  String get shortAddress {
    if (addressLine.isNotEmpty && city.isNotEmpty) {
      return '$addressLine, $city';
    }
    return addressLine.isNotEmpty ? addressLine : city;
  }

  String get displayName => recipientName ?? 'Chưa có tên';
  String get displayPhone => recipientPhone ?? 'Chưa có SĐT';
}
