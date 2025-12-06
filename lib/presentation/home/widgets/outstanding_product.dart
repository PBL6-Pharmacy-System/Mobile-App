import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/home_screen.dart';
import 'package:pharmacy_app/presentation/home/widgets/production_item.dart';
import 'package:pharmacy_app/provider/product_provider.dart';
import 'package:pharmacy_app/common/widgets/shimmer_loading.dart';
import 'package:provider/provider.dart';

class OutstandingProduct extends StatefulWidget {
  const OutstandingProduct({super.key});

  @override
  State<OutstandingProduct> createState() => _OutstandingProductState();
}

class _OutstandingProductState extends State<OutstandingProduct> {
  final ScrollController _scrollController = ScrollController();
  bool _showViewAllButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Load best sellers on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchBestSellers(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    // Hiện nút "Xem tất cả" khi cuộn đến 70%
    final threshold70 = maxScroll * 0.7;
    if (currentScroll >= threshold70 && !_showViewAllButton) {
      setState(() {
        _showViewAllButton = true;
      });
    } else if (currentScroll < threshold70 && _showViewAllButton) {
      setState(() {
        _showViewAllButton = false;
      });
    }

    // Load more khi cuộn đến 80% - Infinite scroll
    final threshold80 = maxScroll * 0.8;
    if (currentScroll >= threshold80) {
      final provider = context.read<ProductProvider>();
      if (!provider.isLoadingMoreBestSellers && provider.hasMoreBestSellers) {
        provider.loadMoreBestSellers();
      }
    }
  }

  void _navigateToCategoryPage() {
    // Chuyển đến trang HomeScreen với tab Danh mục được chọn
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(initialIndex: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: Gap.md, bottom: Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Gap.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sản phẩm nổi bật', style: context.textTheme.titleSmall),
                if (_showViewAllButton)
                  TextButton.icon(
                    onPressed: _navigateToCategoryPage,
                    icon: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    label: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                // Loading state ban đầu - dùng shimmer
                if (productProvider.isLoadingBestSellers &&
                    productProvider.bestSellers.isEmpty) {
                  return const ProductListShimmer(itemCount: 4);
                }

                final products = productProvider.bestSellers;

                // Empty state
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        Gap.smHeight,
                        Text(
                          'Chưa có sản phẩm nổi bật',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Gap.smHeight,
                        TextButton(
                          onPressed: () =>
                              productProvider.fetchBestSellers(refresh: true),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                // Product list với infinite scroll
                return ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: Gap.md),
                  // +1 cho loading indicator nếu còn data để load
                  itemCount:
                      products.length +
                      (productProvider.hasMoreBestSellers ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator ở cuối list
                    if (index >= products.length) {
                      return Container(
                        width: 160,
                        margin: EdgeInsets.only(left: Gap.sm),
                        child: Center(
                          child: productProvider.isLoadingMoreBestSellers
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : const SizedBox.shrink(),
                        ),
                      );
                    }

                    return Container(
                      width: 160,
                      margin: EdgeInsets.only(
                        right: index < products.length - 1 ? Gap.sm : 0,
                      ),
                      child: ProductionItem(products[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
