class OrderModel {
  final int id;
  final int customerId;
  final int? voucherId;
  final String status; // PENDING, PROCESSING, SHIPPING, COMPLETED, CANCELLED
  final double totalAmount; // Tổng tiền trước giảm
  final double discountAmount; // Số tiền được giảm từ voucher
  final double finalAmount; // Tổng tiền sau giảm (thanh toán thực tế)
  final DateTime orderDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated fields from API
  final List<OrderItemModel>? items;
  final List<PaymentInfo>? payments;
  final List<ShippingInfo>? shipments;
  final VoucherInfo? voucher;
  final String? cancelReason;
  final ShippingAddressInfo? shippingAddress; // Địa chỉ giao hàng

  OrderModel({
    required this.id,
    required this.customerId,
    this.voucherId,
    required this.status,
    required this.totalAmount,
    this.discountAmount = 0,
    double? finalAmount,
    required this.orderDate,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.payments,
    this.shipments,
    this.voucher,
    this.cancelReason,
    this.shippingAddress,
  }) : finalAmount = finalAmount ?? totalAmount;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Parse orderitems (API returns 'orderitems')
    List<OrderItemModel>? orderItems;
    if (json['orderitems'] != null) {
      orderItems = (json['orderitems'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList();
    } else if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList();
    }

    // Parse payments (API returns array 'payments')
    List<PaymentInfo>? paymentsList;
    if (json['payments'] != null) {
      paymentsList = (json['payments'] as List)
          .map((p) => PaymentInfo.fromJson(p))
          .toList();
    }

    // Parse shipments (API returns array 'shipments')
    List<ShippingInfo>? shipmentsList;
    if (json['shipments'] != null) {
      shipmentsList = (json['shipments'] as List)
          .map((s) => ShippingInfo.fromJson(s))
          .toList();
    }

    // Parse voucher info
    VoucherInfo? voucherInfo;
    if (json['vouchers'] != null) {
      voucherInfo = VoucherInfo.fromJson(json['vouchers']);
    }

    // Parse shipping address info
    ShippingAddressInfo? shippingAddressInfo;
    if (json['shippingaddresses'] != null) {
      shippingAddressInfo = ShippingAddressInfo.fromJson(
        json['shippingaddresses'],
      );
    }

    return OrderModel(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      voucherId: json['voucher_id'],
      status: json['status'] ?? 'PENDING',
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
      items: orderItems,
      payments: paymentsList,
      shipments: shipmentsList,
      voucher: voucherInfo,
      cancelReason: json['cancel_reason'],
      shippingAddress: shippingAddressInfo,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'voucher_id': voucherId,
      'status': status,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'order_date': orderDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items?.map((item) => item.toJson()).toList(),
      'payments': payments?.map((p) => p.toJson()).toList(),
      'shipments': shipments?.map((s) => s.toJson()).toList(),
      'voucher': voucher?.toJson(),
      'cancel_reason': cancelReason,
      'shippingaddresses': shippingAddress?.toJson(),
    };
  }

  // Get primary payment info
  PaymentInfo? get primaryPayment =>
      payments?.isNotEmpty == true ? payments!.first : null;

  // Get primary shipment info
  ShippingInfo? get primaryShipment =>
      shipments?.isNotEmpty == true ? shipments!.first : null;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isShipping => status.toLowerCase() == 'shipping';
  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isReturned => status.toLowerCase() == 'returned';

  // Can cancel if order is in early stages (pending or confirmed)
  bool get canCancel => isPending || isConfirmed;

  // Can return if order is delivered
  bool get canReturn => isDelivered;

  // Check if order is in active/processing state
  bool get isActive => isPending || isConfirmed || isProcessing || isShipping;

  // Check if order is finished (delivered, completed, cancelled, returned)
  bool get isFinished =>
      isDelivered || isCompleted || isCancelled || isReturned;
}

class OrderItemModel {
  final int id;
  final int orderId;
  final int productUnitId;
  final int quantity;
  final double price;
  final double subtotalAmount;

  // Product info from API
  final ProductInfo? product;
  final ProductUnitInfo? productUnit;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productUnitId,
    required this.quantity,
    required this.price,
    required this.subtotalAmount,
    this.product,
    this.productUnit,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productUnitId: json['product_unit_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: OrderModel._parseDouble(json['price']),
      subtotalAmount: OrderModel._parseDouble(json['subtotal']),
      product: json['products'] != null
          ? ProductInfo.fromJson(json['products'])
          : null,
      productUnit: json['productunits'] != null
          ? ProductUnitInfo.fromJson(json['productunits'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_unit_id': productUnitId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotalAmount,
    };
  }

  double get subtotal => subtotalAmount > 0 ? subtotalAmount : price * quantity;
}

class ProductInfo {
  final int id;
  final String name;
  final String? imageUrl;

