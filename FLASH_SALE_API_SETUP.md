# 🔥 Hướng dẫn Fetch API Flash Sale

## ✅ Đã được thiết lập:

1. ✅ **FlashSaleService** - Service để gọi API
2. ✅ **FlashSaleProvider** - State management với Provider
3. ✅ **FlashSaleProductModel** - Model xử lý dữ liệu
4. ✅ **ApiConfig** - Cấu hình endpoint
5. ✅ **UI đã được cập nhật** để sử dụng FlashSaleService

## 📡 Endpoint Backend

```
GET http://localhost:3000/api/flashsales/active
```

### Response Format từ Backend

Backend cần trả về JSON theo format sau:

```json
{
  "flashsales": [
    {
      "id": 1,
      "name": "Paracetamol 500mg",
      "price": 50000,
      "sale_price": 35000,
      "image_url": "https://example.com/image.jpg",
      "description": "Thuốc giảm đau, hạ sốt",
      "usage": "Uống 1-2 viên mỗi 4-6 giờ",
      "ingredients": "Paracetamol 500mg",
      "sale_start_time": "2024-01-01T00:00:00Z",
      "sale_end_time": "2024-01-31T23:59:59Z",
      "stock_quantity": 100,
      "category": {
        "id": 1,
        "name": "Thuốc giảm đau"
      }
    }
  ]
}
```

**Các field quan trọng:**
- `price` hoặc `original_price` - Giá gốc (có thể là string hoặc number)
- `sale_price` hoặc `salePrice` - Giá khuyến mãi
- `image_url` hoặc `image` - URL hình ảnh
- `sale_start_time` - Thời gian bắt đầu (ISO 8601 format)
- `sale_end_time` - Thời gian kết thúc

## ⚙️ Bước 1: Cấu hình URL Backend

Mở file: `lib/configs/api_config.dart`

```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';  // Android Emulator
// static const String baseUrl = 'http://localhost:3000/api';  // iOS Simulator
// static const String baseUrl = 'http://192.168.1.xxx:3000/api';  // Thiết bị thật
```

### Cách chọn URL đúng:

| Môi trường | URL |
|-----------|-----|
| **Android Emulator** | `http://10.0.2.2:3000/api` |
| **iOS Simulator** | `http://localhost:3000/api` |
| **Thiết bị thật** | `http://[IP_MÁY_TÍNH]:3000/api` |

#### Tìm IP máy tính:

**Windows:**
```bash
ipconfig
# Tìm "IPv4 Address" trong phần WiFi/Ethernet
# Ví dụ: 192.168.1.5
```

**Mac/Linux:**
```bash
ifconfig | grep "inet "
# Hoặc
ip addr show
```

## 🚀 Bước 2: Test Backend

### 1. Đảm bảo Backend đang chạy:

```bash
cd backend_folder
npm start
# hoặc
node server.js
```

### 2. Test bằng Postman hoặc Browser:

```
GET http://localhost:3000/api/flashsales/active
```

Phải trả về dữ liệu JSON với format như trên.

### 3. Kiểm tra CORS trong Backend:

File `server.js` hoặc `app.js` cần có:

```javascript
const cors = require('cors');
app.use(cors());
```

## 📱 Bước 3: Chạy Flutter App

```bash
flutter pub get
flutter run
```

## 🔍 Debug và Kiểm tra

### 1. Xem logs trong Console:

Khi app chạy, bạn sẽ thấy logs:

```
🔵 API: [DIO] Request: GET http://10.0.2.2:3000/api/flashsales/active
🔵 API: [DIO] Response: 200 OK
🔵 API: {"flashsales":[...]}
```

### 2. Nếu có lỗi:

**"Failed host lookup"** - Sai URL hoặc Backend không chạy
- ✅ Check Backend đang chạy: `netstat -an | grep 3000`
- ✅ Check URL đúng format: `10.0.2.2` cho Android Emulator

**"Connection refused"** - Firewall hoặc Backend không lắng nghe
- ✅ Tắt firewall tạm thời
- ✅ Backend phải lắng nghe `0.0.0.0:3000` không chỉ `localhost:3000`

**"Error 404"** - Endpoint sai
- ✅ Check endpoint: `/api/flashsales/active`
- ✅ Test bằng Postman trước

**"Error 500"** - Lỗi Backend
- ✅ Check logs Backend
- ✅ Check database connection

## 📂 Cấu trúc Code

### Service Layer:
```
lib/services/flash_sale_service.dart
```
- Gọi API và parse JSON thành Model

### State Management:
```
lib/provider/flash_sale_provider.dart
```
- Quản lý state loading, error, data

### UI Component:
```
lib/presentation/home/widgets/flash_sale_section.dart
```
- Hiển thị danh sách Flash Sale
- ✅ ĐÃ CÂP NHẬT để sử dụng FlashSaleService

### Model:
```
lib/models/flash_sale_product_model.dart
```
- Parse JSON linh hoạt (hỗ trợ nhiều format)
- Tính % giảm giá tự động
- Check active status

## 🎯 Cách sử dụng trong UI khác

### Option 1: Dùng Provider (Recommended)

```dart
import 'package:provider/provider.dart';
import 'package:pharmacy_app/provider/flash_sale_provider.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FlashSaleProvider()..fetchActiveFlashSales(),
      child: Consumer<FlashSaleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return CircularProgressIndicator();
          }
          
          if (provider.error != null) {
            return Text('Error: ${provider.error}');
          }
          
          return ListView.builder(
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('${product.salePrice}đ'),
              );
            },
          );
        },
      ),
    );
  }
}
```

### Option 2: Dùng Service trực tiếp

```dart
import 'package:pharmacy_app/services/flash_sale_service.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final FlashSaleService _service = FlashSaleService();
  List<FlashSaleProductModel> products = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    loadData();
  }
  
  Future<void> loadData() async {
    try {
      final data = await _service.getActiveFlashSales();
      setState(() {
        products = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) return CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => Text(products[index].name),
    );
  }
}
```

## ✨ Tính năng đặc biệt của Model

### 1. Parse linh hoạt nhiều format:

```dart
// Backend trả về "price" hoặc "original_price" đều OK
// Backend trả về "sale_price" hoặc "salePrice" đều OK
// Backend trả về "image_url" hoặc "image" đều OK
// Price có thể là: "50000", 50000, hoặc 50000.0
```

### 2. Tính discount % tự động:

```dart
final product = FlashSaleProductModel.fromJson(json);
print(product.discountPercent); // Tự động tính từ originalPrice và salePrice
```

### 3. Check active status:

```dart
if (product.isActive) {
  print('Flash sale đang diễn ra');
}

final remaining = product.remainingTime;
if (remaining != null) {
  print('Còn lại: ${remaining.inHours} giờ');
}
```

## 🔒 Production Checklist

- [ ] Thay đổi `baseUrl` thành production URL
- [ ] Remove hoặc disable `LogInterceptor` trong ApiService
- [ ] Thêm error tracking (Sentry, Firebase Crashlytics)
- [ ] Thêm retry mechanism cho failed requests
- [ ] Cache data với SharedPreferences
- [ ] Thêm pull-to-refresh
- [ ] Handle offline mode

## 🆘 Support

Nếu gặp vấn đề:
1. Check logs trong console
2. Test API bằng Postman
3. Verify Backend response format
4. Check network configuration

Happy Coding! 🚀
