import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/presentation/account/account_page.dart';
import 'package:pharmacy_app/presentation/cart/cart_page.dart';
import 'package:pharmacy_app/presentation/category/category_page.dart';
import 'package:pharmacy_app/presentation/chat/chat_page.dart';
import 'package:pharmacy_app/presentation/home/home_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    CategoryPage(),
    CartPage(),
    ChatPage(),
    AccountPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            activeIcon: SvgPicture.asset(
              'assets/images/house.svg',
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
            ),
            icon: SvgPicture.asset('assets/images/house.svg'),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            activeIcon: SvgPicture.asset(
              'assets/images/grid-3x3.svg',
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
            ),
            icon: SvgPicture.asset('assets/images/grid-3x3.svg'),
            label: 'Danh mục',
          ),
          BottomNavigationBarItem(
            activeIcon: SvgPicture.asset(
              'assets/images/shopping-cart.svg',
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
            ),
            icon: SvgPicture.asset('assets/images/shopping-cart.svg'),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            activeIcon: SvgPicture.asset(
              'assets/images/message-circle.svg',
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
            ),
            icon: SvgPicture.asset('assets/images/message-circle.svg'),
            label: 'Tư vấn',
          ),
          BottomNavigationBarItem(
            activeIcon: SvgPicture.asset(
              'assets/images/user.svg',
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
            ),
            icon: SvgPicture.asset('assets/images/user.svg'),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
