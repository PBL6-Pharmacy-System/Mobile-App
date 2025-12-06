import 'package:flutter/material.dart';
import 'package:pharmacy_app/models/user_model.dart';
import 'package:pharmacy_app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // State
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Constructor - check if user is already logged in
  AuthProvider() {
    _checkLoginStatus();
  }

  /// Check if user is already logged in on app start
  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedIn = await _authService.isLoggedIn();
      if (loggedIn) {
        // First load from local storage
        _currentUser = await _authService.getCurrentUser();
        _isLoggedIn = true;

        // Then fetch fresh data from API
        await refreshUser();
      }
    } catch (e) {
      print('❌ [AuthProvider] Check login status error: $e');
      _error = 'Không thể kiểm tra trạng thái đăng nhập';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user info from API /auth/me and update state
  Future<bool> refreshUser() async {
    try {
      print('🔄 [AuthProvider] Refreshing user from API...');
      final user = await _authService.fetchCurrentUser();

      if (user != null) {
        _currentUser = user;
        print(
          '✅ [AuthProvider] User refreshed: ${user.fullName}, customerId: ${user.customerId}',
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [AuthProvider] Refresh user error: $e');
      return false;
    }
  }

  /// Login with username/email and password
  Future<bool> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      if (response.success && response.user != null) {
        _currentUser = response.user;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [AuthProvider] Login error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login with OTP - Supports both phone and email
  Future<bool> loginWithOTP({
    String? phone,
    String? email,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.loginWithOTP(
        phone: phone,
        email: email,
        otp: otp,
      );

      if (response.success && response.user != null) {
        _currentUser = response.user;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [AuthProvider] OTP login error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request OTP - Supports both phone and email
  Future<Map<String, dynamic>> requestOTP({
    String? phone,
    String? email,
  }) async {
    try {
      return await _authService.requestOTP(phone: phone, email: email);
    } catch (e) {
      print('❌ [AuthProvider] Request OTP error: $e');
      return {'success': false, 'message': 'Không thể gửi mã OTP'};
    }
  }

  /// Register new account
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (response.success && response.user != null) {
        _currentUser = response.user;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [AuthProvider] Register error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _isLoggedIn = false;
      _error = null;
    } catch (e) {
      print('❌ [AuthProvider] Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
