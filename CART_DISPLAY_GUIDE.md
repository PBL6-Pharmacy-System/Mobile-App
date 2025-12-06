# Hướng Dẫn Sử Dụng Giỏ Hàng

## 🎯 Tổng Quan

Hệ thống giỏ hàng đã được triển khai đầy đủ với các chức năng:

- ✅ Hiển thị danh sách sản phẩm trong giỏ
- ✅ Cập nhật số lượng (+/-)
- ✅ Xóa sản phẩm
- ✅ Tính tổng tiền tự động
- ✅ Áp dụng voucher giảm giá
- ✅ Badge hiển thị số lượng items

## 📁 Files Đã Tạo

### 1. **CartScreen** - Màn hình giỏ hàng

```
lib/presentation/cart/cart_screen.dart
```

**Features:**

- Hiển thị danh sách sản phẩm
- Pull-to-refresh
- Empty state khi giỏ trống
- Loading & error states
- Quantity controls
- Remove item với confirmation
- Cart summary với tổng tiền

### 2. **CartBadge** - Badge số lượng

```
lib/presentation/cart/widgets/cart_badge.dart
```

**Features:**

- Hiển thị số lượng items trong giỏ
- Auto-update khi giỏ thay đổi
- Badge màu đỏ
- Giới hạn hiển thị 99+

## 🚀 Cách Sử Dụng

### 1. Navigate tới CartScreen

**Từ bất kỳ đâu:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const CartScreen()),
);
```

**Hoặc dùng route name (nếu đã config):**

```dart
Navigator.pushNamed(context, '/cart');
```

### 2. Thêm CartBadge vào AppBar

**Trong HomePage hoặc bất kỳ screen nào:**

```dart
import 'package:pharmacy_app/presentation/cart/cart_screen.dart';
import 'package:pharmacy_app/presentation/cart/widgets/cart_badge.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Trang chủ'),
      actions: [
        // Cart badge
        CartBadge(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartScreen(),
              ),
            );
          },
        ),
      ],
    ),
    body: // Your content
  );
}
```

### 3. Thêm Sản Phẩm Vào Giỏ

**Đã có AddToCartButton widget:**

```dart
import 'package:pharmacy_app/presentation/cart/widgets/add_to_cart_button.dart';

