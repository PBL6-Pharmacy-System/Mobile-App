import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/models/flash_sale_product_model.dart';
import 'package:pharmacy_app/presentation/home/widgets/flash_sale_item.dart';
import 'package:pharmacy_app/services/flash_sale_service.dart';

class FlashSaleProductsPage extends StatefulWidget {
  const FlashSaleProductsPage({super.key});

  @override
  State<FlashSaleProductsPage> createState() => _FlashSaleProductsPageState();
}

class _FlashSaleProductsPageState extends State<FlashSaleProductsPage> {
  late Timer _timer;
  Duration _timeLeft = const Duration(hours: 2, minutes: 30, seconds: 45);
  final FlashSaleService _flashSaleService = FlashSaleService();
  List<FlashSaleProductModel> flashSaleProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _loadFlashSaleProducts();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      } else {
        _timer.cancel();
      }
    });
  }

  Future<void> _loadFlashSaleProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      final flashProducts = await _flashSaleService.getActiveFlashSales();

      setState(() {
        flashSaleProducts = flashProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading flash sale products: $e');
    }
  }

  String _formatTime(int value) {
    return value.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours;
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 15),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FLASH SALE',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          // Countdown timer
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                _buildTimeUnit(_formatTime(hours)),
                const Text(
                  ':',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTimeUnit(_formatTime(minutes)),
                const Text(
                  ':',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTimeUnit(_formatTime(seconds)),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : flashSaleProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có Flash Sale',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng quay lại sau',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                // Header info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Có ${flashSaleProducts.length} sản phẩm đang giảm giá',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider trắng mỏng
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.white.withOpacity(0.3),
                ),

                // Grid sản phẩm
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadFlashSaleProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: flashSaleProducts.length,
                      itemBuilder: (context, index) {
                        return FlashSaleItem(flashSaleProducts[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTimeUnit(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
