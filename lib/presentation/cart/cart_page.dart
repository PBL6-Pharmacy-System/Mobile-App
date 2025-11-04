import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/cart/widgets/cart_item.dart';
import 'package:pharmacy_app/presentation/checkout/checkout_page.dart';
import 'package:pharmacy_app/provider/app_state.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final carts = context.watch<AppState>().carts;

    return Scaffold(
      appBar: _buildAppbar(context, carts),
      body: SafeArea(
        child: carts.isEmpty
            ? _buildEmpty(context)
            : Column(
                children: [
                  _buildListItem(carts),
                  Divider(height: 1),
                  _buildCartInfo(context),
                ],
              ),
      ),
    );
  }

  _buildAppbar(BuildContext context, List<ProductModel> carts) {
    return AppBar(
      backgroundColor: primaryColor,
      leading: SizedBox.shrink(),
      centerTitle: true,
      title: Text(
        'Giỏ hàng (${carts.length})',
        style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
      ),
    );
  }

  _buildCartInfo(BuildContext context) {
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
              Text('13.500đ', style: context.textTheme.bodyMedium),
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
          Divider(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng:', style: context.textTheme.bodySmall),
              Text(
                '13.500đ',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: primaryColor,
                ),
              ),
            ],
          ),
          Gap.smHeight,
          ButtonApp(
            child: Text('Thanh toán'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CheckoutPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  _buildListItem(List<ProductModel> carts) {
    return Expanded(
      child: Padding(
        padding: EdgeInsetsDirectional.all(Gap.md),
        child: ListView.builder(
          itemCount: carts.length,
          itemBuilder: (context, index) {
            return CartItem(carts[index]);
          },
        ),
      ),
    );
  }

  _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        spacing: Gap.md,
        children: [
          Gap.xxlHeight,
          SvgPicture.asset(
            'assets/images/shopping-bag.svg',
            width: 100,
            height: 100,
          ),
          Text('Giỏ hàng trống', style: context.textTheme.titleSmall),
          Text(
            'Hãy thêm sản phẩm vào giỏ hàng của bạn',
            style: context.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
          ButtonApp(child: Text('Tiếp tục mua sắm'), onPressed: () {}),
        ],
      ),
    );
  }
}
