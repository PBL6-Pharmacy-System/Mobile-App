import 'package:dio/dio.dart';
import 'package:pharmacy_app/models/address_model.dart';
import 'package:pharmacy_app/models/order_model.dart';
import 'package:pharmacy_app/models/voucher_model.dart';
import 'package:pharmacy_app/services/api_service.dart';

class CheckoutService {
  final Dio _dio = ApiService().dio;

  /// Lấy danh sách voucher có thể dùng
  Future<List<VoucherModel>> getAvailableVouchers() async {
    try {
      print('🎫 [CheckoutService] Fetching available vouchers');

      final response = await _dio.get('/vouchers/available');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          final vouchersData = data['data']['vouchers'] ?? data['data'];
          if (vouchersData is List) {
            print('🎫 [CheckoutService] Found ${vouchersData.length} vouchers');
            return vouchersData
                .map((json) => VoucherModel.fromJson(json))
                .toList();
          }
        }
      }

      return [];
    } on DioException catch (e) {
      print('❌ [CheckoutService] Get vouchers error: ${e.message}');
      return [];
    }
  }

  /// Lấy danh sách địa chỉ giao hàng của khách hàng
  Future<List<AddressModel>> getAddresses(int customerId) async {
    try {
      print(
        '📍 [CheckoutService] Fetching addresses for customer: $customerId',
      );

      final response = await _dio.get(
        '/customers/$customerId/shipping-addresses',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> addressList = data['data'];
          print('📍 [CheckoutService] Found ${addressList.length} addresses');
          return addressList
              .map((json) => AddressModel.fromJson(json))
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      print('❌ [CheckoutService] Get addresses error: ${e.message}');
      return [];
    }
  }

  /// Tạo địa chỉ giao hàng mới
  Future<AddressModel?> createAddress({
    required int customerId,
    required String recipientName,
    required String recipientPhone,
    required String addressLine,
    required String city,
    String? state,
    String? postalCode,
    bool isDefault = false,
  }) async {
    try {
      print(
        '📍 [CheckoutService] Creating new address for customer: $customerId',
      );

      final response = await _dio.post(
        '/customers/$customerId/shipping-addresses',
        data: {
          'recipient_name': recipientName,
          'recipient_phone': recipientPhone,
          'address_line': addressLine,
          'city': city,
          'state': state,
          'postal_code': postalCode,
          'is_default': isDefault,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          print('✅ [CheckoutService] Address created successfully');
          return AddressModel.fromJson(data['data']);
        }
      }

      return null;
    } on DioException catch (e) {
      print('❌ [CheckoutService] Create address error: ${e.message}');
      if (e.response?.data != null && e.response!.data['error'] != null) {
        throw e.response!.data['error'];
      }
      throw 'Không thể tạo địa chỉ mới';
    }
  }

  /// Checkout - Đặt hàng
  Future<CheckoutResult> checkout({
    required int shippingAddressId,
    required String paymentMethod,
    String? voucherCode,
    String? note,
  }) async {
    try {
      print('🛒 [CheckoutService] ============================');
      print('🛒 [CheckoutService] Starting checkout');
      print('🛒 [CheckoutService] shippingAddressId: $shippingAddressId');
      print('🛒 [CheckoutService] paymentMethod: $paymentMethod');
      print('🛒 [CheckoutService] voucherCode: $voucherCode');

      final response = await _dio.post(
        '/cart/checkout',
        data: {
          'shippingAddressId': shippingAddressId,
          'paymentMethod': paymentMethod,
          if (voucherCode != null && voucherCode.isNotEmpty)
            'voucherCode': voucherCode,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );

      print('🛒 [CheckoutService] Response status: ${response.statusCode}');
      print('🛒 [CheckoutService] Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          print('✅ [CheckoutService] Checkout successful');

          // Parse order from response
          OrderModel? order;
          if (data['data'] != null && data['data']['order'] != null) {
            order = _parseOrderFromResponse(data['data']['order']);
          }

          // Check if online payment is required
          String? paymentUrl;
          if (data['data'] != null && data['data']['paymentUrl'] != null) {
            paymentUrl = data['data']['paymentUrl'];
          }

          return CheckoutResult(
            success: true,
            message: data['message'] ?? 'Đặt hàng thành công',
            order: order,
            paymentUrl: paymentUrl,
          );
        } else {
          return CheckoutResult(
            success: false,
            message: data['error'] ?? 'Đặt hàng thất bại',
          );
        }
      }

      return CheckoutResult(success: false, message: 'Đặt hàng thất bại');
    } on DioException catch (e) {
      print('❌ [CheckoutService] Checkout error: ${e.message}');
      print('❌ [CheckoutService] Response: ${e.response?.data}');

      String errorMessage = 'Đặt hàng thất bại';
      if (e.response?.data != null) {
        errorMessage = e.response!.data['error'] ?? errorMessage;
      }

      return CheckoutResult(success: false, message: errorMessage);
    }
  }

  OrderModel _parseOrderFromResponse(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      voucherId: json['voucher_id'],
      status: json['status'] ?? 'pending',
      totalAmount: _parseDouble(json['total_amount']),
      discountAmount: _parseDouble(json['discount_amount']),
      finalAmount: _parseDouble(json['final_amount']),
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Preview voucher (kiểm tra voucher trước khi checkout)
  Future<VoucherPreviewResult> previewVoucher({
    required int customerId,
    required String voucherCode,
  }) async {
    try {
      print('🎫 [CheckoutService] Previewing voucher: $voucherCode');

      final response = await _dio.post(
        '/cart/$customerId/voucher/preview',
        data: {'voucherCode': voucherCode},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          return VoucherPreviewResult(
            valid: true,
            discountAmount: _parseDouble(data['data']?['discountAmount']),
            finalAmount: _parseDouble(data['data']?['finalAmount']),
            message: data['message'] ?? 'Voucher hợp lệ',
          );
        } else {
          return VoucherPreviewResult(
            valid: false,
            message: data['error'] ?? 'Voucher không hợp lệ',
          );
        }
      }

      return VoucherPreviewResult(
        valid: false,
        message: 'Voucher không hợp lệ',
      );
    } on DioException catch (e) {
      print('❌ [CheckoutService] Preview voucher error: ${e.message}');
      String errorMessage = 'Không thể kiểm tra voucher';
      if (e.response?.data != null && e.response!.data['error'] != null) {
        errorMessage = e.response!.data['error'];
      }
      return VoucherPreviewResult(valid: false, message: errorMessage);
    }
  }

  /// Kiểm tra mã voucher bằng API /vouchers/check/:code
  Future<VoucherCheckResult> checkVoucherCode({
    required String voucherCode,
    required double orderAmount,
  }) async {
    try {
      print('🎫 [CheckoutService] Checking voucher code: $voucherCode');
      print('🎫 [CheckoutService] Order amount: $orderAmount');

      final response = await _dio.get(
        '/vouchers/check/${voucherCode.trim().toUpperCase()}',
        queryParameters: {'orderAmount': orderAmount},
      );

      print('🎫 [CheckoutService] Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          final voucherData = data['data']['voucher'];
          final isValid = data['data']['isValid'] == true;
          final estimatedDiscount = _parseDouble(
            data['data']['estimatedDiscount'],
          );

          if (isValid && voucherData != null) {
            // Tính lại discount nếu API không trả về
            double discount = estimatedDiscount;
            if (discount == 0 && voucherData != null) {
              final discountType = voucherData['discount_type'];
              final discountValue = _parseDouble(voucherData['discount_value']);

              if (discountType == 'percentage') {
                discount = (orderAmount * discountValue) / 100;
              } else {
                discount = discountValue;
              }
            }

            return VoucherCheckResult(
              valid: true,
              voucherCode: voucherData['code'] ?? voucherCode,
              discountType: voucherData['discount_type'] ?? 'fixed',
              discountValue: _parseDouble(voucherData['discount_value']),
              minOrderValue: voucherData['min_order_value'] != null
                  ? _parseDouble(voucherData['min_order_value'])
                  : null,
              estimatedDiscount: discount,
              message: data['data']['message'] ?? 'Voucher hợp lệ',
            );
          }
        }

        return VoucherCheckResult(
          valid: false,
          message: data['error'] ?? 'Voucher không hợp lệ',
        );
      }

      return VoucherCheckResult(valid: false, message: 'Voucher không hợp lệ');
    } on DioException catch (e) {
      print('❌ [CheckoutService] Check voucher error: ${e.message}');
      print('❌ [CheckoutService] Response: ${e.response?.data}');

      String errorMessage = 'Không thể kiểm tra voucher';
      if (e.response?.data != null && e.response!.data['error'] != null) {
        errorMessage = e.response!.data['error'];
      }
      return VoucherCheckResult(valid: false, message: errorMessage);
    }
  }

  /// Tạo thanh toán MoMo cho đơn hàng
  Future<MoMoPaymentResult> createMoMoPayment(int orderId) async {
    try {
      print('💜 [CheckoutService] Creating MoMo payment for order: $orderId');

      final response = await _dio.post(
        '/payments/momo/create-payment',
        data: {'orderId': orderId},
      );

      print('💜 [CheckoutService] MoMo Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          return MoMoPaymentResult(
            success: true,
            payUrl: data['data']['payUrl'],
            deeplink: data['data']['deeplink'],
            qrCodeUrl: data['data']['qrCodeUrl'],
            orderId: orderId,
            amount: data['data']['amount']?.toString(),
            message: data['message'] ?? 'Tạo thanh toán MoMo thành công',
          );
        }
      }

      return MoMoPaymentResult(
        success: false,
        message: response.data?['message'] ?? 'Không thể tạo thanh toán MoMo',
      );
    } on DioException catch (e) {
      print('❌ [CheckoutService] MoMo payment error: ${e.message}');
      print('❌ [CheckoutService] Response: ${e.response?.data}');

      String errorMessage = 'Không thể tạo thanh toán MoMo';
      if (e.response?.data != null && e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      return MoMoPaymentResult(success: false, message: errorMessage);
    }
  }
}

