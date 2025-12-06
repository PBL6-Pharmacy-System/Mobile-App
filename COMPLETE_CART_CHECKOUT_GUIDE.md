# 🛒 Hướng Dẫn Hoàn Chỉnh: Thêm Sản Phẩm Vào Giỏ Hàng & Thanh Toán

## ✅ Đã Hoàn Thành

### 1. **Backend API Updates**

- ✅ Thêm `productunits: true` vào tất cả product queries
- ✅ `getAllProducts()` - Include productunits
- ✅ `getProductById()` - Include productunits
- ✅ `getProductsByCategory()` - Include productunits
- ✅ `getProductsBySubcategory()` - Include productunits
- ✅ `searchProducts()` - Include productunits

### 2. **Flutter Models & Services**

- ✅ `ProductModel` - Parse productunits array
- ✅ `ProductUnit` class với đầy đủ fields
- ✅ `defaultUnit` getter - Tìm base unit
- ✅ `CartService` - API integration
- ✅ `CartProvider` - State management

### 3. **UI Components**

- ✅ `AddToCartButton` - Basic button với loading state
- ✅ `EnhancedAddToCartButton` - Advanced với animations
- ✅ `AddToCartIconButton` - Compact icon button
- ✅ `CartScreen` - Màn hình giỏ hàng đầy đủ
- ✅ `CartBadge` - Badge số lượng items

## 🚀 Luồng Hoạt Động

### **Bước 1: Thêm Sản Phẩm Vào Giỏ**

```dart
// User nhấn nút "Thêm giỏ hàng"
AddToCartButton(
  product: product,
  onSuccess: () {
    // Optional: Navigate to cart or show message
  },
)
```

**Xử lý:**

1. Check user đã login chưa
2. Lấy `customerId` từ AuthProvider
3. Lấy `defaultUnit` từ product (conversion_factor = 1)
4. Gọi API: `POST /api/cart/:customerId/add`
5. Backend tạo/update cart trong `orders` table (status = 'CART')
6. Backend thêm item vào `orderitems` table
7. Show success snackbar
8. CartProvider auto reload cart
9. CartBadge tự động update số lượng

### **Bước 2: Xem Giỏ Hàng**

```dart
// Navigate to cart screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const CartScreen()),
);
```

**Hiển thị:**

- Danh sách sản phẩm với ảnh, tên, giá
- Quantity controls (+/-)
- Delete button
- Tổng tiền tự động
- Voucher discount (nếu có)

### **Bước 3: Cập Nhật Giỏ Hàng**

```dart
// User thay đổi số lượng
await cartProvider.updateItemQuantity(
  customerId: customerId,
  itemId: item.id,
  quantity: newQuantity,
);

// Hoặc xóa sản phẩm
await cartProvider.removeItem(
  customerId: customerId,
  itemId: item.id,
);
```

**Backend xử lý:**

- Check stock availability
- Update `orderitems.quantity` và `subtotal`
- Recalculate `orders.total_amount`
- Return updated cart

### **Bước 4: Thanh Toán**

```dart
// TODO: Implement checkout
ElevatedButton(
  onPressed: () async {
    // 1. Validate cart
    final validation = await cartService.validateCartBeforeCheckout(customerId);

    // 2. Select shipping address
    // 3. Select payment method
    // 4. Apply voucher (if any)

    // 5. Create order
    final order = await orderService.checkout(cartId);

    // 6. Process payment
    // 7. Navigate to order success screen
  },
  child: Text('Tiến hành đặt hàng'),
)
```

## 📊 Database Schema

### **orders** (Cũng dùng làm cart)

```sql
id              SERIAL PRIMARY KEY
customer_id     INT (FK to customers)
status          VARCHAR  -- 'CART', 'PENDING', 'PROCESSING', ...
order_date      TIMESTAMP
total_amount    DECIMAL
final_amount    DECIMAL
discount_amount DECIMAL
voucher_id      INT (nullable)
```

### **orderitems** (Cart items)

```sql
id              SERIAL PRIMARY KEY
order_id        INT (FK to orders)
product_id      INT (FK to products)
unit_id         INT (FK to productunits)
quantity        INT
price           DECIMAL  -- Unit price
subtotal        DECIMAL  -- quantity * price
```

### **productunits** (Product units/SKUs)

