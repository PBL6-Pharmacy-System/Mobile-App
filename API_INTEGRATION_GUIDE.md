# 🚀 Hướng dẫn Tích hợp API Backend

## ✅ Đã Fix:
1. ✅ ProductModel với null safety và helper getters
2. ✅ Các class Categories, Suppliers, Unittype với empty constructors
3. ✅ Tất cả file đã được update để không phụ thuộc fake data
4. ✅ API Service structure đã được tạo

## 📦 Bước 1: Cài đặt packages

Thêm vào `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.4.0
  provider: ^6.1.1  # Nếu chưa có
```

Chạy lệnh:
```bash
flutter pub get
```

## ⚙️ Bước 2: Cấu hình URL Backend

Mở file: `lib/services/api_service.dart`

Thay đổi `baseUrl` theo môi trường:

```dart
// Nếu test trên Android Emulator:
static const String baseUrl = 'http://10.0.2.2:3000/api';

// Nếu test trên iOS Simulator:
static const String baseUrl = 'http://localhost:3000/api';

// Nếu test trên thiết bị thật:
static const String baseUrl = 'http://192.168.1.X:3000/api'; // Thay X bằng IP máy tính
```

### Cách tìm IP máy tính:

**Windows:**
```bash
ipconfig
# Tìm "IPv4 Address" trong phần WiFi/Ethernet
```

**Mac/Linux:**
```bash
ifconfig
# Hoặc
ip addr show
```

## 🔧 Bước 3: Sử dụng API trong các trang

### CategoryPage - Load Products từ API

```dart
import 'package:pharmacy_app/services/product_service.dart';

class _CategoryPageState extends State<CategoryPage> {
  final ProductService _productService = ProductService();
  bool isLoading = false;
  
  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    
    try {
      final products = await _productService.getProductsByCategory(
        selectedCategory.id.toString()
      );
      
      setState(() {
        listProduct = products;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  @override
  void initState() {
    super.initState();
    loadProducts();
  }
}
```

### SearchPage - Search Products từ API

```dart
import 'package:pharmacy_app/services/product_service.dart';

class _SearchPageState extends State<SearchPage> {
  final ProductService _productService = ProductService();
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }
    
    setState(() => isSearching = true);
    
    try {
      final results = await _productService.searchProducts(query);
      setState(() {
        searchResults = results;
        isSearching = true;
      });
    } catch (e) {
      setState(() {
        searchResults = [];
        isSearching = true;
      });
    }
  }
}
```

## 🔍 Bước 4: Test API

### 1. Test bằng Postman

```
GET http://localhost:3000/api/products
GET http://localhost:3000/api/products?category_id=1
GET http://localhost:3000/api/products/search?q=vitamin
GET http://localhost:3000/api/products/1
```

### 2. Kiểm tra Response Format

Backend của bạn nên trả về format:

**Option 1: Với wrapper**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Paracetamol",
      "price": "50000",
      "images": ["url1", "url2"],
      "categories": {
        "id": 1,
        "name": "Thuốc"
      },
      ...
    }
  ]
}
```

**Option 2: Array trực tiếp**
```json
[
  {
    "id": 1,
    "name": "Paracetamol",
    ...
  }
]
```

ProductService đã được code để hỗ trợ cả 2 format!

## ⚠️ Troubleshooting

### Lỗi: "Unable to connect to server"

1. **Kiểm tra Backend đang chạy:**
   ```bash
   # Trong folder backend
   npm start
   # hoặc
   node server.js
   ```

2. **Kiểm tra CORS trong Backend:**
   ```javascript
   const cors = require('cors');
   app.use(cors());
   ```

3. **Kiểm tra URL đúng:**
   - Emulator: `10.0.2.2`
   - Real device: IP máy tính

### Lỗi Parse JSON

- Xem log console: `🔵 API: ...`
- Kiểm tra format JSON từ Backend
- Đảm bảo field names match với ProductModel

### Lỗi: "Target of URI doesn't exist: 'package:dio/dio.dart'"

Chạy:
```bash
flutter pub get
flutter clean
flutter pub get
```

## 📱 Test Flow

1. ✅ Chạy Backend: `npm start`
2. ✅ Test API bằng Postman
3. ✅ Cập nhật `baseUrl` trong `api_service.dart`
4. ✅ Run Flutter app: `flutter run`
5. ✅ Kiểm tra logs trong console
6. ✅ Test từng tính năng

## 🎯 Kết luận

Hệ thống đã sẵn sàng để tích hợp API:

- ✅ ProductModel đã fix null safety
- ✅ Services đã được tạo
- ✅ UI đã xử lý empty states
- ✅ Error handling đã có

**Chỉ cần:**
1. Cài `dio` package
2. Cấu hình đúng URL
3. Đảm bảo Backend chạy
4. Test!

Happy Coding! 🚀
