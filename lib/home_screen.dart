import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/presentation/account/account_page.dart';
import 'package:pharmacy_app/presentation/cart/cart_page.dart';
import 'package:pharmacy_app/presentation/category/category_screen.dart';
import 'package:pharmacy_app/presentation/chat/chat_page.dart';
import 'package:pharmacy_app/presentation/home/home_page.dart';
import 'package:pharmacy_app/provider/product_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0, this.initialCategoryId});

  final int initialIndex;
  final int? initialCategoryId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  // Giữ các page được khởi tạo để không rebuild
  late final List<Widget> _pages;

  // Cache trạng thái đã preload
  bool _hasPreloaded = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Khởi tạo pages một lần duy nhất
    _pages = [
      const HomePage(),
      CategoryScreen(initialCategoryId: widget.initialCategoryId),
      const CartPage(),
      ChatPage(onBack: () => _onItemTapped(0)),
      const AccountPage(),
    ];

    // Preload data khi vào HomeScreen
    _preloadData();
  }

  /// Preload data cho app để load nhanh hơn khi chuyển tab
  Future<void> _preloadData() async {
    if (_hasPreloaded) return;
    _hasPreloaded = true;

    // Preload best sellers và flash sales trong background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      if (productProvider.bestSellers.isEmpty) {
        productProvider.fetchBestSellers(refresh: true);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ẩn bottom navigation bar khi ở trang Tư vấn (index 3)
    final bool showBottomNav = _selectedIndex != 3;

    return Scaffold(
      // Sử dụng IndexedStack để giữ state của các tab
      // Tránh rebuild khi chuyển tab -> load nhanh hơn
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: showBottomNav ? _buildCustomBottomNav() : null,
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Trang chủ
              _buildNavItem(
                index: 0,
                icon: 'assets/images/house.svg',
                label: 'Trang chủ',
              ),
              // Danh mục
              _buildNavItem(
                index: 1,
                icon: 'assets/images/grid-3x3.svg',
                label: 'Danh mục',
              ),
              // Giỏ hàng - Nút nổi ở giữa
              _buildCartButton(),
              // Tư vấn
              _buildNavItem(
                index: 3,
                icon: 'assets/images/message-circle.svg',
                label: 'Tư vấn',
              ),
              // Tài khoản
              _buildNavItem(
                index: 4,
                icon: 'assets/images/user.svg',
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                isSelected ? primaryColor : Colors.grey.shade400,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primaryColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    final isSelected = _selectedIndex == 2;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(2),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Nút giỏ hàng nổi - đẩy lên trên
            Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/shopping-cart.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
            // Label
            Transform.translate(
              offset: const Offset(0, -8),
              child: Text(
                'Giỏ hàng',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? primaryColor : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
