import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pharmacy_app/models/auth_response_model.dart';
import 'package:pharmacy_app/models/user_model.dart';
import 'package:pharmacy_app/services/api_service.dart';

class AuthService {
  final Dio _dio = ApiService().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  // ==================== AUTH STATE ====================

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get stored user data from local storage
  Future<UserModel?> getCurrentUser() async {
    try {
      final id = await _storage.read(key: '$_userDataKey.id');
      if (id == null) {
        print('⚠️ No user id found in storage');
        return null;
      }

      final username = await _storage.read(key: '$_userDataKey.username');
      final email = await _storage.read(key: '$_userDataKey.email');
      final fullName = await _storage.read(key: '$_userDataKey.full_name');
      final phoneNumber = await _storage.read(key: '$_userDataKey.phone');
      final avatar = await _storage.read(key: '$_userDataKey.avatar');
      final role = await _storage.read(key: '$_userDataKey.role');
      final customerIdStr = await _storage.read(
        key: '$_userDataKey.customer_id',
      );
      final staffIdStr = await _storage.read(key: '$_userDataKey.staff_id');
      final adminIdStr = await _storage.read(key: '$_userDataKey.admin_id');

      print('📦 Loading user: id=$id, role=$role, customerId=$customerIdStr');

      final user = UserModel(
        id: int.parse(id),
        username: username ?? '',
        email: email ?? '',
        fullName: fullName ?? '',
        phoneNumber: phoneNumber,
        avatar: avatar,
        role: role ?? 'CUSTOMER',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customerId: customerIdStr != null ? int.tryParse(customerIdStr) : null,
        staffId: staffIdStr != null ? int.tryParse(staffIdStr) : null,
        adminId: adminIdStr != null ? int.tryParse(adminIdStr) : null,
      );

      if (user.customerId == null && role == 'CUSTOMER') {
        print('⚠️ WARNING: Customer user but no customerId!');
      }

      return user;
    } catch (e) {
      print('❌ Error loading user data: $e');
      return null;
    }
  }

  /// Fetch current user info from API /auth/me
  Future<UserModel?> fetchCurrentUser() async {
    try {
      print('🔄 [AuthService] Fetching user from /auth/me');

      // Ensure token is set in headers before making request
      final token = await getAccessToken();
      if (token != null) {
        ApiService().setAuthToken(token);
        print('🔑 [AuthService] Token loaded for request');
      } else {
        print('⚠️ [AuthService] No token found in storage');
        return null;
      }

      final response = await _dio.get('/auth/me');

      print('🔄 [AuthService] Response status: ${response.statusCode}');
      print('🔄 [AuthService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // API returns { success: true, data: { user info } }
        if (data['success'] == true && data['data'] != null) {
          print('📦 [AuthService] Raw user data: ${data['data']}');
          print(
            '📦 [AuthService] avatar_url from API: ${data['data']['avatar_url']}',
          );
          final user = UserModel.fromJson(data['data']);
          print(
            '✅ [AuthService] Fetched user: id=${user.id}, customerId=${user.customerId}, fullName=${user.fullName}, avatar=${user.avatar}',
          );

          // Save updated user data to storage
          await _saveAuthData(
            accessToken: (await getAccessToken())!,
            user: user,
          );

          return user;
        }
      }

      print('⚠️ [AuthService] Failed to fetch user from API');
      return null;
    } on DioException catch (e) {
      print('❌ [AuthService] Fetch user error: ${e.message}');
      print('❌ [AuthService] Response: ${e.response?.data}');
      return null;
    }
  }

  // ==================== AUTHENTICATION ====================

