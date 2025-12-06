# Hướng Dẫn Tích Hợp Chức Năng Giỏ Hàng

## 📦 Tổng Quan

Chức năng giỏ hàng đã được thiết kế hoàn chỉnh với:

- ✅ API integration với backend
- ✅ Widget `AddToCartButton` tái sử dụng
- ✅ Xác thực người dùng
- ✅ Xử lý lỗi và thông báo
- ✅ Hỗ trợ nhiều đơn vị sản phẩm

## 🔧 Cấu Trúc Code

### 1. Service Layer

**File**: `lib/services/cart_service.dart`

```dart
class CartService {
  // Thêm sản phẩm vào giỏ hàng
  Future<bool> addToCart({
    required int customerId,
    required int productId,
    required int productUnitId,
    required int quantity,
    double? unitPrice,
    int? branchId,
  });

  // Lấy giỏ hàng
  Future<CartModel?> getCart(int customerId);

  // Cập nhật số lượng
  Future<CartModel?> updateCartItem({
    required int customerId,
    required int itemId,
    required int quantity,
  });

  // Xóa sản phẩm
  Future<CartModel?> removeCartItem({
    required int customerId,
    required int itemId,
  });

  // Xóa toàn bộ giỏ hàng
  Future<bool> clearCart(int customerId);
}
```

### 2. Widget Component

**File**: `lib/presentation/cart/widgets/add_to_cart_button.dart`

Widget tái sử dụng để thêm sản phẩm vào giỏ hàng với đầy đủ xử lý lỗi và thông báo.

## 🚀 Cách Sử Dụng

### Ví Dụ 1: Thêm vào giỏ hàng với đơn vị cơ bản

```dart
import 'package:pharmacy_app/presentation/cart/widgets/add_to_cart_button.dart';

// Trong widget của bạn
AddToCartButton(
  product: productModel,
  quantity: 1,
  onSuccess: () {
    // Callback khi thêm thành công
    print('Đã thêm vào giỏ hàng!');
  },
  onLoginRequired: () {
    // Custom behavior khi cần đăng nhập
    Navigator.pushNamed(context, '/login');
  },
)
```

### Ví Dụ 2: Thêm với đơn vị và giá tùy chỉnh

```dart
// Trong trang chi tiết sản phẩm với nhiều đơn vị
class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int selectedUnitId = 0;
  double selectedPrice = 0;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    // Set đơn vị mặc định
    selectedUnitId = widget.product.baseUnitId;
    selectedPrice = double.parse(widget.product.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Thông tin sản phẩm...

          // Chọn đơn vị
          DropdownButton<int>(
            value: selectedUnitId,
            items: productUnits.map((unit) {
              return DropdownMenuItem(
                value: unit.id,
                child: Text('${unit.name} - ${unit.price} VNĐ'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedUnitId = value!;
                selectedPrice = getUnitPrice(value);
              });
            },
          ),

          // Chọn số lượng
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (quantity > 1) {
                    setState(() => quantity--);
                  }
                },
              ),
              Text('$quantity'),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() => quantity++);
                },
              ),
            ],
          ),

          // Nút thêm giỏ hàng
          AddToCartButton(
            product: widget.product,
            quantity: quantity,
            selectedUnitId: selectedUnitId,
            unitPrice: selectedPrice,
            onSuccess: () {
              // Có thể cập nhật UI hoặc điều hướng
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã thêm vào giỏ hàng')),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### Ví Dụ 3: Sử dụng CartService trực tiếp

```dart
import 'package:pharmacy_app/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';

class CustomAddToCartWidget extends StatefulWidget {
  final ProductModel product;

  @override
  _CustomAddToCartWidgetState createState() => _CustomAddToCartWidgetState();
}

class _CustomAddToCartWidgetState extends State<CustomAddToCartWidget> {
  final CartService _cartService = CartService();
  bool isLoading = false;

  Future<void> _addToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      // Hiển thị dialog yêu cầu đăng nhập
      showLoginDialog();
      return;
    }

    final customerId = authProvider.currentUser?.customerId;
    if (customerId == null) {
      showError('Không tìm thấy thông tin khách hàng');
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await _cartService.addToCart(
        customerId: customerId,
        productId: widget.product.id,
        productUnitId: widget.product.baseUnitId,
        quantity: 1,
        unitPrice: double.parse(widget.product.price),
      );

      if (success) {
        showSuccess('Đã thêm vào giỏ hàng');
      } else {
        showError('Không thể thêm sản phẩm');
      }
    } catch (e) {
      showError(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : _addToCart,
      child: isLoading
        ? CircularProgressIndicator()
        : Text('Thêm vào giỏ'),
    );
  }
}
```

## 📋 Checklist Tích Hợp

### Trong Product List / Grid

```dart
// lib/presentation/products/widgets/product_item.dart

import 'package:pharmacy_app/presentation/cart/widgets/add_to_cart_button.dart';

