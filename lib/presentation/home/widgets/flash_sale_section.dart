import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/flash_sale_product_model.dart';
import 'package:pharmacy_app/presentation/home/widgets/flash_sale_item.dart';
import 'package:pharmacy_app/presentation/flash_sale/flash_sale_products_page.dart';
import 'package:pharmacy_app/services/flash_sale_service.dart';
import 'package:pharmacy_app/common/widgets/shimmer_loading.dart';

class FlashSaleSection extends StatefulWidget {
  const FlashSaleSection({super.key});

  @override
  State<FlashSaleSection> createState() => _FlashSaleSectionState();
}

class _FlashSaleSectionState extends State<FlashSaleSection> {
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

  Future<void> _loadFlashSaleProducts() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Lấy Flash Sale từ API backend
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

  String _formatTime(int value) {
    return value.toString().padLeft(2, '0');
  }

  void _navigateToCategoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FlashSaleProductsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours;
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryLightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.symmetric(horizontal: Gap.md),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          // Header với tiêu đề và countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'FLASH SALE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              // Countdown timer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 16,
                    ),
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

          const SizedBox(height: 12),

          // Danh sách sản phẩm cuộn ngang
          SizedBox(
            height: 260,
            child: isLoading
                ? const ProductListShimmer(itemCount: 3)
                : flashSaleProducts.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có Flash Sale',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: flashSaleProducts.length + 1,
                    itemBuilder: (context, index) {
                      // Item cuối cùng là nút "Xem tất cả"
                      if (index == flashSaleProducts.length) {
                        return _buildViewAllButton();
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < flashSaleProducts.length - 1 ? 12 : 0,
                        ),
                        child: FlashSaleItem(flashSaleProducts[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildViewAllButton() {
    return GestureDetector(
      onTap: _navigateToCategoryPage,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              'Xem tất cả',
              style: TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${flashSaleProducts.length} SP',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
