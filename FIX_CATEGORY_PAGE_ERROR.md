# ⚠️ LỖI VÀ GIẢI PHÁP - category_page.dart

## Vấn đề

File `category_page.dart` đang sử dụng:

- ❌ `fake_data.dart` (không tồn tại)
- ❌ `SubCategoryModel` (không tồn tại)
- ❌ `categories` global variable (không tồn tại)
- ❌ Cấu trúc: Category → SubCategory → SubItem (không khớp với API)

## API thật trả về

```dart
CategoryModel {
  id: int
  name: String
  productCount: int
  children: List<CategoryModel>  // Nested recursively
}
```

## Giải pháp

### ✅ Option 1: Sử dụng CategoryScreen mới (Khuyến nghị)

File `lib/presentation/category/category_screen.dart` đã được tạo sẵn:

- ✅ Hoạt động hoàn toàn với API thật
- ✅ Caching với SharedPreferences
- ✅ Infinite scroll pagination
- ✅ UI đẹp với tabs và subcategories

**Cách thay thế:**

```dart
// Thay vì:
import 'package:pharmacy_app/presentation/category/category_page.dart';
Navigator.push(context, MaterialPageRoute(
  builder: (context) => CategoryPage(),
));

// Dùng:
import 'package:pharmacy_app/presentation/category/category_screen.dart';
Navigator.push(context, MaterialPageRoute(
  builder: (context) => CategoryScreen(),
));
```

### ⚠️ Option 2: Sửa category_page.dart (Phức tạp)

Cần viết lại toàn bộ file vì:

1. Xóa tất cả logic SubCategoryModel
2. Thay `subCategories` → `children`
3. Thay `subItems` → nested `children`
4. Load categories từ API thay vì fake data
5. Thay đổi UI logic cho cấu trúc mới

**Ước tính:** 2-3 giờ để refactor toàn bộ

### 🔧 Option 3: Sửa nhanh - Chỉ hiển thị main categories

Nếu muốn giữ `category_page.dart` đơn giản:

```dart
// Chỉ hiển thị danh sách categories chính
// Không có subcategories/subitems
// Load products theo category chính
```

Thời gian: 30 phút

## Khuyến nghị

**Dùng CategoryScreen mới!** Vì:

- ✅ Đã sẵn sàng, hoạt động tốt
- ✅ Full features (cache, pagination, shimmer loading)
- ✅ Không cần sửa gì
- ✅ Tiết kiệm thời gian

**File cần thay đổi:**

1. `lib/presentation/home/widgets/home_category.dart` - Thay CategoryPage → CategoryScreen
2. Các file navigation khác dẫn đến CategoryPage

## Tóm tắt

**Lỗi hiện tại:**

- `category_page.dart` → Dùng fake data cũ, cấu trúc không khớp với API
- `fake_data.dart` → Đã xóa (dùng API thật)
- `SubCategoryModel` → Không tồn tại trong cấu trúc mới

**Đã sửa:**

- ✅ `product_model.dart` - Sửa getter category
- ✅ `category_service.dart` - Xóa unused import
- ✅ `category_screen.dart` - Xóa unused field

**Cần làm:**

- 🔄 Thay tất cả `CategoryPage` → `CategoryScreen` trong app
- 🗑️ Xóa `category_page.dart` (optional, nếu không dùng)
- 🗑️ Xóa `fake_data.dart` import ở các file khác
