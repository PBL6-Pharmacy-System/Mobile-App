import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/presentation/home/widgets/flash_sale_section.dart';
import 'package:pharmacy_app/presentation/home/widgets/home_category.dart';
import 'package:pharmacy_app/presentation/home/widgets/home_header.dart';
import 'package:pharmacy_app/presentation/home/widgets/image_slider.dart';
import 'package:pharmacy_app/presentation/home/widgets/outstanding_product.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        spacing: Gap.md,
        children: [
          HomeHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: Gap.sm,
                children: [
                  HomeCategory(),
                  ImageSlider(),
                  FlashSaleSection(),
                  OutstandingProduct(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