class CheckoutResult {
  final bool success;
  final String message;
  final OrderModel? order;
  final String? paymentUrl; // For online payment methods

  CheckoutResult({
    required this.success,
    required this.message,
    this.order,
    this.paymentUrl,
  });
}

class VoucherPreviewResult {
  final bool valid;
  final double discountAmount;
  final double finalAmount;
  final String message;

  VoucherPreviewResult({
    required this.valid,
    this.discountAmount = 0,
    this.finalAmount = 0,
    required this.message,
  });
}

class VoucherCheckResult {
  final bool valid;
  final String? voucherCode;
  final String? discountType; // 'percentage' hoặc 'fixed'
  final double? discountValue;
  final double? minOrderValue;
  final double estimatedDiscount;
  final String message;

  VoucherCheckResult({
    required this.valid,
    this.voucherCode,
    this.discountType,
    this.discountValue,
    this.minOrderValue,
    this.estimatedDiscount = 0,
    required this.message,
  });

  /// Tính toán số tiền giảm dựa trên tổng đơn hàng
  double calculateDiscount(double orderAmount) {
    if (!valid || discountType == null || discountValue == null) return 0;

    // Kiểm tra đơn hàng tối thiểu
    if (minOrderValue != null && orderAmount < minOrderValue!) return 0;

    if (discountType == 'percentage') {
      return (orderAmount * discountValue!) / 100;
    } else {
      // fixed
      return discountValue!;
    }
  }
}

class MoMoPaymentResult {
  final bool success;
  final String? payUrl; // URL thanh toán trên web
  final String? deeplink; // Deeplink mở app MoMo
  final String? qrCodeUrl; // URL QR code
  final int? orderId;
  final String? amount; // Số tiền thanh toán
  final String message;

  MoMoPaymentResult({
    required this.success,
    this.payUrl,
    this.deeplink,
    this.qrCodeUrl,
    this.orderId,
    this.amount,
    required this.message,
  });
}
