# Enhanced Add to Cart Button - Hướng Dẫn

## 🎨 Tổng Quan

Thư viện widgets nâng cao cho chức năng thêm giỏ hàng với animations, feedback tốt hơn và nhiều tuỳ chọn hiển thị.

## 📦 Các Widget

### 1. EnhancedAddToCartButton

Button đầy đủ tính năng với animations và quantity selector.

**Features:**

- ✅ Animations khi nhấn (scale effect)
- ✅ Loading state với spinner
- ✅ Success state với checkmark
- ✅ Quantity selector tích hợp (optional)
- ✅ Snackbar với link tới giỏ hàng
- ✅ Login dialog đẹp
- ✅ Error handling

### 2. AddToCartIconButton

Icon button nhỏ gọn cho product cards.

**Features:**

- ✅ Circular button với icon
- ✅ Elastic scale animation
- ✅ Loading spinner
- ✅ Compact feedback
- ✅ Shadow effect

## 🚀 Cách Sử Dụng

### EnhancedAddToCartButton

#### **Basic Usage (No Quantity Selector)**

```dart
import 'package:pharmacy_app/presentation/cart/widgets/enhanced_add_to_cart_button.dart';

EnhancedAddToCartButton(
  product: product,
)
```

#### **With Quantity Selector**

```dart
EnhancedAddToCartButton(
  product: product,
  showQuantitySelector: true,
  initialQuantity: 1,
  onSuccess: () {
    print('Product added successfully!');
  },
)
```

#### **With Custom Unit & Price**

```dart
EnhancedAddToCartButton(
  product: product,
  selectedUnitId: selectedUnit.id,
  unitPrice: selectedUnit.price,
  showQuantitySelector: true,
)
```

### AddToCartIconButton

#### **Usage in Product Card**

```dart
import 'package:pharmacy_app/presentation/cart/widgets/enhanced_add_to_cart_button.dart';

// Trong product card
Stack(
  children: [
    // Product image
    Image.network(product.imageUrl),

    // Add to cart icon button
    Positioned(
      bottom: 8,
      right: 8,
      child: AddToCartIconButton(
        product: product,
        onSuccess: () {
          // Refresh cart badge
        },
      ),
    ),
  ],
)
```

## 🎯 Props

### EnhancedAddToCartButton Props

| Prop                   | Type            | Required | Default | Description                  |
| ---------------------- | --------------- | -------- | ------- | ---------------------------- |
| `product`              | `ProductModel`  | ✅ Yes   | -       | Sản phẩm cần thêm vào giỏ    |
| `selectedUnitId`       | `int?`          | ❌ No    | `null`  | ID đơn vị đã chọn            |
| `unitPrice`            | `double?`       | ❌ No    | `null`  | Giá của đơn vị đã chọn       |
| `onSuccess`            | `VoidCallback?` | ❌ No    | `null`  | Callback khi thêm thành công |
| `showQuantitySelector` | `bool`          | ❌ No    | `false` | Hiển thị quantity selector   |
| `initialQuantity`      | `int`           | ❌ No    | `1`     | Số lượng ban đầu             |

### AddToCartIconButton Props

| Prop        | Type            | Required | Default | Description                  |
| ----------- | --------------- | -------- | ------- | ---------------------------- |
| `product`   | `ProductModel`  | ✅ Yes   | -       | Sản phẩm cần thêm vào giỏ    |
| `onSuccess` | `VoidCallback?` | ❌ No    | `null`  | Callback khi thêm thành công |

## 🎬 Animations

### EnhancedAddToCartButton

**Button Press Animation:**

```dart
// Scale down khi nhấn
Tween<double>(begin: 1.0, end: 0.95)
Duration: 200ms
Curve: easeInOut
```

**State Transitions:**

```
IDLE → LOADING → SUCCESS → IDLE
  ↓       ↓         ↓
 Icon  Spinner  Checkmark
```

**Success Animation Flow:**

1. Button turns green
2. Shows checkmark icon
3. Displays snackbar with product info
4. Returns to idle after 1.5s

### AddToCartIconButton

**Elastic Animation:**

```dart
// Elastic scale khi click
Tween<double>(begin: 1.0, end: 1.2)
Duration: 300ms
Curve: elasticOut
```

## 📱 UI States

### EnhancedAddToCartButton States

#### 1. **Idle State**

```
┌──────────────────────────┐
│  🛒  Thêm vào giỏ hàng   │
└──────────────────────────┘
```

#### 2. **Loading State**

```
┌──────────────────────────┐
│         ⏳              │  (Spinner)
└──────────────────────────┘
```

#### 3. **Success State**

```
┌──────────────────────────┐
│      ✅  Đã thêm         │
└──────────────────────────┘
Background: Green
Duration: 1.5s
```

#### 4. **With Quantity Selector**

```
┌──────────────────────────┐
│   [-]    2    [+]        │
└──────────────────────────┘
         ↓
┌──────────────────────────┐
│  🛒  Thêm vào giỏ (2)    │
└──────────────────────────┘
```

### AddToCartIconButton State

```
   ┌────┐
   │ 🛒 │  ← Idle
   └────┘

   ┌────┐
   │ ⏳ │  ← Loading
   └────┘
```

## 🎨 Customization

### Thay Đổi Colors

#### EnhancedAddToCartButton

```dart
// Trong file enhanced_add_to_cart_button.dart

// Button color
backgroundColor: Colors.blue,  // Thay vì primaryColor

// Success color
backgroundColor: _showSuccess ? Colors.teal : Colors.blue,
```

#### AddToCartIconButton

```dart
// Container decoration
decoration: BoxDecoration(
  color: Colors.orange,  // Thay vì primaryColor
  // ...
),
```

### Custom Animations

#### Tốc độ animation