  ProductInfo({required this.id, required this.name, this.imageUrl});

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image_url': imageUrl,
  };
}

class ProductUnitInfo {
  final int id;
  final String unitName;

  ProductUnitInfo({required this.id, required this.unitName});

  factory ProductUnitInfo.fromJson(Map<String, dynamic> json) {
    return ProductUnitInfo(
      id: json['id'] ?? 0,
      unitName: json['unit_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'unit_name': unitName};
}

class VoucherInfo {
  final String code;
  final String? discountType;
  final double discountValue;

  VoucherInfo({
    required this.code,
    this.discountType,
    required this.discountValue,
  });

  factory VoucherInfo.fromJson(Map<String, dynamic> json) {
    return VoucherInfo(
      code: json['code'] ?? '',
      discountType: json['discount_type'],
      discountValue: OrderModel._parseDouble(json['discount_value']),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'discount_type': discountType,
    'discount_value': discountValue,
  };
}

class PaymentInfo {
  final int id;
  final String method; // COD, VNPAY, MOMO
  final String status; // PENDING, COMPLETED, FAILED
  final double amount;
  final String? transactionId;
  final DateTime? paymentDate;

  PaymentInfo({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    this.transactionId,
    this.paymentDate,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'] ?? 0,
      method: json['payment_method'] ?? json['method'] ?? 'COD',
      status: json['status'] ?? 'PENDING',
      amount: OrderModel._parseDouble(json['amount']),
      transactionId: json['transaction_id'],
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_method': method,
      'status': status,
      'amount': amount,
      'transaction_id': transactionId,
      'payment_date': paymentDate?.toIso8601String(),
    };
  }

  bool get isPending => status == 'PENDING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';

  String get methodDisplay {
    switch (method.toUpperCase()) {
      case 'COD':
        return 'Thanh toán khi nhận hàng';
      case 'MOMO':
        return 'Ví MoMo';
      case 'VNPAY':
        return 'VNPay';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản ngân hàng';
      default:
        return method;
    }
  }
}

class ShippingInfo {
  final int id;
  final String? trackingNumber;
  final String status; // PREPARING, SHIPPED, IN_TRANSIT, DELIVERED
  final DateTime? estimatedDelivery;

  ShippingInfo({
    required this.id,
    this.trackingNumber,
    required this.status,
    this.estimatedDelivery,
  });

  factory ShippingInfo.fromJson(Map<String, dynamic> json) {
    return ShippingInfo(
      id: json['id'] ?? 0,
      trackingNumber: json['tracking_number'],
      status: json['status'] ?? 'PREPARING',
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.parse(json['estimated_delivery'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'status': status,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PREPARING':
        return 'Đang chuẩn bị';
      case 'SHIPPED':
        return 'Đã giao cho ĐVVC';
      case 'IN_TRANSIT':
        return 'Đang vận chuyển';
      case 'DELIVERED':
        return 'Đã giao hàng';
      default:
        return status;
    }
  }
}

/// Thông tin địa chỉ giao hàng
class ShippingAddressInfo {
  final int id;
  final String recipientName;
  final String recipientPhone;
  final String addressLine;
  final String? ward;
  final String? district;
  final String? city;

  ShippingAddressInfo({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.addressLine,
    this.ward,
    this.district,
    this.city,
  });

  factory ShippingAddressInfo.fromJson(Map<String, dynamic> json) {
    return ShippingAddressInfo(
      id: json['id'] ?? 0,
      recipientName: json['recipient_name'] ?? '',
      recipientPhone: json['recipient_phone'] ?? '',
      addressLine: json['address_line'] ?? '',
      ward: json['ward'],
      district: json['district'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'address_line': addressLine,
      'ward': ward,
      'district': district,
      'city': city,
    };
  }

  /// Địa chỉ đầy đủ
  String get fullAddress {
    final parts = <String>[];
    if (addressLine.isNotEmpty) parts.add(addressLine);
    if (ward != null && ward!.isNotEmpty) parts.add(ward!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    return parts.join(', ');
  }
}
