import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;

  AuthResponseModel({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle both response formats:
    // 1. OTP login: {"success": true, "data": {"user": {...}, "token": "..."}}
    // 2. Regular: {"success": true, "user": {...}, "accessToken": "..."}

    final data = json['data'] as Map<String, dynamic>?;
    final hasDataWrapper = data != null;

    print('🔐 [AuthResponseModel] Raw JSON keys: ${json.keys}');
    print('🔐 [AuthResponseModel] Has data wrapper: $hasDataWrapper');
    if (hasDataWrapper && data['user'] != null) {
      print('🔐 [AuthResponseModel] User data: ${data['user']}');
    }

    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      // Try multiple token field names in priority order
      accessToken: hasDataWrapper
          ? (data['token'] ?? data['accessToken'] ?? data['access_token'])
          : (json['token'] ?? json['accessToken'] ?? json['access_token']),
      refreshToken: hasDataWrapper
          ? (data['refreshToken'] ?? data['refresh_token'])
          : (json['refreshToken'] ?? json['refresh_token']),
      user: hasDataWrapper && data['user'] != null
          ? UserModel.fromJson(data['user'])
          : (json['user'] != null ? UserModel.fromJson(json['user']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
    };
  }
}
