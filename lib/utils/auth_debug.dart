import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Debug helper để kiểm tra auth data
class AuthDebug {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _userDataKey = 'user_data';

  /// In tất cả thông tin user trong storage
  static Future<void> printAllUserData() async {
    print('🔍 ===== AUTH DEBUG START =====');

    final id = await _storage.read(key: '$_userDataKey.id');
    final username = await _storage.read(key: '$_userDataKey.username');
    final email = await _storage.read(key: '$_userDataKey.email');
    final fullName = await _storage.read(key: '$_userDataKey.full_name');
    final role = await _storage.read(key: '$_userDataKey.role');
    final customerId = await _storage.read(key: '$_userDataKey.customer_id');
    final staffId = await _storage.read(key: '$_userDataKey.staff_id');
    final adminId = await _storage.read(key: '$_userDataKey.admin_id');

    print('User ID: $id');
    print('Username: $username');
    print('Email: $email');
    print('Full Name: $fullName');
    print('Role: $role');
    print('Customer ID: $customerId');
    print('Staff ID: $staffId');
    print('Admin ID: $adminId');

    if (role == 'CUSTOMER' && customerId == null) {
      print('⚠️ ⚠️ ⚠️ WARNING: Customer role but NO customer_id! ⚠️ ⚠️ ⚠️');
    }

    print('🔍 ===== AUTH DEBUG END =====');
  }

  /// Xóa tất cả auth data
  static Future<void> clearAllAuthData() async {
    print('🗑️ Clearing all auth data...');
    await _storage.deleteAll();
    print('✅ All auth data cleared');
  }
}
