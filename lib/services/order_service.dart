import 'package:dio/dio.dart';
import 'package:pharmacy_app/models/order_model.dart';
import 'package:pharmacy_app/services/api_service.dart';

class OrderService {
  final Dio _dio = ApiService().dio;

  /// Lấy danh sách đơn hàng của khách hàng
  Future<List<OrderModel>> getMyOrders({
    required int customerId,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      print('📋 [OrderService] Fetching orders for customer: $customerId');
      print('📋 [OrderService] API URL: /customers/$customerId/orders');

      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _dio.get(
        '/customers/$customerId/orders',
        queryParameters: queryParams,
      );

      print('📋 [OrderService] Response status: ${response.statusCode}');
      print('📋 [OrderService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Backend returns { orders: [...], pagination: {...} } directly (without success wrapper)
        // Or { success: true, data: { orders: [...] } } in some cases
        List<dynamic>? orderList;

        if (data['orders'] != null) {
          // Direct format: { orders: [...], pagination: {...} }
          orderList = data['orders'];
        } else if (data['success'] == true && data['data'] != null) {
          // Wrapped format: { success: true, data: { orders: [...] } }
          orderList = data['data']['orders'] ?? data['data'];
        }

        if (orderList != null) {
          print('✅ [OrderService] Found ${orderList.length} orders');
          return orderList.map((json) => OrderModel.fromJson(json)).toList();
        }
      }

      print('⚠️ [OrderService] No orders found in response');
      return [];
    } on DioException catch (e) {
      print('❌ [OrderService] Get orders error: ${e.message}');
      print('❌ [OrderService] Response: ${e.response?.data}');
      return [];
    }
  }

  /// Lấy chi tiết đơn hàng
  Future<OrderModel?> getOrderDetail(int orderId) async {
    try {
      print('📋 [OrderService] Fetching order detail: $orderId');

      final response = await _dio.get('/orders/$orderId');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          print('✅ [OrderService] Order detail loaded');
          return OrderModel.fromJson(data['data']);
        }
      }

      return null;
    } on DioException catch (e) {
      print('❌ [OrderService] Get order detail error: ${e.message}');
      return null;
    }
  }

  /// Checkout giỏ hàng thành đơn hàng
  Future<Map<String, dynamic>> checkout({
    required int customerId,
    required int shippingAddressId,
    required String paymentMethod, // 'COD', 'VNPAY', 'MOMO'
    String? voucherCode,
    String? note,
  }) async {
    try {
      print('📋 [OrderService] Creating order via checkout');

      final response = await _dio.post(
        '/cart/checkout',
        data: {
          'customerId': customerId,
          'shippingAddressId': shippingAddressId,
          'paymentMethod': paymentMethod,
          if (voucherCode != null) 'voucherCode': voucherCode,
          if (note != null) 'note': note,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          print('✅ [OrderService] Checkout successful');
          return {
            'success': true,
            'orderId': data['data']['orderId'] ?? data['data']['id'],
            'order': data['data']['order'] != null
                ? OrderModel.fromJson(data['data']['order'])
                : null,
            'paymentUrl': data['data']['paymentUrl'], // Nếu là VNPay/Momo
            'message': data['message'] ?? 'Đặt hàng thành công',
          };
        }
      }

      return {'success': false, 'message': 'Đặt hàng thất bại'};
    } on DioException catch (e) {
      print('❌ [OrderService] Checkout error: ${e.message}');
      return {'success': false, 'message': _handleError(e)};
    }
  }

  /// Hủy đơn hàng
  Future<Map<String, dynamic>> cancelOrder({
    required int orderId,
    String? reason,
  }) async {
    try {
      print('📋 [OrderService] Cancelling order: $orderId');

      final response = await _dio.post(
        '/orders/$orderId/cancel',
        data: {if (reason != null) 'reason': reason},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          print('✅ [OrderService] Order cancelled successfully');
          return {
            'success': true,
            'message': data['message'] ?? 'Đã hủy đơn hàng',
          };
        }
      }

      return {'success': false, 'message': 'Không thể hủy đơn hàng'};
    } on DioException catch (e) {
      print('❌ [OrderService] Cancel order error: ${e.message}');
      return {'success': false, 'message': _handleError(e)};
    }
  }

  /// Lấy thống kê đơn hàng (số lượng theo status)
  Future<Map<String, int>> getOrderStats(int customerId) async {
    try {
      final response = await _dio.get('/customers/$customerId/orders/stats');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? {};
        return {
          'pending': data['pending'] ?? 0,
          'processing': data['processing'] ?? 0,
          'shipping': data['shipping'] ?? 0,
          'completed': data['completed'] ?? 0,
          'cancelled': data['cancelled'] ?? 0,
        };
      }

      return {};
    } on DioException catch (e) {
      print('❌ [OrderService] Get order stats error: ${e.message}');
      return {};
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

      if (statusCode == 404) return 'Không tìm thấy đơn hàng';
      if (statusCode == 400) return message ?? 'Dữ liệu không hợp lệ';
      if (statusCode == 403) return 'Không thể hủy đơn hàng này';
      if (message != null) return message;

      return 'Lỗi từ server: $statusCode';
    }
    return 'Đã có lỗi xảy ra';
  }
}
