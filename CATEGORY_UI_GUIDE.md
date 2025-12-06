# Category UI Implementation Guide

## 📱 Tổng quan

Đã triển khai UI danh mục sản phẩm với các tính năng:

- ✅ Hiển thị cây danh mục từ API `/categories/tree`
- ✅ Tab ngang với subcategories có thể mở rộng
- ✅ Load sản phẩm theo category ID từ API `/products?categoryId=X`
- ✅ Infinite scroll với pagination (6 sản phẩm/lần)
- ✅ Caching với SharedPreferences (24 giờ)
- ✅ Lazy loading hình ảnh với CachedNetworkImage
- ✅ Pull-to-refresh
- ✅ Loading states với shimmer effects

## 🏗️ Kiến trúc

### 1. Models

**`lib/models/category_model.dart`**

```dart
class CategoryModel {
  final int id;
  final String name;
  final int? parentId;
  final int productCount;
  final List<CategoryModel> children;

  // Helper methods
  List<CategoryModel> getAllDescendants(); // Lấy tất cả categories con
  bool get hasChildren; // Kiểm tra có con không
  int get totalProductCount; // Tổng số sản phẩm bao gồm con
}

class CategoryTreeResponse {
  final bool success;
  final List<CategoryModel> data;
}
```

**`lib/models/product_model.dart`** (Updated)

```dart
class ProductListResponse {
  final bool success;
  final List<ProductModel> data;
  final PaginationInfo? pagination;
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;
}
```

### 2. Services

**`lib/services/category_service.dart`**

```dart
class CategoryService {
  // Load categories với caching (24 giờ)
  Future<List<CategoryModel>> getAllCategories({bool forceRefresh = false});

  // Cache management
  Future<void> clearCache();
  Future<bool> hasCachedData();

  // Private helpers
  Future<void> _cacheCategories(List<CategoryModel> categories);
  Future<List<CategoryModel>?> _getCachedCategories({bool ignoreExpiration});
}
```

**`lib/services/product_service.dart`** (Updated)

```dart
class ProductService {
  // API: GET /products?categoryId=X&page=Y&limit=Z
  Future<ProductListResponse> getProductsByCategoryWithPagination({
    required int categoryId,
    int page = 1,
    int limit = 6,
  });
}
```

### 3. UI Components

**`lib/presentation/category/category_screen.dart`**

- Main screen với category tabs và product grid
- Quản lý state: loading, error, pagination
- Infinite scroll với ScrollController
- Pull-to-refresh support

**`lib/presentation/category/widgets/category_tab_bar.dart`**

- Horizontal scrolling tabs cho main categories
- Expandable subcategories chips
- Visual feedback cho selected category
- Product count badges

**`lib/presentation/category/widgets/product_grid_view.dart`**

- 2 columns grid layout
- Loading indicator khi load more
- Optimized aspect ratio (0.68) cho product cards

**`lib/presentation/category/widgets/category_shimmer_loading.dart`**

- Shimmer loading cho tabs và grid
- Skeleton screens while loading

**`lib/presentation/widgets/product_card.dart`**

- Compact product display
- Cached network images
- Price formatting
- Add to cart button
- Navigation to product detail

## 📊 Data Flow

```
1. CategoryScreen loads
   ↓
2. CategoryService.getAllCategories()
   ↓
3. Check SharedPreferences cache
   ├─ Cache valid (< 24h) → Return cached data
   └─ Cache expired/missing → Fetch from API
      ↓
4. API: GET /categories/tree
   ↓
5. Cache response in SharedPreferences
   ↓
6. Select first category
   ↓
7. ProductService.getProductsByCategoryWithPagination()
   ↓
8. API: GET /products?categoryId=X&page=1&limit=6
   ↓
9. Display products in grid
   ↓
10. User scrolls → Load more (page 2, 3, ...)
```

## 🚀 Performance Optimizations

### 1. **Caching Strategy**

```dart
// SharedPreferences cache với TTL 24 giờ
- Key: 'cached_categories'
- Timestamp: 'cached_categories_time'
- Expiration: Duration(hours: 24)

// Fallback behavior:
- Network error → Return expired cache
- No cache → Show error screen
```