```sql
id                  SERIAL PRIMARY KEY
product_id          INT (FK to products)
unit_id             INT (FK to unittype)
unit_name           VARCHAR  -- "Hộp", "Viên", "Vỉ"
conversion_factor   INT      -- 1 = base unit
price               DECIMAL
barcode             VARCHAR
```

## 🔄 API Endpoints

### **Cart Management**

#### **1. Get Cart**

```http
GET /api/cart/:customerId
Authorization: Bearer <token>
```

**Response:**

```json
{
  "success": true,
  "data": {
    "id": 63,
    "customer_id": 35,
    "status": "CART",
    "total_amount": "150000",
    "final_amount": "150000",
    "orderitems": [
      {
        "id": 73,
        "product_id": 2,
        "unit_id": 3,
        "quantity": 3,
        "price": "50000",
        "subtotal": "150000",
        "products": {
          "id": 2,
          "name": "Paracetamol 500mg",
          "image_url": "..."
        },
        "productunits": {
          "id": 3,
          "unit_name": "Hộp",
          "conversion_factor": 1,
          "price": "50000"
        }
      }
    ]
  }
}
```

#### **2. Add to Cart**

```http
POST /api/cart/:customerId/add
Authorization: Bearer <token>
Content-Type: application/json

{
  "productId": 2,
  "productUnitId": 3,
  "quantity": 1,
  "unitPrice": 50000  // Optional, will use current price if not provided
}
```

**Response:**

```json
{
  "success": true,
  "message": "Đã thêm sản phẩm vào giỏ hàng",
  "data": {
    "id": 73,
    "order_id": 63,
    "product_id": 2,
    "unit_id": 3,
    "quantity": 3,
    "price": "50000",
    "subtotal": "150000"
  }
}
```

#### **3. Update Quantity**

```http
PUT /api/cart/:customerId/items/:itemId
Authorization: Bearer <token>
Content-Type: application/json

{
  "quantity": 5
}
```

#### **4. Remove Item**

```http
DELETE /api/cart/:customerId/items/:itemId
Authorization: Bearer <token>
```

#### **5. Clear Cart**

```http
DELETE /api/cart/:customerId/clear
Authorization: Bearer <token>
```

#### **6. Get Cart Summary**

```http
GET /api/cart/:customerId/summary
Authorization: Bearer <token>
```

**Response:**

```json
{
  "success": true,
  "data": {
    "itemCount": 3,
    "subtotal": 150000,
    "discount": 0,
    "total": 150000
  }
}
```

## 🎨 UI Examples

### **1. Product Card với AddToCartIconButton**

```dart
class ProductCard extends StatelessWidget {
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Stack(
            children: [
              // Product image
              Image.network(
                product.images.isNotEmpty ? product.images[0] : '',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              // Floating add to cart button
              Positioned(
                bottom: 8,
                right: 8,
                child: AddToCartIconButton(
                  product: product,
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
                SizedBox(height: 4),
                Text(
                  '${product.price} ₫',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### **2. Product Detail với EnhancedAddToCartButton**

```dart
class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          // Cart badge
          CartBadge(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Product images carousel
          CarouselSlider(
            items: product.images.map((url) {
              return Image.network(url, fit: BoxFit.cover);
            }).toList(),
          ),

          // Product info
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${product.price} ₫',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(product.description),
                  SizedBox(height: 16),
                  Text('Cách dùng:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(product.usage),
                  // More info...
                ],
              ),
            ),
          ),

          // Add to cart button at bottom
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: EnhancedAddToCartButton(
                product: product,
                showQuantitySelector: true,
                initialQuantity: 1,
                onSuccess: () {
                  // Optional: Show additional feedback or navigate
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### **3. HomePage với CartBadge**

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhà thuốc'),
        actions: [
          // Cart badge with item count
          CartBadge(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartScreen()),
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: // Your home content
    );
  }
}
```

## 🔍 Debugging

### **Check if productunits are parsed**

```dart
// Trong ProductModel.fromJson()
if (json["productunits"] != null) {
  units = List<ProductUnit>.from(
    json["productunits"].map((x) => ProductUnit.fromJson(x)),
  );
  print('✅ Parsed ${units.length} product units for ${json["name"]}');
} else {
  print('⚠️ No productunits in response for ${json["name"]}');
}
```

**Console output khi đúng:**

```
✅ Parsed 3 product units for Paracetamol 500mg
```

**Console output khi lỗi:**

```
⚠️ No productunits in response for Paracetamol 500mg
❌ No product units available
```

### **Check backend response**

```bash
# PowerShell
Invoke-RestMethod -Uri 'http://localhost:3000/api/products/2' -Method Get | ConvertTo-Json -Depth 5
```

**Phải có `productunits` array:**

```json
{
  "id": 2,
  "name": "Paracetamol 500mg",
  "productunits": [
    {
      "id": 3,
      "product_id": 2,
      "unit_id": 1,
      "unit_name": "Hộp",
      "conversion_factor": 1,
      "price": "50000"
    },
    {
      "id": 4,
      "product_id": 2,
      "unit_id": 2,
      "unit_name": "Viên",
      "conversion_factor": 20,
      "price": "2500"
    }
  ]
}
```

### **Test Add to Cart**

```dart
// Trong AddToCartButton
print('📦 Adding to cart:');
print('  productId: ${widget.product.id}');
print('  productUnitId: $productUnitId');
print('  customerId: $customerId');
print('  quantity: ${widget.quantity}');
print('  price: $price');
```

**Expected console:**

```
📦 Current user: tronghi20.04@gmail.com, customerId: 35
✅ Parsed 3 product units for Paracetamol 500mg
📦 Adding to cart:
  productId: 2
  productUnitId: 3
  customerId: 35
  quantity: 1
  price: 50000.0
