# 🚀 Performance Optimization Guide - Category UI

## So sánh: Flutter vs Web trong việc lưu trữ dữ liệu

### Flutter (Mobile App)

#### ✅ **SharedPreferences** (Đang sử dụng)

```dart
// Tương đương localStorage của web
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('key', jsonEncode(data));
String? cached = prefs.getString('key');
```

**Ưu điểm:**

- ✅ Đơn giản, dễ sử dụng
- ✅ Lưu trữ persistent (không mất khi tắt app)
- ✅ Có sẵn trong project
- ✅ Hoàn hảo cho config và cache nhỏ

**Giới hạn:**

- ⚠️ Chỉ lưu string, int, bool, double (phải serialize object → JSON)
- ⚠️ Không tối ưu cho data lớn (> 1MB)
- ⚠️ Đọc/ghi đồng bộ (có thể block UI)

**Use cases:**

- ✅ Cache danh mục sản phẩm (< 100KB)
- ✅ User preferences
- ✅ Authentication tokens
- ✅ App settings

---

#### 🔥 **Hive** (Recommended upgrade)

```dart
// NoSQL database, nhanh gấp 10x SharedPreferences
import 'package:hive_flutter/hive_flutter.dart';

// Initialize
await Hive.initFlutter();
Hive.registerAdapter(CategoryModelAdapter());
var box = await Hive.openBox<CategoryModel>('categories');

// Save
await box.put('main_categories', categoryList);

// Read
List<CategoryModel>? cached = box.get('main_categories');

// Watch for changes
box.watch().listen((event) {
  print('Data changed: ${event.key}');
});
```

**Ưu điểm:**

- 🚀 Cực nhanh (NoSQL, binary format)
- 💪 Type-safe với adapters
- 📦 Lưu trữ objects trực tiếp (không cần JSON)
- 🔒 Hỗ trợ encryption
- 🎯 Lazy loading
- ⚡ Reactive streams (ValueListenableBuilder)

**Khi nào dùng:**

- ✅ Cache lớn (> 100KB)
- ✅ Frequent reads/writes
- ✅ Complex objects
- ✅ Need reactive updates

**Implementation:**

```yaml
# pubspec.yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

```dart
// category_model.dart
import 'package:hive/hive.dart';

part 'category_model.g.dart'; // Generated file

@HiveType(typeId: 0)
class CategoryModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int productCount;

  @HiveField(3)
  List<CategoryModel> children;
}
```

---

#### 💎 **Isar** (Next-gen alternative)

```dart
// Modern Hive alternative, còn nhanh hơn
import 'package:isar/isar.dart';

@collection
class CategoryModel {
  Id id = Isar.autoIncrement;
  String name;
  int productCount;

  @Index()
  int? parentId;
}

// Query with filters
final categories = await isar.categoryModels
  .where()
  .productCountGreaterThan(10)
  .sortByName()
  .findAll();
```

**Ưu điểm:**

- ⚡ Nhanh nhất (binary format + ACID transactions)
- 🔍 Full-text search built-in
- 📊 Complex queries và indexes
- 🔗 Relationships (links)
- 📱 Multi-isolate support
- 🎨 Beautiful DevTools

**Khi nào dùng:**

- ✅ Large datasets (1000+ items)
- ✅ Complex queries
- ✅ Need search functionality
- ✅ High performance requirements

---

### Comparison Table

| Feature              | SharedPreferences | Hive              | Isar           |
| -------------------- | ----------------- | ----------------- | -------------- |
| **Speed**            | Slow (sync)       | Fast (10x faster) | Fastest (ACID) |
| **Size limit**       | < 1MB             | Unlimited         | Unlimited      |
| **Type safety**      | ❌ (strings only) | ✅ (adapters)     | ✅ (native)    |
| **Queries**          | ❌                | ⚠️ (basic)        | ✅ (advanced)  |
| **Encryption**       | ❌                | ✅                | ✅             |
| **Reactive**         | ❌                | ✅                | ✅             |
| **Setup complexity** | Easy              | Medium            | Medium         |
| **Learning curve**   | 5 min             | 30 min            | 1 hour         |

---

## Recommended Caching Strategy cho Category UI

### Level 1: Memory Cache (Current session)

```dart
class MemoryCache {
  static final Map<String, dynamic> _cache = {};
  static DateTime? _lastUpdate;

