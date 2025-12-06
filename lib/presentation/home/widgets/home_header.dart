import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/presentation/search/search_page.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  void _openSearchPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Gap.md),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryLightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.sM,
        children: [
          Gap.smHeight,
          Text(
            'Nhà thuốc Long Châu',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Chăm sóc sức khỏe toàn diện',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          GestureDetector(
            onTap: () => _openSearchPage(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: Gap.sM + 2,
                horizontal: Gap.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius12,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: greyColor),
                  SizedBox(width: Gap.sM),
                  Text(
                    'Tìm thuốc, bệnh lý, sản phẩm y tế...',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: greyColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