Widget buildProductItem(ProductModel product) {
  return Card(
    child: Column(
      children: [
        Image.network(product.image),
        Text(product.name),
        Text('${product.price} VNĐ'),

        // Thêm nút giỏ hàng
        AddToCartButton(
          product: product,
          quantity: 1,
        ),
      ],
    ),
  );
}
```

### Trong Product Detail Page

```dart
// lib/presentation/products/product_detail_page.dart

// Thêm ở cuối trang
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: Container(
    padding: EdgeInsets.all(16),
    color: Colors.white,
    child: AddToCartButton(
      product: product,
      quantity: selectedQuantity,
      selectedUnitId: selectedUnitId,
      unitPrice: selectedUnitPrice,
    ),
  ),
)
```

### Trong Flash Sale Items

```dart
// lib/presentation/flash_sale/widgets/flash_sale_item.dart

AddToCartButton(
  product: product,
  quantity: 1,
  unitPrice: flashsalePrice, // Giá flashsale
)
```

## 🔐 Xác Thực & Bảo Mật

### 1. Kiểm tra đăng nhập tự động

Widget `AddToCartButton` tự động:

- ✅ Kiểm tra người dùng đã đăng nhập
- ✅ Hiển thị dialog yêu cầu đăng nhập nếu cần
- ✅ Chỉ cho phép Customer thêm giỏ hàng

### 2. Xử lý Token

```dart
// Token được tự động thêm vào headers bởi ApiService
// Không cần xử lý thủ công
```

## ⚠️ Xử Lý Lỗi

### Các lỗi phổ biến:

1. **Sản phẩm hết hàng**

```
Error: "Sản phẩm không đủ số lượng trong kho"
```

2. **Giá thay đổi**

```
Error: "Giá sản phẩm đã thay đổi. Giá hiện tại: xxx VNĐ"
```

3. **Vượt giới hạn số lượng**

```
Error: "Số lượng tối đa cho mỗi sản phẩm là 100"
```

4. **Giỏ hàng đầy**

```
Error: "Giỏ hàng chỉ chứa tối đa 50 loại sản phẩm khác nhau"
```

### Custom error handling:

```dart
AddToCartButton(
  product: product,
  onSuccess: () {
    // Xử lý thành công
  },
  onLoginRequired: () {
    // Xử lý khi cần đăng nhập
    showCustomLoginDialog();
  },
)
```

## 🎨 Tùy Chỉnh Giao Diện

### Custom button style:

```dart
// Bạn có thể tạo custom button riêng
class CustomAddToCartButton extends StatelessWidget {
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AddToCartButton(
        product: product,
        // ... các props khác
      ),
    );
  }
}
```

## 📊 API Endpoints

Backend API được sử dụng:

```
POST /api/cart/:customerId/add
- Body: { productId, productUnitId, quantity, unitPrice?, branchId? }
- Response: { success, message, data }

GET /api/cart/:customerId
- Response: { success, data: CartModel }

PUT /api/cart/:customerId/items/:itemId
- Body: { quantity }
- Response: { success, message, data }

DELETE /api/cart/:customerId/items/:itemId
- Response: { success, message }
```

## 🐛 Debugging

### Enable logs:

Tất cả cart operations đều có logs:

```
📦 [CartService] Adding to cart: productId=123, quantity=2
✅ [CartService] Added to cart successfully
❌ [CartService] Add to cart error: ...
```

### Check token:

```dart
final token = await AuthService().getAccessToken();
print('Token: $token');
```

### Check customer ID:

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
print('Customer ID: ${authProvider.currentUser?.customerId}');
```

## ✅ Testing

### Test flow:

1. Đăng nhập với tài khoản customer
2. Kiểm tra `customerId` có trong token
3. Thử thêm sản phẩm vào giỏ hàng
4. Xác nhận thông báo thành công
5. Kiểm tra giỏ hàng có sản phẩm

### Test cases:

- [ ] Thêm sản phẩm khi chưa đăng nhập → Hiện dialog login
- [ ] Thêm sản phẩm với số lượng = 1
- [ ] Thêm sản phẩm với số lượng > 1
- [ ] Thêm cùng sản phẩm 2 lần → Cộng dồn số lượng
- [ ] Thêm với đơn vị khác nhau
- [ ] Thêm khi hết hàng → Hiện lỗi
- [ ] Thêm vượt giới hạn → Hiện lỗi

## 📱 Next Steps

Các tính năng có thể mở rộng:

1. **Badge số lượng giỏ hàng** trên icon
2. **Animation** khi thêm sản phẩm
3. **Quick add** từ product list
4. **Undo** sau khi thêm
5. **Recommend** sản phẩm liên quan

## 🆘 Hỗ Trợ

Nếu gặp vấn đề:

1. Kiểm tra logs trong console
2. Verify backend API đang chạy
3. Kiểm tra token trong SecureStorage
4. Test với Postman trước

---

**Tài liệu này được tạo ngày**: 27/11/2025
**Backend API version**: 1.0.0
**Flutter SDK**: >=3.0.0