### 2. **Image Optimization**

```dart
// CachedNetworkImage package
- Memory cache: Automatic
- Disk cache: Automatic
- Placeholder: CircularProgressIndicator
- Error widget: Medication icon
- Image format: Progressive loading
```

### 3. **Lazy Loading**

```dart
// Infinite scroll với threshold
ScrollController.addListener(() {
  if (pixels >= maxScrollExtent - 200) { // Pre-load 200px trước
    loadMoreProducts();
  }
});

// Pagination
- Default: 6 products per page
- hasMoreProducts flag từ API
- currentPage state management
```

### 4. **State Management**

```dart
// Optimized setState calls
- Separate loading states: _isLoadingCategories, _isLoadingProducts, _isLoadingMore
- Avoid unnecessary rebuilds
- Use const widgets where possible
```

### 5. **Memory Management**

```dart
// Dispose controllers
@override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}

// Flattened category list
List<CategoryModel> _allCategories = []; // For O(1) lookup
```

## 📱 UI/UX Features

### Category Tabs

- **Main Categories**: Horizontal scrolling pills
- **Subcategories**: Expandable chips below main tabs
- **Visual States**:
  - Selected: Blue background, white text, bold
  - Unselected: Grey background, black text
  - Hover/Press: InkWell ripple effect

### Product Grid

- **Layout**: 2 columns, aspect ratio 0.68
- **Spacing**: 12px between items and edges
- **Card Components**:
  - Image: 1:1 aspect ratio
  - Title: 2 lines max, ellipsis
  - Unit type: Small grey text
  - Price: Blue, bold, formatted (K/M₫)
  - Add button: Blue circle with cart icon

### Loading States

- **Categories Loading**: Shimmer tabs + grid skeletons
- **Products Loading**: Center CircularProgressIndicator
- **Load More**: Small indicator at bottom
- **Pull to Refresh**: Standard Material refresh indicator

### Error Handling

- **Error Screen**: Icon + message + retry button
- **Network Error**: Show cached data if available
- **Empty State**: Icon + "Không có sản phẩm nào"

## 🔧 Installation

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.4.1 # NEW
  shimmer: ^3.0.0 # NEW
  shared_preferences: ^2.3.5 # EXISTING
  dio: ^5.9.0 # EXISTING
```

### 2. Install Packages

```powershell
cd D:\AppMobile\pharmacy_app
flutter pub get
```

### 3. Verify Backend APIs

```powershell
# Test category tree API
Invoke-RestMethod -Uri "http://localhost:3000/api/categories/tree" | ConvertTo-Json -Depth 10

# Test products API
Invoke-RestMethod -Uri "http://localhost:3000/api/products?categoryId=128&page=1&limit=6" | ConvertTo-Json -Depth 10
```

## 📂 File Structure

```
lib/
├── models/
│   ├── category_model.dart         ✅ UPDATED (New structure)
│   └── product_model.dart          ✅ UPDATED (Added ProductListResponse)
├── services/
│   ├── category_service.dart       ✅ UPDATED (Added caching)
│   └── product_service.dart        ✅ UPDATED (Added pagination method)
├── presentation/
│   ├── category/
│   │   ├── category_screen.dart    ✅ NEW
│   │   └── widgets/
│   │       ├── category_tab_bar.dart            ✅ NEW
│   │       ├── product_grid_view.dart           ✅ NEW
│   │       └── category_shimmer_loading.dart    ✅ NEW
│   └── widgets/
│       └── product_card.dart       ✅ NEW
```

## 🎯 Usage Example

### Navigate to Category Screen

```dart
// From home screen or navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CategoryScreen(),
  ),
);
```

### Manual Cache Refresh

```dart
final categoryService = CategoryService();

// Force refresh categories
await categoryService.getAllCategories(forceRefresh: true);

// Clear cache manually
await categoryService.clearCache();

// Check if has valid cache
bool hasCache = await categoryService.hasCachedData();
```

### Custom Category Loading

```dart
// In your widget
final categoryService = CategoryService();
final categories = await categoryService.getAllCategories();

// Get all subcategories (flattened)
List<CategoryModel> allSubcategories = [];
for (var mainCat in categories) {
  allSubcategories.addAll(mainCat.getAllDescendants());
}

