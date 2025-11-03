import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

void showAddToCartSuccess(BuildContext context, String productName) {
  Flushbar(
    margin: const EdgeInsets.all(8),
    borderRadius: BorderRadius.circular(12),
    backgroundColor: Colors.white,
    boxShadows: const [
      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
    ],
    flushbarPosition: FlushbarPosition.TOP,
    duration: const Duration(seconds: 2),
    messageText: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đã thêm vào giỏ hàng',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          '$productName x1',
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ],
    ),
    icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
    leftBarIndicatorColor: Colors.green,
  ).show(context);
}
