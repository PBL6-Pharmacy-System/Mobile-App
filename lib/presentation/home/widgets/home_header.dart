import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Gap.md),
      width: double.infinity,
      decoration: BoxDecoration(color: primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.sM,
        children: [
          Text(
            'Nhà thuốc Long Châu',
            style: context.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            'Chăm sóc sức khỏe toàn diện',
            style: context.textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
          TextFormField(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                vertical: Gap.xs,
                horizontal: Gap.md,
              ),
              prefixIcon: Icon(Icons.search, color: borderColor),
              hintText: 'Tìm thuốc, bệnh lý, sản phẩm y tế...',
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: borderColor,
              ),
              fillColor: Colors.white,
              filled: true,
              focusedBorder: OutlineInputBorder(
                borderRadius: radius12,
                borderSide: BorderSide(width: 1, color: borderColor),
              ),
              border: OutlineInputBorder(
                borderRadius: radius12,
                borderSide: BorderSide(width: 1, color: borderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
