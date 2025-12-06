# 📚 Hướng dẫn sử dụng API Categories và Products

Tài liệu này hướng dẫn cách lấy cây categories và lấy sản phẩm theo category từ Backend API.

---

## 🌳 1. API Lấy Cây Categories

### 📍 Endpoint
```
GET /api/categories/tree
```

### 📤 Response Format
Backend trả về cây phân cấp đầy đủ của categories với subcategories và subitems:

```json
[
  {
    "id": 128,
    "name": "Thực phẩm chức năng",
    "icon": "healing",
    "sub_categories": [
      {
        "name": "Vitamin & Khoáng chất",
        "icon": "medication",
        "sub_items": [
          "Bổ sung Canxi & Vitamin D",
          "Vitamin tổng hợp",
          "Dầu cá, Omega 3, DHA"
        ]
      },
      {
        "name": "Sinh lý - Nội tiết tố",
        "icon": "favorite",
        "sub_items": [
          "Sinh lý nam",
          "Sinh lý nữ"
        ]
      }
    ]
  },
  {
    "id": 129,
    "name": "Thuốc không kê đơn",
    "icon": "medical_services",
    "sub_categories": [...]
  }
]
```

### 🧪 Test với curl
```bash
curl http://localhost:3000/api/categories/tree
```

### 🎯 Sử dụng trong Flutter

#### 1. Import Service
```dart
import 'package:pharmacy_app/services/category_service.dart';
```

#### 2. Lấy tất cả categories
```dart
final CategoryService _categoryService = CategoryService();

Future<void> loadCategories() async {
  try {
    final categories = await _categoryService.getAllCategories();
    
    print('Số lượng categories: ${categories.length}');
    
    // Duyệt qua từng category
    for (var category in categories) {
      print('Category: ${category.name}');
      print('  - Icon: ${category.icon}');
      print('  - Subcategories: ${category.subCategories.length}');
      
      // Duyệt qua subcategories
      for (var subCategory in category.subCategories) {
        print('    Subcategory: ${subCategory.name}');
        print('      - SubItems: ${subCategory.subItems.join(", ")}');
      }
    }
    
  } catch (e) {
    print('Lỗi khi tải categories: $e');
  }
}
```

#### 3. Lấy category theo ID
```dart
Future<void> loadCategoryById(int categoryId) async {
  try {
    final category = await _categoryService.getCategoryById(categoryId);
    print('Category: ${category.name}');
  } catch (e) {
    print('Lỗi: $e');
  }
}
```

#### 4. Lấy sản phẩm của category
```dart
Future<void> loadCategoryProducts(int categoryId) async {
  try {
    // Lấy sản phẩm bao gồm cả subcategories
    final result = await _categoryService.getCategoryProducts(
      categoryId,
      page: 1,
      limit: 20,
      includeChildren: true, // true = bao gồm sản phẩm của subcategories
    );
    
    print('Total products: ${result['total']}');
    print('Current page: ${result['page']}');
    
  } catch (e) {
    print('Lỗi: $e');
  }
}
```

---

## 🛍️ 2. API Lấy Sản phẩm theo Category

### 📍 Endpoint chính
```
GET /api/categories/:categoryId/products
```

### 🎯 Query Parameters
- `page` (optional): Số trang, mặc định = 1
- `limit` (optional): Số sản phẩm mỗi trang, mặc định = 20
- `includeChildren` (optional): Bao gồm sản phẩm của subcategories không, mặc định = true

### 📝 Examples

#### A. Lấy sản phẩm của category (bao gồm subcategories)
```bash
# Category ID = 128 là "Thực phẩm chức năng"
curl "http://localhost:3000/api/categories/128/products?page=1&limit=20"
```

#### B. Lấy sản phẩm chỉ từ category đó (không bao gồm subcategories)
```bash
curl "http://localhost:3000/api/categories/128/products?includeChildren=false"
```

### 📤 Response Format
```json
{
  "products": [
    {
      "id": 1,
      "name": "Viên uống Vitamin C 1000mg",
      "price": "125000",
      "unit": "Hộp 30 viên",
      "image": "https://example.com/image.jpg",
      "category": "Thực phẩm chức năng",
      "subcategory": "Vitamin & Khoáng chất",
      "subitem": "Vitamin C các loại",
      "description": "Bổ sung vitamin C...",
      "stock": 100
    }
  ],
  "total": 25,
  "page": 1,
  "limit": 20,
  "totalPages": 2
}
```