  static void set<T>(String key, T value) {
    _cache[key] = value;
    _lastUpdate = DateTime.now();
  }

  static T? get<T>(String key) => _cache[key] as T?;

  static bool isValid(Duration ttl) {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) < ttl;
  }

  static void clear() => _cache.clear();
}
```

**Use:** Giữ data trong RAM trong khi app đang chạy (fastest)

### Level 2: Disk Cache (Persistent)

```dart
// Option A: SharedPreferences (Đang dùng - OK cho < 100KB)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('categories', jsonEncode(categories));

// Option B: Hive (Better - Recommended)
final box = await Hive.openBox('categories');
await box.put('data', categories); // Type-safe, no JSON needed

// Option C: Isar (Best - For large scale)
await isar.writeTxn(() async {
  await isar.categoryModels.putAll(categories);
});
```

**Use:** Lưu data giữa các lần mở app

### Level 3: Network Cache (CDN/Server)

```dart
// API with ETag caching
final response = await dio.get(
  '/categories/tree',
  options: Options(
    headers: {
      'If-None-Match': cachedETag, // Server returns 304 if not modified
    },
  ),
);

if (response.statusCode == 304) {
  return cachedData; // Use cache
} else {
  saveToCache(response.data);
  return response.data;
}
```

**Use:** Giảm bandwidth, server load

---

## Implementation Plan

### Phase 1: Current (SharedPreferences) ✅

```dart
✅ Categories: 24h TTL
✅ Memory: In-memory list during session
✅ Size: < 100KB
✅ Performance: Good enough for MVP
```

### Phase 2: Upgrade to Hive (Recommended)

```dart
🎯 Categories: Hive box with 24h TTL
🎯 Products: Separate Hive box per category
🎯 Images: CachedNetworkImage (already using)
🎯 Performance: 10x faster reads
🎯 Memory: More efficient
```

**Migration Steps:**

1. Add Hive dependencies
2. Generate adapters for models
3. Create HiveCacheService
4. Replace SharedPreferences calls
5. Test and compare performance

### Phase 3: Advanced (Isar + Image prefetch)

```dart
🚀 Full-text search in categories
🚀 Complex queries (filter by price, rating)
🚀 Prefetch images for next page
🚀 Offline-first architecture
🚀 Background sync
```

---

## Image Optimization

### Current: CachedNetworkImage ✅

```dart
CachedNetworkImage(
  imageUrl: url,
  memoryCache: true,  // LRU cache in RAM
  diskCache: true,    // SQLite cache on disk
  maxWidth: 400,      // Resize for display
  maxHeight: 400,
  fadeInDuration: Duration(milliseconds: 200),
)
```

**Auto features:**

- ✅ Memory cache (fast)
- ✅ Disk cache (persistent)
- ✅ Progressive loading
- ✅ Automatic cleanup

### Advanced: Image Prefetch

```dart
// Prefetch images for next page while user scrolls
void _prefetchNextPage() async {
  if (_currentPage >= _totalPages - 1) return;

  final nextPageProducts = await _productService.getProductsByCategoryWithPagination(
    categoryId: _selectedCategory!.id,
    page: _currentPage + 1,
    limit: 6,
  );

  for (var product in nextPageProducts.data) {
    precacheImage(
      CachedNetworkImageProvider(product.imageUrl),
      context,
    );
  }
}

// Call when user is 75% down the list
if (_scrollPosition > _maxScroll * 0.75) {
  _prefetchNextPage();
}
```

### Image Compression (Backend)

```javascript
// Backend: Serve multiple sizes
// /uploads/products/123_thumbnail.jpg (200x200) - for grid
// /uploads/products/123_medium.jpg (600x600) - for detail
// /uploads/products/123_large.jpg (1200x1200) - for zoom

// Flutter: Choose appropriate size
final imageUrl = isGridView
  ? '${baseUrl}/uploads/products/${product.id}_thumbnail.jpg'
  : '${baseUrl}/uploads/products/${product.id}_medium.jpg';
```

---

## Network Optimization

### Pagination Strategy

```dart
// Current: Load 6 products per page ✅
const int pageSize = 6;

// Optimized: Adaptive pagination
int get pageSize {
  final screenHeight = MediaQuery.of(context).size.height;
  final itemHeight = 250.0; // Product card height
  final itemsPerScreen = (screenHeight / itemHeight).ceil();
  return itemsPerScreen * 2; // Load 2 screens worth
}
```

### Request Debouncing

```dart
// Avoid rapid API calls when scrolling fast
Timer? _debounceTimer;

