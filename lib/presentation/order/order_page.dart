import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/order_model.dart';
import 'package:pharmacy_app/presentation/order/order_detail_page.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/services/order_service.dart';
import 'package:provider/provider.dart';

/// Order Status Constants (matching backend)
class OrderStatus {
  static const String cart = 'cart';
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String processing = 'processing';
  static const String shipping = 'shipping';
  static const String delivered = 'delivered';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String returned = 'returned';
}

class OrderPage extends StatefulWidget {
  final int initialTabIndex;

  const OrderPage({super.key, this.initialTabIndex = 0});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();

  // Mỗi tab có danh sách đơn hàng riêng
  final Map<int, List<OrderModel>> _ordersByTab = {};
  final Map<int, bool> _isLoadingByTab = {};
  final Map<int, String?> _errorByTab = {};

  int? _customerId;

  // Tab definitions with status filters
  static const List<Map<String, dynamic>> _tabs = [
    {
      'label': 'Chờ xác nhận',
      'icon': Icons.hourglass_empty,
      'statuses': [OrderStatus.pending],
    },
    {
      'label': 'Đang xử lý',
      'icon': Icons.inventory_2_outlined,
      'statuses': [OrderStatus.confirmed, OrderStatus.processing],
    },
    {
      'label': 'Đang giao',
      'icon': Icons.local_shipping_outlined,
      'statuses': [OrderStatus.shipping],
    },
    {
      'label': 'Đã giao',
      'icon': Icons.check_circle_outline,
      'statuses': [OrderStatus.delivered, OrderStatus.completed],
    },
    {
      'label': 'Đã hủy',
      'icon': Icons.cancel_outlined,
      'statuses': [OrderStatus.cancelled, OrderStatus.returned],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    // Khởi tạo state cho mỗi tab
    for (int i = 0; i < _tabs.length; i++) {
      _ordersByTab[i] = [];
      _isLoadingByTab[i] = false;
      _errorByTab[i] = null;
    }

    // Lắng nghe khi tab thay đổi
    _tabController.addListener(_onTabChanged);

    // Load đơn hàng cho tab đầu tiên
    _initCustomerAndLoadOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tabIndex = _tabController.index;
      // Load đơn hàng nếu tab chưa được load
      if (_ordersByTab[tabIndex]!.isEmpty && !_isLoadingByTab[tabIndex]!) {
        _loadOrdersForTab(tabIndex);
      }
    }
  }

  Future<void> _initCustomerAndLoadOrders() async {
    final authProvider = context.read<AuthProvider>();
    _customerId = authProvider.currentUser?.customerId;

    print('🔍 [OrderPage] _initCustomerAndLoadOrders');
    print('🔍 [OrderPage] isLoggedIn: ${authProvider.isLoggedIn}');
    print('🔍 [OrderPage] currentUser: ${authProvider.currentUser}');
    print('🔍 [OrderPage] customerId: $_customerId');
    print('🔍 [OrderPage] userId: ${authProvider.currentUser?.id}');

    if (_customerId == null) {
      for (int i = 0; i < _tabs.length; i++) {
        setState(() {
          _errorByTab[i] = 'Vui lòng đăng nhập để xem đơn hàng';
        });
      }
      return;
    }

    // Load tab đầu tiên
    _loadOrdersForTab(widget.initialTabIndex);
  }

  Future<void> _loadOrdersForTab(
    int tabIndex, {
    bool forceRefresh = false,
  }) async {
    if (_customerId == null) return;
    if (_isLoadingByTab[tabIndex] == true && !forceRefresh) return;

    setState(() {
      _isLoadingByTab[tabIndex] = true;
      _errorByTab[tabIndex] = null;
    });

    try {
      final statuses = _tabs[tabIndex]['statuses'] as List<String>;
      final statusFilter = statuses.join(',');

      print(
        '🔍 [OrderPage] Loading orders for tab $tabIndex with statuses: $statusFilter',
      );

      final orders = await _orderService.getMyOrders(
        customerId: _customerId!,
        status: statusFilter,
        limit: 50,
      );

      print('✅ [OrderPage] Loaded ${orders.length} orders for tab $tabIndex');

      setState(() {
        _ordersByTab[tabIndex] = orders;
        _isLoadingByTab[tabIndex] = false;
      });
    } catch (e) {
      print('❌ [OrderPage] Error loading tab $tabIndex: $e');
      setState(() {
        _isLoadingByTab[tabIndex] = false;
        _errorByTab[tabIndex] = 'Không thể tải đơn hàng: $e';
      });
    }
  }

  Future<void> _refreshCurrentTab() async {
    await _loadOrdersForTab(_tabController.index, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Đơn hàng của tôi',
          style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              controller: _tabController,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              tabs: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final count = _getTabOrderCount(index);
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(tab['icon'] as IconData, size: 16),
                      const SizedBox(width: 4),
                      Text('${tab['label']}${count > 0 ? ' ($count)' : ''}'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryLightColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.asMap().entries.map((entry) {
          final tabIndex = entry.key;
          return _buildTabContent(tabIndex);
        }).toList(),
      ),
    );
  }

