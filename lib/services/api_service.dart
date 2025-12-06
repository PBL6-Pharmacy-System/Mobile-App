import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  // ⚠️ QUAN TRỌNG: Thay đổi URL này thành URL Backend Node.js của bạn
  // Nếu test trên emulator: http://10.0.2.2:3000/api
  // Nếu test trên thiết bị thật: http://192.168.1.x:3000/api (IP máy tính của bạn)
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Cho Android emulator
  static const String baseUrl =
      'http://192.168.40.2:3000/api'; // Cho thiết bị thật (WiFi)
  // static const String baseUrl = 'http://192.168.40.2:3000/api'; // Cho Ethernet
  // static const String baseUrl = 'http://localhost:3000/api'; // Cho iOS Simulator

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Giảm timeout cho trải nghiệm nhanh hơn
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Cho phép nén dữ liệu
          'Accept-Encoding': 'gzip, deflate',
        },
        // Tối ưu connection
        persistentConnection: true,
      ),
    );

    // Chỉ log khi debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) {
            debugPrint('🔵 API: $obj');
          },
        ),
      );
    }

    // Thêm retry interceptor cho các lỗi tạm thời
    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

  Dio get dio => _dio;

  // Thêm token nếu cần authentication
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

/// Interceptor tự động retry khi gặp lỗi kết nối
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;

  _RetryInterceptor(this._dio, {int maxRetries = 2}) : _maxRetries = maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Chỉ retry với các lỗi kết nối tạm thời
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

      if (retryCount < _maxRetries) {
        err.requestOptions.extra['retryCount'] = retryCount + 1;

        // Đợi một chút trước khi retry
        final delay = 500 * (retryCount + 1) as int;
        await Future.delayed(Duration(milliseconds: delay));

        try {
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // Nếu retry thất bại, tiếp tục báo lỗi
        }
      }
    }
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        (err.type == DioExceptionType.connectionError && err.error != null);
  }
}