### 🎯 Sử dụng trong Flutter

#### 1. Import Service
```dart
import 'package:pharmacy_app/services/product_service.dart';
import 'package:pharmacy_app/models/product_model.dart';
```

#### 2. Lấy sản phẩm theo Category ID
```dart
final ProductService _productService = ProductService();

Future<void> loadProductsByCategoryId(int categoryId) async {
  try {
    setState(() {
      isLoading = true;
    });
    
    // Lấy sản phẩm bao gồm cả subcategories
    final products = await _productService.getProductsByCategoryId(
      categoryId,
      page: 1,
      limit: 20,
      includeChildren: true, // Bao gồm sản phẩm của subcategories
    );
    
    print('Tìm thấy ${products.length} sản phẩm');
    
    setState(() {
      listProduct = products;
      isLoading = false;
    });
    
  } catch (e) {
    setState(() {
      isLoading = false;
      errorMessage = e.toString();
    });
    print('Lỗi: $e');
  }
}

// Sử dụng - VD: Category ID = 128 là "Thực phẩm chức năng"
loadProductsByCategoryId(128);

// Lấy sản phẩm chỉ từ category đó (không bao gồm subcategories)
loadProductsByCategoryId(128, includeChildren: false);
```

#### 3. Lấy sản phẩm theo Subcategory/SubItem
```dart
Future<void> loadProductsBySubcategory(String subcategoryName, {String? mainCategory}) async {
  try {
    setState(() {
      isLoading = true;
    });
    
    final products = await _productService.getProductsBySubcategory(
      subcategoryName,
      mainCategoryName: mainCategory,
      page: 1,
      limit: 100,
    );
    
    print('Tìm thấy ${products.length} sản phẩm cho "$subcategoryName"');
    
    setState(() {
      listProduct = products;
      isLoading = false;
    });
    
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    print('Lỗi: $e');
  }
}

// Sử dụng
loadProductsBySubcategory('Vitamin C các loại', mainCategory: 'Thực phẩm chức năng');
```

#### 4. Lấy tất cả sản phẩm
```dart
Future<void> loadAllProducts() async {
  try {
    final products = await _productService.getAllProducts();
    print('Tổng số sản phẩm: ${products.length}');
  } catch (e) {
    print('Lỗi: $e');
  }
}
```

---

## 🔄 3. Flow hoàn chỉnh: Category → Subcategory → Products

### Ví dụ thực tế trong CategoryPage

```dart
import 'package:flutter/material.dart';
import 'package:pharmacy_app/services/category_service.dart';
import 'package:pharmacy_app/services/product_service.dart';
import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/models/product_model.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  
  List<CategoryModel> categories = [];
  CategoryModel? selectedCategory;
  List<ProductModel> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  // Bước 1: Load categories từ API
  Future<void> loadCategories() async {
    try {
      setState(() => isLoading = true);
      
      final categoriesData = await _categoryService.getAllCategories();
      
      setState(() {
        categories = categoriesData;
        if (categories.isNotEmpty) {
          selectedCategory = categories[0];
        }
        isLoading = false;
      });
      
      // Load products của category đầu tiên
      if (selectedCategory != null && selectedCategory!.id != null) {
        loadProductsByCategory(selectedCategory!.id!);
      }
      
    } catch (e) {
      setState(() => isLoading = false);
      print('Lỗi load categories: $e');
    }
  }

  // Bước 2: Load products theo category ID
  Future<void> loadProductsByCategory(int categoryId) async {
    try {
      setState(() => isLoading = true);
      
      final productsData = await _productService.getProductsByCategoryId(
        categoryId,
        page: 1,
        limit: 20,
        includeChildren: true, // Bao gồm sản phẩm của subcategories
      );
      
      setState(() {
        products = productsData;
        isLoading = false;
      });
      
    } catch (e) {
      setState(() => isLoading = false);
      print('Lỗi load products: $e');
    }
  }

  // Bước 3: Load products theo subcategory/subitem
  Future<void> loadProductsBySubcategory(String subcategoryName) async {
    try {
      setState(() => isLoading = true);
      
      final productsData = await _productService.getProductsBySubcategory(
        subcategoryName,
        mainCategoryName: selectedCategory?.name,
        page: 1,
        limit: 100,
      );
      
      setState(() {
        products = productsData;
        isLoading = false;
      });
      
    } catch (e) {
      setState(() => isLoading = false);
      print('Lỗi load products: $e');
    }
  }

  // Xử lý khi chọn category
  void onCategorySelected(CategoryModel category) {
    setState(() {
      selectedCategory = category;
    });
    if (category.id != null) {
      loadProductsByCategory(category.id!);
    }
  }

  // Xử lý khi chọn subcategory/subitem
  void onSubItemSelected(String subItemName) {
    loadProductsBySubcategory(subItemName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Hiển thị categories
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category;
                      
                      return GestureDetector(
                        onTap: () => onCategorySelected(category),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Hiển thị subcategories
                if (selectedCategory != null &&
                    selectedCategory!.subCategories.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedCategory!.subCategories.length,
                      itemBuilder: (context, index) {
                        final subCategory = selectedCategory!.subCategories[index];
                        
                        return PopupMenuButton<String>(
                          onSelected: onSubItemSelected,
                          itemBuilder: (context) {
                            return subCategory.subItems.map((subItem) {
                              return PopupMenuItem<String>(
                                value: subItem,
                                child: Text(subItem),
                              );
                            }).toList();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(subCategory.name),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // Hiển thị products
                Expanded(
                  child: products.isEmpty
                      ? const Center(child: Text('Chưa có sản phẩm'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            
                            return Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product image
                                  Expanded(
                                    child: Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Image.network(
                                          product.image,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.image);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${product.price}đ',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
```

