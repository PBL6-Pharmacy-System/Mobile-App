import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/shimmer_loading.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/home_screen.dart';
import 'package:pharmacy_app/models/cart_model.dart';
import 'package:pharmacy_app/presentation/cart/widgets/cart_item.dart';
import 'package:pharmacy_app/presentation/checkout/checkout_page.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/provider/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCart();
    });
  }

  void _loadCart() {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();

    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      // Sử dụng customerId (ID trong bảng customers), không phải id (ID trong bảng users)
      final customerId = authProvider.currentUser!.customerId;
      print('📦 [CartPage] Loading cart for customerId: $customerId');

      if (customerId != null) {
        cartProvider.fetchCart(customerId);
      } else {
        print('❌ [CartPage] No customerId found for user');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(context),
      body: SafeArea(
        child: Consumer2<CartProvider, AuthProvider>(
          builder: (context, cartProvider, authProvider, child) {
            if (!authProvider.isLoggedIn) {
              return _buildNotLoggedIn(context);
            }

            if (cartProvider.isLoading) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (_, __) => const CartItemShimmer(),
              );
            }

            final cart = cartProvider.cart;
            final items = cart?.items ?? [];

            if (items.isEmpty) {
              return _buildEmptyCart(context);
            }

            return Column(
              children: [
                _buildListItem(items),
                const Divider(height: 1),
                _buildCartInfo(context, cartProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              size: 70,
              color: Colors.grey[350],
            ),
            Gap.mdHeight,
            Text(
              'Giỏ hàng trống',
              style: context.textTheme.titleSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Gap.smHeight,
            Text(
              'Hãy thêm sản phẩm vào giỏ hàng của bạn',
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            Gap.mdHeight,
            SizedBox(
              width: 180,
              child: ButtonApp(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Tiếp tục mua sắm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppbar(BuildContext context) {
    // Kiểm tra xem có thể pop hay không
    final canPop = Navigator.canPop(context);

    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryLightColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (canPop) {
            Navigator.pop(context);
          } else {
            // Nếu không thể pop, quay về trang chủ
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeScreen(initialIndex: 0),
              ),
              (route) => false,
            );
          }
        },
      ),
      centerTitle: true,
      title: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          return Text(
            'Giỏ hàng (${cartProvider.itemCount})',
            style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildCartInfo(BuildContext context, CartProvider cartProvider) {
    final subtotal = cartProvider.subtotal;
    final discount = cartProvider.voucherDiscount;
    final total = cartProvider.total;

    return Padding(
      padding: EdgeInsets.all(Gap.md),
      child: Column(
        spacing: Gap.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tạm tính:', style: context.textTheme.bodySmall),
              Text(
                currencyFormatter.format(subtotal),
                style: context.textTheme.bodyMedium,
              ),
            ],
          ),
          if (discount > 0)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giảm giá:', style: context.textTheme.bodySmall),
                Text(
                  '- ${currencyFormatter.format(discount)}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phí vận chuyển:', style: context.textTheme.bodySmall),
              Text(
                'Miễn phí',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng:', style: context.textTheme.bodySmall),
              Text(
                currencyFormatter.format(total),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gap.smHeight,
          ButtonApp(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckoutPage()),
              );
            },
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(List<CartItemModel> items) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Gap.md),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return CartItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: Gap.md,
        children: [
          Icon(Icons.login, size: 80, color: Colors.grey[400]),
          Text('Vui lòng đăng nhập', style: context.textTheme.titleSmall),
          Text(
            'Bạn cần đăng nhập để xem giỏ hàng',
            style: context.textTheme.bodyMedium?.copyWith(color: textColor),
            textAlign: TextAlign.center,
          ),
          ButtonApp(
            onPressed: () {
              // Navigate to login
              Navigator.pop(context);
            },
            child: const Text('Đăng nhập ngay'),
          ),
        ],
      ),
    );
  }
}