```dart
_animationController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 300),  // Tăng/giảm tốc độ
);
```

#### Animation curve

```dart
_scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
  CurvedAnimation(
    parent: _animationController,
    curve: Curves.bounceOut,  // Đổi curve
  ),
);
```

### Custom Button Style

```dart
EnhancedAddToCartButton(
  product: product,
  // Wrap trong Container để custom thêm
)

// Hoặc sửa trực tiếp trong _buildAddButton():
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.purple,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),  // Rounded hơn
    ),
    elevation: 4,  // Shadow nhiều hơn
  ),
  // ...
)
```

## 💡 Examples

### Example 1: Product Detail Screen

```dart
class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Column(
        children: [
          // Product info...
          Image.network(product.imageUrl),
          Text(product.name),
          Text('${product.price} ₫'),

          const Spacer(),

          // Enhanced button với quantity selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: EnhancedAddToCartButton(
              product: product,
              showQuantitySelector: true,
              initialQuantity: 1,
              onSuccess: () {
                // Optional: Navigate to cart
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Product Grid Card

```dart
class ProductCard extends StatelessWidget {
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Product image with floating add button
          Stack(
            children: [
              Image.network(
                product.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              // Floating icon button
              Positioned(
                bottom: 8,
                right: 8,
                child: AddToCartIconButton(
                  product: product,
                ),
              ),
            ],
          ),

          // Product info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
                Text('${product.price} ₫'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Example 3: Product List with Regular Button

```dart
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    final product = products[index];

    return ListTile(
      leading: Image.network(product.imageUrl),
      title: Text(product.name),
      subtitle: Text('${product.price} ₫'),

      // Regular enhanced button
      trailing: EnhancedAddToCartButton(
        product: product,
      ),
    );
  },
)
```

## 🔔 Snackbar Messages

### Success Snackbar

```
╔════════════════════════════════╗
║ ✅ Đã thêm vào giỏ hàng        ║
║ Paracetamol 500mg (x2)         ║
║                    [Xem giỏ] →  ║
╚════════════════════════════════╝
```

### Error Snackbar

```
╔════════════════════════════════╗
║ ❌ Sản phẩm không đủ số lượng  ║
╚════════════════════════════════╝
```

## 🔐 Login Dialog

```
╔═══════════════════════════════════╗
║  🛒  Yêu cầu đăng nhập            ║
║                                   ║
║  Bạn cần đăng nhập để thêm sản    ║
║  phẩm vào giỏ hàng                ║
║                                   ║
║        [Để sau]  [Đăng nhập ngay] ║
╚═══════════════════════════════════╝
```

## ⚙️ Integration với CartProvider

Cả hai widget đều tích hợp với `CartProvider`:

```dart
final cartProvider = context.read<CartProvider>();

final success = await cartProvider.addItem(
  customerId: customerId,
  productId: widget.product.id,
  productUnitId: productUnitId,
  quantity: _quantity,
  unitPrice: price,
);
```

**Auto-reload cart sau khi add:**

- CartProvider tự động fetch cart mới
- CartBadge tự động cập nhật số lượng
- Không cần manual refresh

## 🎯 Best Practices

### 1. **Chọn Widget Phù Hợp**

**Dùng EnhancedAddToCartButton khi:**

- Product detail screen
- Cần quantity selector
- Có đủ không gian
- Muốn feedback rõ ràng

**Dùng AddToCartIconButton khi:**

- Product card trong grid/list
- Không gian hạn chế
- Cần UI compact
- Floating button trên image

### 2. **Handle onSuccess**

```dart
EnhancedAddToCartButton(
  product: product,
  onSuccess: () {
    // Reload product list nếu có stock count
    // Hoặc navigate to cart
    // Hoặc update UI
  },
)
```

### 3. **Error Handling**

Cả hai widget đều tự động handle errors:

- Login required → Show login dialog
- No customerId → Show error
- No product units → Show error
- Network error → Show error snackbar

### 4. **Performance**

```dart
// Tránh rebuild không cần thiết
Consumer<CartProvider>(
  builder: (context, cartProvider, child) {
    // Chỉ rebuild khi cart thay đổi
    return child!;
  },
  child: EnhancedAddToCartButton(
    product: product,
  ),
)
```

## 📊 Testing

### Manual Testing Checklist

**EnhancedAddToCartButton:**

- [ ] Nhấn button → Animation scale
- [ ] Loading state → Spinner hiển thị
- [ ] Success state → Checkmark + green background
- [ ] Snackbar xuất hiện với product info
- [ ] Tap "Xem giỏ" → Navigate to cart
- [ ] Quantity selector: +/- buttons hoạt động
- [ ] Quantity giới hạn 1-99
- [ ] Login required → Dialog hiển thị

**AddToCartIconButton:**

- [ ] Nhấn icon → Elastic animation
- [ ] Loading → Spinner trong icon
- [ ] Success → Toast message
- [ ] No login → Show error

## 🚨 Troubleshooting

### Button không hoạt động

**Check:**

1. AuthProvider có isLoggedIn = true?
2. User có customerId?
3. Product có defaultUnit?
4. CartProvider được provide đúng chưa?

### Animation không smooth

**Fix:**

```dart
// Tăng frame rate
import 'package:flutter/scheduler.dart';

timeDilation = 1.0;  // Normal speed
// hoặc
timeDilation = 2.0;  // Slow motion (for debugging)
```

### Snackbar bị overlap

**Fix:**

```dart
ScaffoldMessenger.of(context).clearSnackBars();  // Clear existing
ScaffoldMessenger.of(context).showSnackBar(...);
```

---

**Version**: 2.0.0  
**Created**: 27/11/2025  
**Requires**:

- flutter_secure_storage
- provider
- dio
