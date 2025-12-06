import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageSlider extends StatelessWidget {
  const ImageSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> bannerImages = [
      'assets/banners/Banner_H2_1_6d86dbb69f.png',
      'assets/banners/Banner_Ung_Thu_1_185705d391.jpg',
      'assets/banners/Banner_Web_PC_805x246_08bf786c89.png',
      'assets/banners/Banner_Web_PC_805x246_77941da2d1.png',
      'assets/banners/D_H1_Desktop_1200x367_3053759f45.png',
      'assets/banners/D_H1_Desktop_1200x367_8ba0bd390a.png',
      'assets/banners/H1_desktop_805x246_9723f40439.jpg',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.95,
          aspectRatio: 3.2,
          autoPlayInterval: const Duration(seconds: 4),
        ),
        items: bannerImages.map((imagePath) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                fit: BoxFit.fill,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
