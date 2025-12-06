import 'package:dio/dio.dart';
import 'package:pharmacy_app/models/cart_model.dart';
import 'package:pharmacy_app/services/api_service.dart';

class CartService {
  final Dio _dio = ApiService().dio;

  /// Get cart của khách hàng
  Future<CartModel?> getCart(int customerId) async {
    try {
      print('📦 [CartService] ============================');
      print('📦 [CartService] Fetching cart for customer: $customerId');
      print('📦 [CartService] API URL: /cart/$customerId');

      final response = await _dio.get('/cart/$customerId');

      print('📦 [CartService] Response status: ${response.statusCode}');
      print('📦 [CartService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          print('📦 [CartService] Cart data: ${data['data']}');
          final cart = CartModel.fromJson(data['data']);
          print(
            '📦 [CartService] Parsed cart items count: ${cart.items.length}',
          );
          return cart;
        }
      }

      return null;
    } on DioException catch (e) {
      print('❌ [CartService] Get cart error: ${e.message}');
      print('❌ [CartService] Status code: ${e.response?.statusCode}');
      print('❌ [CartService] Response: ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        // Cart chưa tồn tại, return null
        return null;
      }
      rethrow;
    }
  }

  /// Lấy tóm tắt giỏ hàng (số lượng items, tổng tiền)
  Future<Map<String, dynamic>> getCartSummary(int customerId) async {
    try {
      final response = await _dio.get('/cart/$customerId/summary');

      if (response.statusCode == 200) {
        return response.data['data'] ?? {};
      }

      return {'itemCount': 0, 'totalAmount': 0.0};
    } on DioException catch (e) {
      print('❌ [CartService] Get cart summary error: ${e.message}');
      return {'itemCount': 0, 'totalAmount': 0.0};
    }
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<bool> addToCart({
    required int customerId,
    required int productId,
    required int productUnitId,
    required int quantity,
    double? unitPrice,
    int? branchId,
  }) async {
    try {
      print(
        '📦 [CartService] Adding to cart: productId=$productId, productUnitId=$productUnitId, quantity=$quantity',
      );

      final response = await _dio.post(
        '/cart/$customerId/add',
        data: {
          'productId': productId,
          'productUnitId': productUnitId,
          'quantity': quantity,
          if (unitPrice != null) 'unitPrice': unitPrice,
          if (branchId != null) 'branchId': branchId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          print('✅ [CartService] Added to cart successfully');
          return true;
        }
      }

      return false;
    } on DioException catch (e) {
      print('❌ [CartService] Add to cart error: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      // Throw error message from backend
      if (e.response?.data != null && e.response!.data['error'] != null) {
        throw e.response!.data['error'];
      }

      throw _handleError(e);
    }
  }

  /// Cập nhật số lượng item trong giỏ
  Future<CartModel?> updateCartItem({
    required int customerId,
    required int itemId,
    required int quantity,
  }) async {
    try {
      print(
        '📦 [CartService] Updating cart item: itemId=$itemId, quantity=$quantity',
      );

      final response = await _dio.put(
        '/cart/$customerId/items/$itemId',
        data: {'quantity': quantity},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          print('✅ [CartService] Updated cart item successfully');
          return CartModel.fromJson(data['data']);
        }
      }

      return null;
    } on DioException catch (e) {
      print('❌ [CartService] Update cart item error: ${e.message}');
      throw _handleError(e);
    }
  }

  /// Xóa item khỏi giỏ hàng
  Future<bool> removeCartItem({
    required int customerId,
    required int itemId,
  }) async {
    try {
      print('📦 [CartService] ============================');
      print(
        '📦 [CartService] Removing cart item: customerId=$customerId, itemId=$itemId',
      );
      print('📦 [CartService] API URL: /cart/$customerId/items/$itemId');

      final response = await _dio.delete('/cart/$customerId/items/$itemId');

      print('📦 [CartService] Response status: ${response.statusCode}');
      print('📦 [CartService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          print('✅ [CartService] Removed cart item successfully');
          return true;
        }
      }

      return false;
    } on DioException catch (e) {
      print('❌ [CartService] Remove cart item error: ${e.message}');
      print('❌ [CartService] Response: ${e.response?.data}');

      // Throw error message from backend
      if (e.response?.data != null && e.response!.data['error'] != null) {
        throw e.response!.data['error'];
      }

      throw _handleError(e);
    }
  }

  /// Xóa toàn bộ giỏ hàng
  Future<bool> clearCart(int customerId) async {
    try {
      print('📦 [CartService] Clearing cart for customer: $customerId');

      final response = await _dio.delete('/cart/$customerId/clear');

      if (response.statusCode == 200) {
        print('✅ [CartService] Cleared cart successfully');
        return true;
      }

      return false;
    } on DioException catch (e) {
      print('❌ [CartService] Clear cart error: ${e.message}');
      return false;
    }
  }

  /// Preview áp dụng voucher (không lưu)
  Future<Map<String, dynamic>> previewVoucher({
    required int customerId,
    required String voucherCode,
  }) async {
    try {
      print('📦 [CartService] Previewing voucher: $voucherCode');

      final response = await _dio.post(
        '/cart/$customerId/voucher/preview',
        data: {'voucherCode': voucherCode},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          print('✅ [CartService] Voucher preview successful');
          return {
            'valid': true,
            'voucherCode': voucherCode,
            'discountAmount': data['data']['discountAmount'] ?? 0.0,
            'finalAmount': data['data']['finalAmount'] ?? 0.0,
            'message': data['message'],
          };
        }
      }

      return {'valid': false, 'message': 'Mã voucher không hợp lệ'};
    } on DioException catch (e) {
      print('❌ [CartService] Preview voucher error: ${e.message}');
      return {'valid': false, 'message': _handleError(e)};
    }
  }

  String _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Kết nối quá thời gian chờ';
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến server';
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      final message = error.response?.data['message'];

      if (statusCode == 404) return 'Không tìm thấy sản phẩm';
      if (statusCode == 400) return message ?? 'Dữ liệu không hợp lệ';
      if (statusCode == 409) return 'Sản phẩm đã hết hàng';
      if (message != null) return message;

      return 'Lỗi từ server: $statusCode';
    }
    return 'Đã có lỗi xảy ra';
  }
}