// Get category by ID
final selectedCategory = allSubcategories.firstWhere(
  (cat) => cat.id == 128,
);
```

### Load Products by Category

```dart
final productService = ProductService();

// Load first page
final response = await productService.getProductsByCategoryWithPagination(
  categoryId: 128,
  page: 1,
  limit: 6,
);

print('Loaded ${response.data.length} products');
print('Has more: ${response.pagination?.hasNextPage}');
print('Total: ${response.pagination?.totalItems}');
```

## 🎨 Customization

### Modify Grid Layout

```dart
// In product_grid_view.dart
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,        // Change to 3 for more columns
  childAspectRatio: 0.68,   // Adjust card height
  crossAxisSpacing: 12,     // Horizontal spacing
  mainAxisSpacing: 12,      // Vertical spacing
),
```

### Change Pagination Size

```dart
// In category_screen.dart
final response = await _productService.getProductsByCategoryWithPagination(
  categoryId: _selectedCategory!.id,
  page: _currentPage,
  limit: 12, // Change from 6 to 12
);
```

### Adjust Cache Duration

```dart
// In category_service.dart
static const Duration _cacheExpiration = Duration(hours: 48); // Change from 24 to 48
```

### Modify Scroll Threshold

```dart
// In category_screen.dart
void _onScroll() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 400) { // Change from 200 to 400
    _loadMoreProducts();
  }
}
```

## 🔍 Debugging

### Enable Debug Logs

All services have built-in logging:

```
🌐 Fetching category tree from API...
✅ Found 4 categories
💾 Categories cached successfully
📦 Loaded categories from cache
🌐 Fetching products for category 128 (page 1)...
✅ Loaded 6 products
```

### Common Issues

**1. Categories not loading**

```dart
// Check API connection
final categories = await CategoryService().getAllCategories(forceRefresh: true);

// Check console for errors:
❌ Error loading categories: ...
```

**2. Images not showing**

```dart
// Verify image URL format in product_card.dart
final imageUrl = product.images.isNotEmpty
    ? '${ApiConfig.baseUrl.replaceAll('/api', '')}${product.images[0]}'
    : '';
print('Image URL: $imageUrl'); // Should be: http://localhost:3000/uploads/...
```

**3. Infinite scroll not working**

```dart
// Check ScrollController is attached
itemCount: products.length + (isLoadingMore ? 1 : 0),

// Verify pagination info
print('Has next page: ${response.pagination?.hasNextPage}');
print('Current page: ${response.pagination?.currentPage}');
```

## 🚀 Cải tiến đề xuất (Future Enhancements)

### 1. **Advanced Caching với Hive/Isar**

```dart
// Replace SharedPreferences with Hive for better performance
// - Faster read/write
// - Type-safe
// - Support for complex objects
// - Encryption support

@HiveType(typeId: 0)
class CategoryModel extends HiveObject {
  @HiveField(0) int id;
  @HiveField(1) String name;
  @HiveField(2) List<CategoryModel> children;
}
```

### 2. **Image Prefetching**

```dart
// Prefetch images for next page while user scrolls
void _prefetchNextPageImages() {
  for (var product in _nextPageProducts) {
    precacheImage(
      CachedNetworkImageProvider(product.imageUrl),
      context,
    );
  }
}
```

### 3. **State Management với Riverpod/Bloc**

```dart
// Better separation of business logic
final categoryProvider = FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final categoryService = ref.read(categoryServiceProvider);
  return categoryService.getAllCategories();
});

// Cleaner UI code
class CategoryScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryProvider);
    return categoriesAsync.when(
      data: (categories) => CategoryView(categories),
      loading: () => CategoryShimmerLoading(),
      error: (err, stack) => ErrorView(err),
    );
  }
}
```

### 4. **Offline Support**

```dart
// Queue API calls when offline
// Sync when online
class OfflineQueueService {
  Future<void> addToCart(ProductModel product) async {
    if (await isOnline()) {
      await cartService.add(product);
    } else {
      await offlineQueue.enqueue(AddToCartAction(product));
    }
  }
}
```

### 5. **Search và Filter**

```dart
// Add search bar in CategoryScreen
TextField(
  decoration: InputDecoration(
    hintText: 'Tìm kiếm sản phẩm...',
    prefixIcon: Icon(Icons.search),
  ),
  onChanged: (query) {
    _debounceSearch(query);
  },
);

