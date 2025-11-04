import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/dialog.dart';
import 'package:pharmacy_app/common/widgets/text_field_app.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String paymentMethod = "COD";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Thanh toán",
          style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReceiverInfoCard(),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(),
            const SizedBox(height: 24),
            ButtonApp(
              onPressed: () {
                showCheckoutSuccess(context);
              },
              child: const Text("Xác nhận đặt hàng"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverInfoCard() {
    return Container(
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
        spacing: Gap.sm,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Thông tin người nhận", style: context.textTheme.titleMedium),
          TextFieldApp(labelText: "Họ và tên"),
          TextFieldApp(labelText: "Số điện thoại"),
          TextFieldApp(labelText: "Địa chỉ giao hàng"),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
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
          Text("Phương thức thanh toán", style: context.textTheme.titleMedium),
          Gap.mdHeight,
          _paymentOption(
            "COD",
            "Thanh toán khi nhận hàng (COD)",
            Icons.local_shipping,
          ),
          _paymentOption("MoMo", "Ví MoMo", Icons.account_balance_wallet),
          _paymentOption("ZaloPay", "ZaloPay", Icons.payment),
          _paymentOption("Bank", "Thẻ ngân hàng", Icons.credit_card),
        ],
      ),
    );
  }

  Widget _paymentOption(String value, String label, IconData icon) {
    return InkWell(
      onTap: () => setState(() => paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: Gap.sm),
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(
            color: paymentMethod == value
                ? Colors.blueAccent
                : Colors.grey.shade300,
          ),
          borderRadius: radius10,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: paymentMethod,
              onChanged: (v) => setState(() => paymentMethod = v!),
              activeColor: primaryColor,
            ),
            Icon(
              icon,
              color: paymentMethod == value
                  ? primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: context.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}