---

## 📝 4. Tóm tắt

### Services đã tạo:

1. **CategoryService** (`lib/services/category_service.dart`):
   - `getAllCategories()` - Lấy toàn bộ cây categories từ `/categories/tree`
   - `getCategoryById(id)` - Lấy category theo ID
   - `getCategoryProducts(categoryId, {page, limit, includeChildren})` - Lấy sản phẩm của category

2. **ProductService** (`lib/services/product_service.dart`):
   - `getAllProducts()` - Lấy tất cả sản phẩm
   - `getProductsByCategoryId(categoryId, {page, limit, includeChildren})` - Lấy sản phẩm theo category ID
   - `getProductsByCategoryName(categoryName)` - Lấy sản phẩm theo tên category (nếu backend hỗ trợ)
   - `getProductsBySubcategory(subcategoryName)` - Lấy sản phẩm theo subcategory/subitem (nếu backend hỗ trợ)
   - `getProductById(id)` - Lấy chi tiết sản phẩm
   - `searchProducts(keyword)` - Tìm kiếm sản phẩm

### Luồng hoạt động:

```
1. Load Categories từ API
   ↓
2. Hiển thị danh sách Categories
   ↓
3. User chọn Category
   ↓
4. Load Products theo Category đã chọn
   ↓
5. User có thể chọn Subcategory/SubItem
   ↓
6. Load Products theo Subcategory/SubItem
```

### Lưu ý quan trọng:

- ✅ Tất cả các API đều có xử lý lỗi (try-catch)
- ✅ Có logging để debug (`print` statements)
- ✅ Hỗ trợ pagination (page, limit)
- ✅ Encode URL để tránh lỗi với ký tự đặc biệt (tiếng Việt)
- ✅ Xử lý nhiều cấu trúc response khác nhau từ backend

---

## 🚀 Sử dụng nhanh

```dart
// 1. Load categories từ API /categories/tree
final categories = await CategoryService().getAllCategories();

// 2. Load products theo category ID (bao gồm subcategories)
final products = await ProductService().getProductsByCategoryId(128);

// 3. Load products chỉ từ category đó (không bao gồm subcategories)
final products = await ProductService().getProductsByCategoryId(128, includeChildren: false);

// 4. Load products theo subcategory (nếu backend hỗ trợ)
final products = await ProductService().getProductsBySubcategory('Vitamin C các loại');
```

## 🧪 Test API với curl

```bash
# 1. Test lấy cây categories
curl http://localhost:3000/api/categories/tree

# 2. Lấy sản phẩm của category (ID=128 là "Thực phẩm chức năng")
curl "http://localhost:3000/api/categories/128/products?page=1&limit=20"

# 3. Lấy sản phẩm chỉ từ category đó (không bao gồm children)
curl "http://localhost:3000/api/categories/128/products?includeChildren=false"
```

---

**Chúc bạn code thành công! 🎉**
