class UserModel {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? avatar;
  final String role; // CUSTOMER, STAFF, ADMIN
  final DateTime createdAt;
  final DateTime updatedAt;

  // Role-specific IDs
  final int? customerId;
  final int? staffId;
  final int? adminId;
  final int? branchId; // For staff

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.avatar,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.customerId,
    this.staffId,
    this.adminId,
    this.branchId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse customer_id từ nhiều nguồn:
    // 1. Trực tiếp từ json['customer_id']
    // 2. Từ customers relation: json['customers']['id']
    // 3. Từ customers relation khi là array: json['customers'][0]['id']
    int? customerId = json['customer_id'];

    if (customerId == null && json['customers'] != null) {
      final customers = json['customers'];
      if (customers is Map) {
        customerId = customers['id'];
      } else if (customers is List && customers.isNotEmpty) {
        customerId = customers[0]['id'];
      }
    }

    print(
      '📦 [UserModel] Parsing user: id=${json['id']}, customers=${json['customers']}, customerId=$customerId',
    );

    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'],
      avatar: json['avatar_url'] ?? json['avatar'],
      role:
          json['role'] ??
          (json['roles'] != null ? json['roles']['role_name'] : 'CUSTOMER'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      customerId: customerId,
      staffId: json['staff_id'],
      adminId: json['admin_id'],
      branchId: json['branch_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatar,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer_id': customerId,
      'staff_id': staffId,
      'admin_id': adminId,
      'branch_id': branchId,
    };
  }

  bool get isCustomer => role == 'CUSTOMER';
  bool get isStaff => role == 'STAFF';
  bool get isAdmin => role == 'ADMIN';
}
