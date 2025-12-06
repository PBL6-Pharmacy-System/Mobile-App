import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/home/widgets/production_item.dart';
import 'package:pharmacy_app/services/product_service.dart';
import 'package:pharmacy_app/common/widgets/shimmer_loading.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  final int? categoryId;

  const SearchPage({super.key, this.initialQuery, this.categoryId});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> searchResults = [];
  bool isSearching = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String currentQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Nếu có initial query, thực hiện tìm kiếm ngay
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreResults();
    }
  }

  void _onSearchChanged(String query) {
    // Debounce search để tránh gọi API quá nhiều
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
        isLoading = false;
        hasMore = true;
        currentPage = 1;
        currentQuery = '';
      });
      return;
    }

    setState(() {
      isSearching = true;
      isLoading = true;
      currentPage = 1;
      currentQuery = query;
      hasMore = true;
    });

    try {
      final response = await _productService.searchProductsWithPagination(
        keyword: query,
        page: 1,
        limit: 10,
      );

      setState(() {
        searchResults = response.data;
        isLoading = false;
        hasMore = response.data.length >= 10;
      });
    } catch (e) {
      print('Error searching products: $e');
      setState(() {
        searchResults = [];
        isLoading = false;
        hasMore = false;
      });
    }
  }

  void _loadMoreResults() async {
    if (isLoadingMore || !hasMore || currentQuery.isEmpty) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final response = await _productService.searchProductsWithPagination(
        keyword: currentQuery,
        page: currentPage + 1,
        limit: 10,
      );

      setState(() {
        searchResults.addAll(response.data);
        currentPage++;
        isLoadingMore = false;
        hasMore = response.data.length >= 10;
      });
    } catch (e) {
      print('Error loading more products: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        toolbarHeight: 50,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm, thuốc...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(
                left: 14,
                top: 8,
                bottom: 8,
              ),
              isDense: true,
            ),
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            onChanged: _onSearchChanged,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black87, size: 15),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(Gap.md),
          child: Text(
            'Kết quả tìm kiếm (${searchResults.length}${hasMore ? '+' : ''})',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: Gap.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.5,
            ),
            itemCount: searchResults.length + (isLoadingMore ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= searchResults.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return ProductionItem(searchResults[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const ProductGridShimmer(itemCount: 6);
    }

    if (!isSearching && searchResults.isEmpty) {
      return _buildEmptyState();
    }

    if (isSearching && searchResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          Gap.mdHeight,
          Text(
            'Tìm kiếm sản phẩm',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Gap.smHeight,
          Text(
            'Nhập tên thuốc, sản phẩm bạn cần tìm',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          Gap.mdHeight,
          Text(
            'Không tìm thấy kết quả',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Gap.smHeight,
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