  int _getTabOrderCount(int tabIndex) {
    return _ordersByTab[tabIndex]?.length ?? 0;
  }

  Widget _buildTabContent(int tabIndex) {
    final isLoading = _isLoadingByTab[tabIndex] ?? false;
    final error = _errorByTab[tabIndex];
    final orders = _ordersByTab[tabIndex] ?? [];

    if (isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && orders.isEmpty) {
      return _buildErrorView(tabIndex, error);
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrdersForTab(tabIndex, forceRefresh: true),
      child: _buildOrderList(orders),
    );
  }

  Widget _buildErrorView(int tabIndex, String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          Gap.mdHeight,
          Text(
            errorMessage,
            style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          Gap.mdHeight,
          ElevatedButton(
            onPressed: () => _loadOrdersForTab(tabIndex, forceRefresh: true),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            Gap.mdHeight,
            Text(
              'Không có đơn hàng nào',
              style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _orderCard(order);
      },
    );
  }

  Widget _orderCard(OrderModel order) {
    final statusInfo = _getStatusInfo(order.status);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
        ).then((_) => _refreshCurrentTab()); // Reload after returning
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trạng thái đơn hàng - sát lề trái màn hình (không padding)
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusInfo['color'].withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusInfo['text'],
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusInfo['color'],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Card đơn hàng - có padding trái
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              margin: const EdgeInsets.only(bottom: Gap.md),
              padding: const EdgeInsets.all(Gap.md),
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
                  // Header - Mã đơn và ngày đặt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mã đơn: #${order.id}',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dateFormat.format(order.orderDate),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Gap.mdHeight,

                  // Order items preview
                  if (order.items != null && order.items!.isNotEmpty)
                    Column(
                      children: order.items!
                          .take(2)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: Gap.sm),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: item.product?.imageUrl != null
                                        ? Image.network(
                                            item.product!.imageUrl!,
                                            width: Gap.xxl,
                                            height: Gap.xxl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: Gap.xxl,
                                                  height: Gap.xxl,
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.medication,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: Gap.xxl,
                                            height: Gap.xxl,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.medication,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                  Gap.sMWidth,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product?.name ?? 'Sản phẩm',
                                          style: context.textTheme.titleSmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'x${item.quantity}${item.productUnit != null ? ' ${item.productUnit!.unitName}' : ''}',
                                          style: context.textTheme.labelSmall
                                              ?.copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  if (order.items != null && order.items!.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: Text(
                        '+ ${order.items!.length - 2} sản phẩm khác',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  const Divider(),

                  // Total & Payment info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng tiền:',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                            ),
                          ),
                          if (order.primaryPayment != null)
                            Text(
                              order.primaryPayment!.methodDisplay,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Hiển thị giá gốc và giảm giá nếu có voucher
                          if (order.discountAmount > 0) ...[
                            Text(
                              _formatCurrency(order.totalAmount),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              '-${_formatCurrency(order.discountAmount)}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          Text(
                            _formatCurrency(order.finalAmount),
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Gap.smHeight,

                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (order.canCancel)
                        TextButton(
                          onPressed: () => _showCancelDialog(order),
                          child: Text(
                            'Hủy đơn',
                            style: TextStyle(color: Colors.red[400]),
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailPage(orderId: order.id),
                            ),
                          );
                        },
                        child: const Text('Chi tiết'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'text': 'Chờ xác nhận',
          'color': Colors.orange,
          'icon': Icons.hourglass_empty,
        };
      case 'confirmed':
        return {
          'text': 'Đã xác nhận',
          'color': Colors.blue,
          'icon': Icons.check,
        };
      case 'processing':
        return {
          'text': 'Đang xử lý',
          'color': Colors.indigo,
          'icon': Icons.inventory_2,
        };
      case 'shipping':
        return {
          'text': 'Đang giao',
          'color': Colors.purple,
          'icon': Icons.local_shipping,
        };
      case 'delivered':
        return {
          'text': 'Đã giao',
          'color': Colors.teal,
          'icon': Icons.done_all,
        };
      case 'completed':
        return {
          'text': 'Hoàn thành',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'cancelled':
        return {'text': 'Đã hủy', 'color': Colors.red, 'icon': Icons.cancel};
      case 'returned':
        return {
          'text': 'Đã trả hàng',
          'color': Colors.brown,
          'icon': Icons.assignment_return,
        };
      default:
        return {
          'text': status,
          'color': Colors.grey,
          'icon': Icons.help_outline,
        };
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat('#,###', 'vi_VN');
    return '${format.format(amount)}đ';
  }

  void _showCancelDialog(OrderModel order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc muốn hủy đơn hàng #${order.id}?'),
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
              await _cancelOrder(order.id, reasonController.text);
            },
            child: Text('Hủy đơn', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(int orderId, String reason) async {
    try {
      final result = await _orderService.cancelOrder(
        orderId: orderId,
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
        _refreshCurrentTab(); // Reload list
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