  /// Login with username/email and password
  Future<AuthResponseModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': usernameOrEmail,
          'email': usernameOrEmail,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);

        if (authResponse.success && authResponse.accessToken != null) {
          await _saveAuthData(
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken,
            user: authResponse.user,
          );

          // Set token cho các request sau
          ApiService().setAuthToken(authResponse.accessToken!);
        }

        return authResponse;
      }

      return AuthResponseModel(success: false, message: 'Đăng nhập thất bại');
    } on DioException catch (e) {
      print('❌ Login error: ${e.message}');
      return AuthResponseModel(success: false, message: _handleError(e));
    }
  }

  /// Login with OTP (for customers) - Supports both phone and email
  Future<AuthResponseModel> loginWithOTP({
    String? phone,
    String? email,
    required String otp,
  }) async {
    try {
      if (phone == null && email == null) {
        return AuthResponseModel(
          success: false,
          message: 'Số điện thoại hoặc email là bắt buộc',
        );
      }

      print(
        '🔐 [AuthService] Calling login-otp with phone=$phone, email=$email, otp=$otp',
      );

      final response = await _dio.post(
        '/auth/customer/login-otp',
        data: {
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          'otp': otp,
        },
      );

      print('🔐 [AuthService] Response status: ${response.statusCode}');
      print('🔐 [AuthService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);

        print(
          '🔐 [AuthService] Parsed - success: ${authResponse.success}, token: ${authResponse.accessToken != null}, user: ${authResponse.user != null}',
        );

        if (authResponse.success && authResponse.accessToken != null) {
          await _saveAuthData(
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken,
            user: authResponse.user,
          );

          ApiService().setAuthToken(authResponse.accessToken!);
          print('✅ [AuthService] OTP login successful, token saved');
        } else {
          print(
            '❌ [AuthService] OTP login failed - success: ${authResponse.success}, token: ${authResponse.accessToken}',
          );
        }

        return authResponse;
      }

      return AuthResponseModel(
        success: false,
        message: 'Xác thực OTP thất bại',
      );
    } on DioException catch (e) {
      print('❌ OTP login error: ${e.message}');
      print('❌ OTP login response: ${e.response?.data}');
      return AuthResponseModel(success: false, message: _handleError(e));
    }
  }

  /// Request OTP - Supports both phone and email
  Future<Map<String, dynamic>> requestOTP({
    String? phone,
    String? email,
  }) async {
    try {
      if (phone == null && email == null) {
        return {
          'success': false,
          'message': 'Số điện thoại hoặc email là bắt buộc',
        };
      }

      final response = await _dio.post(
        '/auth/otp/request',
        data: {
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Mã OTP đã được gửi',
          'data': data['data'],
        };
      }

      return {'success': false, 'message': 'Gửi OTP thất bại'};
    } on DioException catch (e) {
      print('❌ Request OTP error: ${e.message}');

      // Handle specific error messages from backend
      if (e.response?.data != null && e.response!.data['error'] != null) {
        return {'success': false, 'message': e.response!.data['error']};
      }

      return {'success': false, 'message': _handleError(e)};
    }
  }

  /// Register new account
  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': 'CUSTOMER',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);

        if (authResponse.success && authResponse.accessToken != null) {
          await _saveAuthData(
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken,
            user: authResponse.user,
          );

          ApiService().setAuthToken(authResponse.accessToken!);
        }

        return authResponse;
      }

      return AuthResponseModel(success: false, message: 'Đăng ký thất bại');
    } on DioException catch (e) {
      print('❌ Register error: ${e.message}');
      return AuthResponseModel(success: false, message: _handleError(e));
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      print('❌ Logout error: $e');
    } finally {
      await _clearAuthData();
      ApiService().removeAuthToken();
    }
  }

  // ==================== PRIVATE HELPERS ====================

  Future<void> _saveAuthData({
    required String accessToken,
    String? refreshToken,
    UserModel? user,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);

    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }

    if (user != null) {
      // Convert user to JSON string
      final userJson = user.toJson();
      // Store each field separately for easier retrieval
      await _storage.write(
        key: '$_userDataKey.id',
        value: userJson['id'].toString(),
      );
      await _storage.write(
        key: '$_userDataKey.username',
        value: userJson['username'],
      );
      await _storage.write(
        key: '$_userDataKey.email',
        value: userJson['email'],
      );
      await _storage.write(
        key: '$_userDataKey.full_name',
        value: userJson['full_name'],
      );
      await _storage.write(key: '$_userDataKey.role', value: userJson['role']);

      // Store phone number
      if (userJson['phone_number'] != null) {
        await _storage.write(
          key: '$_userDataKey.phone',
          value: userJson['phone_number'].toString(),
        );
      }

      // Store avatar_url
      if (userJson['avatar_url'] != null) {
        await _storage.write(
          key: '$_userDataKey.avatar',
          value: userJson['avatar_url'].toString(),
        );
        print('✅ Saved avatar_url: ${userJson['avatar_url']}');
      }

      // Store customer_id (đảm bảo có giá trị)
      if (userJson['customer_id'] != null) {
        await _storage.write(
          key: '$_userDataKey.customer_id',
          value: userJson['customer_id'].toString(),
        );
        print('✅ Saved customer_id: ${userJson['customer_id']}');
      } else {
        print('⚠️ No customer_id in user data');
      }

      if (userJson['staff_id'] != null) {
        await _storage.write(
          key: '$_userDataKey.staff_id',
          value: userJson['staff_id'].toString(),
        );
      }
      if (userJson['admin_id'] != null) {
        await _storage.write(
          key: '$_userDataKey.admin_id',
          value: userJson['admin_id'].toString(),
        );
      }
    }
  }

  Future<void> _clearAuthData() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
  }

  String _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Kết nối quá thời gian chờ';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến server';
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      final message = error.response?.data['message'];

      if (statusCode == 401) return 'Sai tên đăng nhập hoặc mật khẩu';
      if (statusCode == 404) return 'Không tìm thấy tài khoản';
      if (statusCode == 409) return 'Tài khoản đã tồn tại';
      if (message != null) return message;

      return 'Lỗi từ server: $statusCode';
    }
    return 'Đã có lỗi xảy ra';
  }
}