✅ [CartService] Added to cart successfully
```

## ⚠️ Common Issues

### **1. "No product units available"**

**Nguyên nhân:** Backend không include `productunits` trong response

**Fix:** Thêm `productunits: true` vào tất cả product queries:

```javascript
include: {
  categories: true,
  suppliers: true,
  unittype: true,
  productunits: true,  // ← Thêm dòng này
  branchinventory: {
    select: { stock: true }
  }
}
```

### **2. "Đơn vị sản phẩm không tồn tại"**

**Nguyên nhân:** Đang gửi `baseUnitId` thay vì `productUnitId`

**Fix:** Dùng `defaultUnit.id`:

```dart
final defaultUnit = widget.product.defaultUnit;
final productUnitId = widget.selectedUnitId ?? defaultUnit.id;
```

### **3. "Không tìm thấy khách hàng"**

**Nguyên nhân:** `customerId` là null

**Fix:** Check `UserModel.fromJson()` parse đúng `customer_id`:

```dart
customerId: json['customers'] != null
  ? json['customers']['id']
  : json['customer_id'],
```

### **4. Cart không reload sau khi add**

**Fix:** Đảm bảo gọi `fetchCart()` sau khi add thành công:

```dart
if (success) {
  await fetchCart(customerId);
}
```

## 📝 Checklist Triển Khai

### **Backend**

- [x] Add `productunits: true` to all product queries
- [x] Cart API endpoints working
- [x] Stock validation
- [x] Price validation
- [ ] Checkout API (TODO)
- [ ] Payment integration (TODO)

### **Flutter**

- [x] ProductModel parse productunits
- [x] ProductUnit model
- [x] defaultUnit getter
- [x] CartService with all CRUD methods
- [x] CartProvider state management
- [x] AddToCartButton components
- [x] CartScreen UI
- [x] CartBadge widget
- [ ] CheckoutScreen (TODO)
- [ ] Payment UI (TODO)
- [ ] Order history (TODO)

### **Testing**

- [x] Add product to cart
- [x] Update quantity
- [x] Remove item
- [x] Clear cart
- [x] CartBadge updates
- [ ] Checkout flow (TODO)
- [ ] Payment processing (TODO)

## 🎯 Next Steps

1. **Implement Checkout Screen**

   - Shipping address selection
   - Payment method selection
   - Order summary
   - Voucher input

2. **Payment Integration**

   - VNPay
   - MoMo
   - ZaloPay
   - COD

3. **Order Tracking**

   - Order history screen
   - Order detail screen
   - Order status tracking
   - Delivery tracking

4. **Notifications**
   - Order confirmation
   - Payment success/failed
   - Delivery updates
   - Promotion notifications

---

**Version**: 3.0.0  
**Updated**: 27/11/2025  
**Status**: Cart ✅ Complete | Checkout 🚧 In Progress