// Trong product card/detail
AddToCartButton(
  product: product,  // ProductModel object
)
```

## 🎨 UI Components

### CartScreen States

#### 1. **Loading State**

```dart
if (cartProvider.isLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

#### 2. **Error State**

```dart
if (cartProvider.error != null) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.error_outline),
        Text(cartProvider.error!),
        ElevatedButton(onPressed: _loadCart, child: Text('Thử lại')),
      ],
    ),
  );
}
```

#### 3. **Empty State**

```dart
if (cartProvider.itemCount == 0) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.shopping_cart_outlined, size: 100),
        Text('Giỏ hàng trống'),
        ElevatedButton(onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}
```

#### 4. **Cart with Items**

```dart
// List of cart items
ListView.separated(
  itemCount: cartProvider.cart!.items.length,
  itemBuilder: (context, index) {
    final item = cartProvider.cart!.items[index];
    return _CartItemCard(item: item);
  },
);

// Cart summary at bottom
_buildCartSummary(cartProvider);
```

### Cart Item Card

**Display:**

- ✅ Product image (80x80)
- ✅ Product name
- ✅ Unit name (hộp, viên, vỉ...)
- ✅ Price (with discount if applicable)
- ✅ Quantity controls (+/-)
- ✅ Remove button

**Example:**

```
┌─────────────────────────────────────┐
│ [Image] Paracetamol 500mg           │
│         Đơn vị: Hộp                 │
│         50.000 ₫                    │
│         [-] 2 [+]        [🗑️]       │
└─────────────────────────────────────┘
```

### Cart Summary

**Display:**

```
Tạm tính:              100.000 ₫
Giảm giá (CODE10):     -10.000 ₫
───────────────────────────────────
Tổng cộng:              90.000 ₫

[    Tiến hành đặt hàng    ]
```

## 🔄 Cart Operations

### Fetch Cart

```dart
final cartProvider = context.read<CartProvider>();
final authProvider = context.read<AuthProvider>();

final customerId = authProvider.currentUser?.customerId;
await cartProvider.fetchCart(customerId);
```

### Update Quantity

```dart
await cartProvider.updateItemQuantity(
  customerId: customerId,
  itemId: item.id,
  quantity: newQuantity,
);
```

### Remove Item

```dart
await cartProvider.removeItem(
  customerId: customerId,
  itemId: item.id,
);
```

### Clear Cart

```dart
await cartProvider.clearCart(customerId);
```

### Apply Voucher

```dart
final success = await cartProvider.applyVoucher(
  customerId: customerId,
  voucherCode: 'CODE10',
);

if (success) {
  print('Voucher applied: ${cartProvider.voucherDiscount}');
}
```

## 📊 Cart Provider State

### Getters

```dart
// Cart data
CartModel? cart = cartProvider.cart;
List<CartItemModel> items = cartProvider.cart?.items ?? [];

// State
bool isLoading = cartProvider.isLoading;
String? error = cartProvider.error;

// Summary
int itemCount = cartProvider.itemCount;
double subtotal = cartProvider.subtotal;
double total = cartProvider.total;

// Voucher
String? voucherCode = cartProvider.appliedVoucherCode;
double discount = cartProvider.voucherDiscount;
```

### Listening to Changes

```dart
// Using Consumer
Consumer<CartProvider>(
  builder: (context, cartProvider, child) {
    return Text('Items: ${cartProvider.itemCount}');
  },
)

// Using Provider.of with listen: true
final cartProvider = Provider.of<CartProvider>(context);

// Using context.watch
final cartProvider = context.watch<CartProvider>();
```

## 🎯 Integration với Existing Code

### Trong HomePage

```dart
import 'package:pharmacy_app/presentation/cart/cart_screen.dart';
import 'package:pharmacy_app/presentation/cart/widgets/cart_badge.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhà thuốc'),
        actions: [
          // Cart badge với số lượng
          CartBadge(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: // Your content
    );
  }
}
```

### Trong Product Card/Detail

```dart
import 'package:pharmacy_app/presentation/cart/widgets/add_to_cart_button.dart';

// Product card
Card(
  child: Column(
    children: [
      // Product image, name, price...

      // Add to cart button
      AddToCartButton(
        product: product,
      ),
    ],
  ),
)
```

## 🔍 Debug & Troubleshooting

### Check Cart Data

```dart
final cart = cartProvider.cart;
if (cart != null) {
  print('Cart ID: ${cart.id}');
  print('Customer ID: ${cart.customerId}');
  print('Items count: ${cart.items.length}');
  print('Subtotal: ${cart.subtotal}');
  print('Total: ${cart.total}');

  for (var item in cart.items) {
    print('Item: ${item.productUnit?.product?.name}');
    print('  Quantity: ${item.quantity}');
    print('  Price: ${item.price}');
    print('  Subtotal: ${item.subtotal}');
  }
}
```

### Logs trong Console

#### Fetch Cart Success:

```
📦 [CartService] Fetching cart for customer: 123
✅ Cart loaded with 3 items
```

#### Update Quantity:

```
📦 [CartService] Updating cart item: itemId=456, quantity=2
✅ [CartService] Updated cart item successfully
```

#### Remove Item:

```
📦 [CartService] Removing cart item: itemId=456
✅ [CartService] Removed cart item successfully
```

#### Error:

```
❌ [CartService] Get cart error: Connection failed
❌ [CartProvider] Fetch cart error: ...
```

## 🎨 Customization

### Thay Đổi Colors

```dart
// Trong cart_screen.dart

// Primary color
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,  // Đổi màu nút
  ),
)

// Price color
Text(
  '${_formatPrice(item.price)} ₫',
  style: const TextStyle(
    color: Colors.red,  // Đổi màu giá
  ),
)
```

### Custom Badge Style

```dart
// Trong cart_badge.dart

Container(
  decoration: BoxDecoration(
    color: Colors.orange,  // Đổi màu badge
    shape: BoxShape.circle,
  ),
)
```

### Format Số Tiền

```dart
// Hiện tại: 100.000 ₫
String _formatPrice(double price) {
  return price.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
}

// Nếu muốn: 100,000 ₫
String _formatPrice(double price) {
  return price.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}
```

## ✅ Testing Checklist

### Manual Testing

- [ ] Mở CartScreen khi giỏ trống → Hiển thị empty state
- [ ] Thêm sản phẩm → Badge cập nhật số lượng
- [ ] Pull to refresh → Reload cart
- [ ] Tăng số lượng (+) → Cập nhật thành công
- [ ] Giảm số lượng (-) → Cập nhật thành công
- [ ] Nhấn xóa → Hiện confirmation dialog
- [ ] Xác nhận xóa → Sản phẩm bị xóa
- [ ] Tổng tiền tự động cập nhật
- [ ] Badge hiển thị đúng số lượng

### Error Cases

- [ ] Không có internet → Hiển thị error state
- [ ] Chưa đăng nhập → Hiện "Vui lòng đăng nhập"
- [ ] Backend lỗi → Hiển thị error message
- [ ] Cập nhật số lượng thất bại → Show snackbar lỗi

## 🚀 Next Steps

### Tích hợp Checkout

```dart
// Trong cart_screen.dart

ElevatedButton(
  onPressed: () {
    // Navigate to checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cart: cartProvider.cart!,
        ),
      ),
    );
  },
  child: const Text('Tiến hành đặt hàng'),
)
```

### Thêm Voucher Input

```dart
// Thêm TextField để nhập voucher
Row(
  children: [
    Expanded(
      child: TextField(
        controller: voucherController,
        decoration: InputDecoration(
          hintText: 'Nhập mã giảm giá',
        ),
      ),
    ),
    ElevatedButton(
      onPressed: () async {
        final success = await cartProvider.applyVoucher(
          customerId: customerId,
          voucherCode: voucherController.text,
        );
        // Show result
      },
      child: const Text('Áp dụng'),
    ),
  ],
)
```

### Save to Local (Offline Support)

```dart
// Trong CartProvider

Future<void> saveCartToLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final cartJson = jsonEncode(_cart?.toJson());
  await prefs.setString('cart', cartJson);
}

Future<void> loadCartFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final cartJson = prefs.getString('cart');
  if (cartJson != null) {
    _cart = CartModel.fromJson(jsonDecode(cartJson));
    notifyListeners();
  }
}
```

---

**Created**: 27/11/2025  
**Version**: 1.0.0  
**Backend API**: v1.0.0
