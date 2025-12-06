import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/home_screen.dart';
import 'package:pharmacy_app/models/order_model.dart';
import 'package:pharmacy_app/services/order_service.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderService _orderService = OrderService();

  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final order = await _orderService.getOrderDetail(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải chi tiết đơn hàng: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết đơn hàng #${widget.orderId}',
          style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Check if we can pop, otherwise go to HomeScreen
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2979FF), Color(0xFF448AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _order == null
          ? _buildNotFoundView()
          : RefreshIndicator(
              onRefresh: _loadOrderDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildStatusSection(),
                    _buildOrderItemsSection(),
                    _buildShippingSection(),
                    _buildPaymentSection(),
                    _buildOrderSummarySection(),
                    _buildActionButtons(),
                    Gap.xlHeight,
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    final List<Widget> buttons = [];

    // Cancel button - for pending/confirmed orders
    if (_order!.canCancel) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showCancelDialog,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Hủy đơn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    // Confirm received button - for delivered orders
    if (_order!.isDelivered) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmReceived,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Đã nhận hàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    // Return button - for delivered orders
    if (_order!.isDelivered) {
      if (buttons.isNotEmpty) buttons.add(Gap.smWidth);
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showReturnDialog,
            icon: const Icon(Icons.assignment_return_outlined, size: 18),
            label: const Text('Trả hàng'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.brown,
              side: const BorderSide(color: Colors.brown),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    // Reorder button - for completed/cancelled/returned orders
    if (_order!.isCompleted || _order!.isCancelled || _order!.isReturned) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _reorder,
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Mua lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: buttons),
    );
  }

  Future<void> _confirmReceived() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đã nhận hàng'),
        content: const Text(
          'Bạn xác nhận đã nhận được đơn hàng này? '
          'Sau khi xác nhận, đơn hàng sẽ được hoàn thành.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Call API to confirm received
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận nhận hàng thành công'),
          backgroundColor: Colors.green,
        ),
      );
      _loadOrderDetail();
    }
  }

  void _showReturnDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu trả hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng cho biết lý do bạn muốn trả hàng:'),
            Gap.mdHeight,
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do trả hàng',
                border: OutlineInputBorder(),
                hintText: 'VD: Sản phẩm bị lỗi, không đúng mô tả...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do trả hàng'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              // TODO: Call API to request return
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi yêu cầu trả hàng'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadOrderDetail();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  void _reorder() {
    // TODO: Add items to cart and navigate to cart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm sản phẩm vào giỏ hàng'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          Gap.mdHeight,
          Text(
            _errorMessage!,
            style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          Gap.mdHeight,
          ElevatedButton(
            onPressed: _loadOrderDetail,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          Gap.mdHeight,
          Text(
            'Không tìm thấy đơn hàng',
            style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final statusInfo = _getStatusInfo(_order!.status);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã đơn: #${_order!.id}',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusInfo['text'],
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusInfo['color'],
                  ),
                ),
              ),
            ],
          ),
          Gap.smHeight,
          Text(
            'Ngày đặt: ${dateFormat.format(_order!.orderDate)}',
            style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),

          // Order status timeline - always show
          Gap.mdHeight,
          const Divider(),
          Gap.smHeight,
          _buildStatusTimeline(),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    // Show timeline based on order status
    final status = _order!.status.toLowerCase();

    // Handle cancelled/returned orders separately
    if (status == 'cancelled') {
      return _buildCancelledTimeline();
    }
    if (status == 'returned') {
      return _buildReturnedTimeline();
    }

    final steps = [
      {'status': 'pending', 'label': 'Đặt hàng', 'icon': Icons.shopping_cart},
      {'status': 'confirmed', 'label': 'Xác nhận', 'icon': Icons.check},
      {'status': 'processing', 'label': 'Xử lý', 'icon': Icons.inventory_2},
      {
        'status': 'shipping',
        'label': 'Giao hàng',
        'icon': Icons.local_shipping,
      },
      {'status': 'delivered', 'label': 'Đã giao', 'icon': Icons.done_all},
      {
        'status': 'completed',
        'label': 'Hoàn thành',
        'icon': Icons.check_circle,
      },
    ];

    // Determine current step index
    int currentStep = 0;
    switch (status) {
      case 'pending':
        currentStep = 0;
        break;
      case 'confirmed':
        currentStep = 1;
        break;
      case 'processing':
        currentStep = 2;
        break;
      case 'shipping':
        currentStep = 3;
        break;
      case 'delivered':
        currentStep = 4;
        break;
      case 'completed':
        currentStep = 5;
        break;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index <= currentStep;
          final isActive = index == currentStep;

          return Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? primaryColor.withAlpha(isActive ? 255 : 180)
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step['icon'] as IconData,
                    color: isCompleted ? Colors.white : Colors.grey[400],
                    size: isActive ? 22 : 18,
                  ),
                ),
                Gap.xsHeight,
                Text(
                  step['label'] as String,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: isCompleted ? primaryColor : Colors.grey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCancelledTimeline() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 24),
          Gap.smWidth,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn hàng đã bị hủy',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_order!.cancelReason != null)
                  Text(
                    'Lý do: ${_order!.cancelReason}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnedTimeline() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.brown.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_return, color: Colors.brown, size: 24),
          Gap.smWidth,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn hàng đã được trả lại',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Hoàn tiền sẽ được xử lý trong 3-5 ngày làm việc',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.brown[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    if (_order!.items == null || _order!.items!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: primaryColor, size: 20),
              Gap.smWidth,
              Text(
                'Sản phẩm (${_order!.items!.length})',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gap.mdHeight,
          ...(_order!.items!.map((item) => _buildOrderItem(item)).toList()),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.product?.imageUrl != null
                ? Image.network(
                    item.product!.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          Gap.mdWidth,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? 'Sản phẩm',
                  style: context.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap.xsHeight,
                Text(
                  'x${item.quantity}${item.productUnit != null ? ' ${item.productUnit!.unitName}' : ''}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(item.price),
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatCurrency(item.subtotal),
                style: context.textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.medication, color: Colors.grey),
    );
  }

  Widget _buildShippingSection() {
    final shipment = _order!.primaryShipment;
    final shippingAddress = _order!.shippingAddress;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: primaryColor,
                size: 20,
              ),
              Gap.smWidth,
              Text(
                'Thông tin vận chuyển',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gap.mdHeight,

          // Địa chỉ giao hàng
          if (shippingAddress != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: primaryColor, size: 18),
                      Gap.xsWidth,
                      Text(
                        'Địa chỉ nhận hàng',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Gap.smHeight,
                  Text(
                    shippingAddress.recipientName,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap.xsHeight,
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      Gap.xsWidth,
                      Text(
                        shippingAddress.recipientPhone,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Gap.xsHeight,
                  Text(
                    shippingAddress.fullAddress,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Gap.mdHeight,
          ],

          // Thông tin vận chuyển
          if (shipment != null) ...[
            _buildInfoRow('Trạng thái', shipment.statusDisplay),
            if (shipment.trackingNumber != null)
              _buildInfoRow('Mã vận đơn', shipment.trackingNumber!),
            if (shipment.estimatedDelivery != null)
              _buildInfoRow(
                'Dự kiến giao',
                DateFormat('dd/MM/yyyy').format(shipment.estimatedDelivery!),
              ),
          ] else ...[
            Text(
              'Đơn hàng đang được chuẩn bị',
              style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final payment = _order!.primaryPayment;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_outlined, color: primaryColor, size: 20),
              Gap.smWidth,
              Text(
                'Thông tin thanh toán',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gap.mdHeight,
          if (payment != null) ...[
            _buildInfoRow('Phương thức', payment.methodDisplay),
            _buildInfoRow(
              'Trạng thái',
              _getPaymentStatusText(payment.status),
              valueColor: _getPaymentStatusColor(payment.status),
            ),
            if (payment.transactionId != null)
              _buildInfoRow('Mã giao dịch', payment.transactionId!),
          ] else ...[
            Text(
              'Chưa có thông tin thanh toán',
              style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],

          // Voucher info
          if (_order!.voucher != null) ...[
            Gap.mdHeight,
            const Divider(),
            Gap.smHeight,
            _buildInfoRow(
              'Mã giảm giá',
              _order!.voucher!.code,
              valueColor: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    // Calculate subtotal from items
    double subtotal = 0;
    if (_order!.items != null) {
      for (var item in _order!.items!) {
        subtotal += item.subtotal;
      }
    }

    // Use discountAmount from API (not calculated)
    final discount = _order!.discountAmount;

    // finalAmount is the actual payment amount
    final finalAmount = _order!.finalAmount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_outlined, color: primaryColor, size: 20),
              Gap.smWidth,
              Text(
                'Tổng kết đơn hàng',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gap.mdHeight,
          _buildSummaryRow('Tạm tính', _formatCurrency(subtotal)),
          _buildSummaryRow('Phí vận chuyển', 'Miễn phí'),
          if (discount > 0)
            _buildSummaryRow(
              'Giảm giá${_order!.voucher != null ? ' (${_order!.voucher!.code})' : ''}',
              '-${_formatCurrency(discount)}',
              valueColor: Colors.green,
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatCurrency(finalAmount),
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textTheme.bodyMedium),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {'text': 'Chờ xác nhận', 'color': Colors.orange};
      case 'confirmed':
        return {'text': 'Đã xác nhận', 'color': Colors.blue};
      case 'processing':
        return {'text': 'Đang xử lý', 'color': Colors.indigo};
      case 'shipping':
        return {'text': 'Đang giao', 'color': Colors.purple};
      case 'delivered':
        return {'text': 'Đã giao', 'color': Colors.teal};
      case 'completed':
        return {'text': 'Hoàn thành', 'color': Colors.green};
      case 'cancelled':
        return {'text': 'Đã hủy', 'color': Colors.red};
      case 'returned':
        return {'text': 'Đã trả hàng', 'color': Colors.brown};
      default:
        return {'text': status, 'color': Colors.grey};
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'COMPLETED':
        return 'Đã thanh toán';
      case 'FAILED':
        return 'Thanh toán thất bại';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat('#,###', 'vi_VN');
    return '${format.format(amount)}đ';
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc muốn hủy đơn hàng #${_order!.id}?'),
            Gap.mdHeight,
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelOrder(reasonController.text);
            },
            child: Text('Hủy đơn', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(String reason) async {
    try {
      final result = await _orderService.cancelOrder(
        orderId: _order!.id,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đã hủy đơn hàng'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadOrderDetail(); // Reload detail
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Không thể hủy đơn hàng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
