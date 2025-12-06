class BranchModel {
  final int id;
  final String name;
  final String address;
  final String city;
  final String? district;
  final String phoneNumber;
  final String? email;
  final double? latitude;
  final double? longitude;
  final int? managerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.district,
    required this.phoneNumber,
    this.email,
    this.latitude,
    this.longitude,
    this.managerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      district: json['district'],
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      managerId: json['manager_id'],
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
      'name': name,
      'address': address,
      'city': city,
      'district': district,
      'phone_number': phoneNumber,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'manager_id': managerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullAddress {
    List<String> parts = [address];
    if (district != null && district!.isNotEmpty) parts.add(district!);
    parts.add(city);
    return parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}