// Filter chips
Wrap(
  children: [
    FilterChip(label: Text('Có sẵn'), onSelected: (bool value) {}),
    FilterChip(label: Text('Giảm giá'), onSelected: (bool value) {}),
    FilterChip(label: Text('Mới nhất'), onSelected: (bool value) {}),
  ],
);
```

### 6. **Analytics**

```dart
// Track user behavior
void _onCategorySelected(CategoryModel category) {
  analytics.logEvent(
    name: 'category_viewed',
    parameters: {
      'category_id': category.id,
      'category_name': category.name,
      'product_count': category.productCount,
    },
  );
}
```

### 7. **Smart Caching Strategy**

```dart
// Hybrid caching: Memory + Disk
class SmartCacheService {
  final MemoryCache _memoryCache = MemoryCache();
  final DiskCache _diskCache = HiveCache();

  Future<List<CategoryModel>> getCategories() async {
    // 1. Check memory (fastest)
    if (_memoryCache.has('categories')) {
      return _memoryCache.get('categories');
    }

    // 2. Check disk (fast)
    if (await _diskCache.has('categories')) {
      final data = await _diskCache.get('categories');
      _memoryCache.set('categories', data);
      return data;
    }

    // 3. Fetch from network (slow)
    final data = await api.getCategories();
    _memoryCache.set('categories', data);
    await _diskCache.set('categories', data);
    return data;
  }
}
```

### 8. **Virtual Scrolling**

```dart
// Only render visible items for huge lists
ListView.builder(
  itemExtent: 200, // Fixed height for better performance
  cacheExtent: 400, // Render 400px above/below viewport
  itemCount: products.length,
  itemBuilder: (context, index) => ProductCard(products[index]),
);
```

## 📊 Performance Metrics

### Expected Performance

- **Category Load Time**: < 300ms (with cache)
- **Product Load Time**: < 500ms (first page)
- **Scroll FPS**: 60fps (smooth scrolling)
- **Memory Usage**: < 100MB
- **Cache Hit Rate**: > 80%

### Monitoring

```dart
import 'package:flutter/foundation.dart';

// Measure load times
final stopwatch = Stopwatch()..start();
await categoryService.getAllCategories();
stopwatch.stop();
debugPrint('Categories loaded in ${stopwatch.elapsedMilliseconds}ms');
```

## ✅ Testing Checklist

- [ ] Categories load successfully
- [ ] Cache works (check SharedPreferences)
- [ ] Products load for each category
- [ ] Pagination works (scroll to bottom)
- [ ] Images load and cache
- [ ] Pull-to-refresh works
- [ ] Error handling (disconnect wifi)
- [ ] Empty states display correctly
- [ ] Navigation to product detail works
- [ ] Add to cart button works
- [ ] App doesn't crash on rapid scrolling
- [ ] Memory doesn't leak
- [ ] UI responsive on different screen sizes

## 📝 Notes

- **SharedPreferences vs Hive**: SharedPreferences được sử dụng vì đơn giản và đã có trong dependencies. Nếu cần performance tốt hơn, migrate sang Hive.
- **Image Caching**: CachedNetworkImage tự động quản lý cache, không cần code thêm.
- **Pagination**: Backend API phải support pagination với query params `page` và `limit`.
- **Category Tree**: Backend API `/categories/tree` phải return nested structure với `children` array.

## 🔗 Related APIs

### Backend Endpoints Used

```
GET /api/categories/tree
Response: { success: true, data: [CategoryModel] }

GET /api/products?categoryId=X&page=Y&limit=Z
Response: {
  success: true,
  data: [ProductModel],
  pagination: PaginationInfo
}
```

### Required Backend Features

- ✅ Category tree with nested children
- ✅ Product count per category
- ✅ Products by category ID
- ✅ Pagination support
- ✅ Product images endpoint

---

**Created**: November 27, 2025
**Last Updated**: November 27, 2025
**Version**: 1.0.0
