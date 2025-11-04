import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              isScrollable: false,
              controller: _tabController,
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              tabs: const [
                Tab(text: 'Đang xử lý (1)'),
                Tab(text: 'Đã giao (1)'),
                Tab(text: 'Đã hủy (1)'),
              ],
            ),
          ),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('Đang xử lý'),
          _buildOrderList('Đã giao'),
          _buildOrderList('Đã hủy'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _orderCard(
          orderId: 'DH001',
          date: '2025-11-01',
          status: status,
          items: [
            {
              'image': 'https://i.imgur.com/0B8T4vW.png',
              'name': 'Paracetamol 500mg',
              'quantity': 2,
            },
            {
              'image': 'https://i.imgur.com/1nP8pUw.png',
              'name': 'Nhiệt kế điện tử',
              'quantity': 1,
            },
          ],
          total: '285.000đ',
        ),
      ],
    );
  }

  Widget _orderCard({
    required String orderId,
    required String date,
    required String status,
    required List<Map<String, dynamic>> items,
    required String total,
  }) {
    Color statusColor;
    switch (status) {
      case 'Đã giao':
        statusColor = Colors.green;
        break;
      case 'Đã hủy':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã đơn: $orderId', style: context.textTheme.titleSmall),
                  Text(
                    'Ngày đặt: $date',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          Gap.mdHeight,
          Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: Gap.sm),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['image'],
                            width: Gap.xxl,
                            height: Gap.xxl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Gap.sMWidth,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: context.textTheme.titleSmall,
                              ),
                              Text(
                                'x${item['quantity']}',
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: Colors.grey,
                                ),
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

          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng tiền:',
                style: context.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              Text(
                total,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