void _onScroll() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    if (_shouldLoadMore) {
      _loadMoreProducts();
    }
  });
}
```

### Batch Requests

```dart
// Instead of multiple requests:
// GET /products?categoryId=128&page=1
// GET /products?categoryId=128&page=2
// GET /products?categoryId=128&page=3

// Use batch request:
// GET /products?categoryId=128&page=1&count=3
// Returns 3 pages worth of data in one request
```

---

## Memory Management

### Lazy Loading with Builder

```dart
// Instead of loading all items at once
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    // Only builds visible items
    return ProductCard(products[index]);
  },
)

// Not this:
ListView(
  children: products.map((p) => ProductCard(p)).toList(),
  // Builds all items immediately (memory intensive)
)
```

### Image Memory Limits

```dart
// Configure CachedNetworkImage limits
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 400,  // Resize in memory
  memCacheHeight: 400,
  maxWidthDiskCache: 800,  // Resize on disk
  maxHeightDiskCache: 800,
)

// Clear cache when needed
await CachedNetworkImage.evictFromCache(url);
await DefaultCacheManager().emptyCache();
```

### Dispose Resources

```dart
@override
void dispose() {
  _scrollController.dispose();
  _debounceTimer?.cancel();
  super.dispose();
}
```

---

## Performance Monitoring

### Measure Load Times

```dart
class PerformanceMonitor {
  static Future<T> measure<T>(
    String name,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      print('✅ $name: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ $name failed: ${stopwatch.elapsedMilliseconds}ms');
      rethrow;
    }
  }
}

// Usage
await PerformanceMonitor.measure('Load categories', () async {
  return await categoryService.getAllCategories();
});
```

### Monitor Memory

```dart
import 'dart:developer' as developer;

void logMemoryUsage() {
  final memoryUsage = developer.Service.getIsolateMemoryUsage();
  print('Memory: ${memoryUsage / 1024 / 1024}MB');
}
```

### Track Render Performance

```dart
// Enable in main.dart
void main() {
  debugProfileBuildsEnabled = true; // Show rebuild info
  debugPrintRebuildDirtyWidgets = true; // Log rebuilds
  runApp(MyApp());
}
```

---

## Best Practices Summary

### ✅ DO

1. **Use SharedPreferences for small data** (< 100KB) ✅ Current
2. **Cache images** with CachedNetworkImage ✅ Current
3. **Implement pagination** with reasonable page sizes ✅ Current
4. **Use ListView.builder** for lazy loading ✅ Current
5. **Dispose controllers** properly ✅ Current
6. **Show loading states** with shimmer ✅ Current
7. **Handle errors** gracefully ✅ Current
8. **Prefetch next page** when user is 75% scrolled
9. **Debounce scroll events** (300ms)
10. **Monitor performance** in production

### ❌ DON'T

1. **Don't load all data at once** - Use pagination
2. **Don't cache everything forever** - Use TTL
3. **Don't block UI thread** - Use isolates for heavy tasks
4. **Don't ignore memory leaks** - Profile regularly
5. **Don't fetch same data multiple times** - Cache aggressively
6. **Don't use large images** - Compress and resize
7. **Don't rebuild unnecessarily** - Use const, keys
8. **Don't forget error handling** - Always have fallback

---

## Migration Roadmap

### Now (SharedPreferences) ✅

- Good for MVP
- < 100KB data
- 24h TTL
- Simple to maintain

### Near Future (Hive) 🎯

- When data grows > 100KB
- Need faster reads
- Want type safety
- 1-2 days to migrate

### Long Term (Isar + Advanced) 🚀

- Large scale (1000+ products)
- Need search
- Complex queries
- Offline-first
- 1 week to implement

---

**Kết luận:**

- ✅ Current implementation với SharedPreferences là **đủ tốt** cho giai đoạn đầu
- 🎯 Nâng cấp lên **Hive** khi app phát triển và có nhiều data hơn
- 🚀 **Isar** cho scale lớn trong tương lai
- 💡 **CachedNetworkImage** đang hoạt động tốt, không cần thay đổi
- ⚡ Focus vào **optimization hiện tại**: prefetch, debounce, memory management

---

**Last Updated**: November 27, 2025
