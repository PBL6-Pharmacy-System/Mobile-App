# 🛒 KẾ HOẠCH TÍCH HỢP APP KHÁCH HÀNG

## 📱 TỔNG QUAN

App Flutter cho khách hàng mua thuốc online, không bao gồm tính năng admin/staff.

---

## ✅ ĐÃ HOÀN THÀNH

### Models (Customer-focused)

- ✅ `user_model.dart` - Thông tin user
- ✅ `auth_response_model.dart` - Response đăng nhập/đăng ký
- ✅ `cart_model.dart` - Giỏ hàng với items, voucher, tổng tiền
- ✅ `order_model.dart` - Đơn hàng với payment, shipping info
- ✅ `address_model.dart` - Địa chỉ giao hàng
- ✅ `voucher_model.dart` - Mã giảm giá
- ✅ `review_model.dart` - Đánh giá sản phẩm
- ✅ `branch_model.dart` - Chi nhánh nhà thuốc

### Services

- ✅ `auth_service.dart` - Đăng nhập, đăng ký, OTP
- ✅ `flash_sale_service.dart` - Flash sales (đã có)
- ✅ `product_service.dart` - Sản phẩm (đã có, cần verify)

### Dependencies

- ✅ `flutter_secure_storage: ^9.2.2` - Lưu token
- ✅ `shared_preferences: ^2.3.5` - Settings
- ✅ `url_launcher: ^6.3.1` - Payment deeplinks

---

## 🔨 CẦN LÀM TIẾP (CHỈ CHO KHÁCH HÀNG)

### 1. Services Layer (APIs)

#### `cart_service.dart`

```dart
Future<CartModel?> getCart(int customerId)
Future<bool> addToCart(int customerId, int productUnitId, int quantity, int? flashsaleId)
Future<bool> updateCartItem(int customerId, int itemId, int quantity)
Future<bool> removeCartItem(int customerId, int itemId)
Future<bool> clearCart(int customerId)
Future<Map<String, dynamic>> previewVoucher(int customerId, String voucherCode)
```

#### `order_service.dart`

```dart
Future<List<OrderModel>> getMyOrders(int customerId, {String? status})
Future<OrderModel?> getOrderDetail(int orderId)
Future<Map<String, dynamic>> checkout(CheckoutData data)
Future<bool> cancelOrder(int orderId, String? reason)
```

#### `review_service.dart`

```dart
Future<List<ReviewModel>> getProductReviews(int productId, {int? rating})
Future<RatingStatsModel?> getProductRatingStats(int productId)
Future<bool> createReview(int productId, int orderId, int rating, String? comment, List<String> images)
Future<bool> updateReview(int reviewId, int rating, String? comment, List<String> images)
```

#### `voucher_service.dart`

```dart
Future<List<VoucherModel>> getAvailableVouchers()
Future<VoucherModel?> getVoucherByCode(String code)
```

#### `address_service.dart`

```dart
Future<List<AddressModel>> getMyAddresses(int customerId)
Future<AddressModel?> getDefaultAddress(int customerId)
Future<bool> createAddress(int customerId, AddressData data)
Future<bool> updateAddress(int addressId, AddressData data)
Future<bool> deleteAddress(int addressId)
Future<bool> setDefaultAddress(int addressId, int customerId)
```

#### `payment_service.dart`

```dart
Future<String?> createVNPayPaymentUrl(int orderId, double amount, String orderInfo)
Future<String?> createMomoPaymentUrl(int orderId, double amount, String orderInfo)
// Handle callbacks trong main.dart
```

#### `branch_service.dart`

```dart
Future<List<BranchModel>> getAllBranches({String? city, String? district})
Future<BranchModel?> getBranchDetail(int branchId)
```

#### `category_service.dart`

```dart
Future<List<CategoryModel>> getAllCategories()
Future<List<ProductModel>> getProductsByCategory(int categoryId, {int? page, int? limit})
```

### 2. Providers (State Management)

#### `auth_provider.dart`

```dart
- UserModel? currentUser
- bool isLoggedIn
- bool isLoading
- String? error

+ login(username, password)
+ loginWithOTP(phone, otp)
+ register(userData)
+ logout()
+ loadCurrentUser()
```

#### `cart_provider.dart`

```dart
- CartModel? cart
- bool isLoading
- String? error

+ fetchCart()
+ addItem(productUnitId, quantity, flashsaleId?)
+ updateItemQuantity(itemId, quantity)
+ removeItem(itemId)
+ clearCart()
+ applyVoucher(code)
+ removeVoucher()

Getters:
+ int itemCount
+ double subtotal
+ double voucherDiscount
+ double total
```

#### `order_provider.dart`

```dart
- List<OrderModel> orders
- OrderModel? selectedOrder
- bool isLoading
- String? error

+ fetchMyOrders({status?})
+ fetchOrderDetail(orderId)
+ cancelOrder(orderId, reason?)
+ refreshOrders()

Filters:
+ getPendingOrders()
+ getProcessingOrders()
+ getShippingOrders()
+ getCompletedOrders()
```

#### `product_provider.dart`

```dart
- List<ProductModel> products
- List<ProductModel> bestSellers
- List<CategoryModel> categories
- bool isLoading
- String? error

+ fetchProducts({categoryId?, search?, page?})
+ fetchBestSellers()
+ fetchCategories()
+ searchProducts(keyword)
```

### 3. UI Screens (Customer Journey)

#### **Authentication**

- 🔨 `login_page.dart` - Login form + OTP option
- 🔨 `register_page.dart` - Register form
- 🔨 `otp_verification_page.dart` - OTP input screen

#### **Home**

- 🔨 `home_page.dart` - Banner, Categories, Flash Sale, Best Sellers
  - Integrate FlashSaleSection (✅ đã có)
  - Add search bar
  - HomeCategory widget với real API
  - OutstandingProduct widget với bestSellers API

#### **Products**

- 🔨 `category_page.dart` - Danh mục sản phẩm (đã có base)
- 🔨 `product_list_page.dart` - Lọc, sort, pagination
- 🔨 `product_detail_page.dart` - Full info, reviews, add to cart
- 🔨 `search_page.dart` - Tìm kiếm sản phẩm

#### **Shopping Cart**

- 🔨 `cart_page.dart` - Items, voucher input, checkout button
- 🔨 `voucher_selection_page.dart` - Danh sách vouchers

#### **Checkout**

- 🔨 `checkout_page.dart` - Address, payment method, review order
- 🔨 `address_selection_page.dart` - Chọn địa chỉ giao hàng
- 🔨 `address_form_page.dart` - Thêm/sửa địa chỉ
- 🔨 `payment_selection_page.dart` - COD/VNPay/Momo
- 🔨 `order_success_page.dart` - Thông báo đặt hàng thành công
- 🔨 `payment_webview_page.dart` - WebView cho VNPay/Momo

#### **Orders**

- 🔨 `order_page.dart` - Tabs theo status (đã có base)
- 🔨 `order_detail_page.dart` - Chi tiết đơn hàng, tracking

#### **Reviews**

- 🔨 `review_form_page.dart` - Viết đánh giá
- 🔨 `review_list_page.dart` - Reviews của sản phẩm

#### **Account**

- 🔨 `account_page.dart` - Profile, settings
- 🔨 `profile_edit_page.dart` - Sửa thông tin cá nhân
- 🔨 `change_password_page.dart` - Đổi mật khẩu
- 🔨 `address_management_page.dart` - Quản lý địa chỉ
- 🔨 `notification_page.dart` - Thông báo (nếu có)

### 4. Common Widgets

- `product_card.dart` - Card hiển thị sản phẩm
- `cart_item_card.dart` - Item trong giỏ hàng
- `order_card.dart` - Card đơn hàng
- `review_card.dart` - Card đánh giá
- `voucher_card.dart` - Card voucher
- `address_card.dart` - Card địa chỉ
- `loading_indicator.dart` - Loading state
- `empty_state.dart` - Empty state
- `error_widget.dart` - Error state

### 5. Payment Integration

- Configure deeplinks trong `AndroidManifest.xml` và `Info.plist`
- Handle callback URLs từ VNPay/Momo
- Update order status sau khi thanh toán

### 6. Testing Flow

1. ✅ Register account
2. ✅ Login
3. ✅ Browse products
4. ✅ Add to cart
5. ✅ Apply voucher
6. ✅ Checkout với address
7. ✅ Select payment method
8. ✅ Complete payment
9. ✅ View order detail
10. ✅ Write review

---

## 🎯 THỨ TỰ THỰC HIỆN ĐỀ XUẤT

### Phase 1: Core Shopping (Tuần 1)

1. CartService + CartProvider
2. Update Cart Page UI
3. ProductProvider + Home Page widgets
4. Product Detail Page với Add to Cart

### Phase 2: Checkout Flow (Tuần 2)

5. AddressService + Address CRUD
6. OrderService + Checkout
7. Checkout Page với address/payment selection
8. Order Success Page

### Phase 3: Orders & Auth (Tuần 3)

9. OrderProvider + Order Pages
10. AuthProvider + Login/Register UI
11. Account Pages

### Phase 4: Polish (Tuần 4)

12. ReviewService + Review UI
13. VoucherService + Voucher UI
14. Payment Gateway Integration
15. Testing & Bug Fixes

---

## ⚠️ LƯU Ý QUAN TRỌNG

- ❌ KHÔNG làm tính năng Admin Dashboard
- ❌ KHÔNG làm tính năng Staff Management
- ❌ KHÔNG làm tính năng Inventory Management
- ❌ KHÔNG làm tính năng Statistics cho admin
- ✅ CHỈ tập trung vào Customer Experience
- ✅ API endpoints đã có sẵn từ backend
- ✅ Backend đã handle authorization, Flutter chỉ cần gửi token

---

## 📝 API ENDPOINTS DÙNG CHO CUSTOMER

### Auth

- POST `/api/auth/register`
- POST `/api/auth/login`
- POST `/api/auth/customer/login-otp`
- POST `/api/auth/otp/request`
- GET `/api/auth/me`
- POST `/api/auth/logout`

### Products

- GET `/api/products` (search, filter, pagination)
- GET `/api/products/:id`
- GET `/api/products/search?q=keyword`
- GET `/api/products/best-sellers`
- GET `/api/categories`

### Cart

- GET `/api/cart/:customerId`
- POST `/api/cart/:customerId/add`
- PUT `/api/cart/:customerId/items/:itemId`
- DELETE `/api/cart/:customerId/items/:itemId`
- POST `/api/cart/:customerId/voucher/preview`

### Orders

- GET `/api/customers/:customerId/orders`
- GET `/api/orders/:id`
- POST `/api/cart/checkout`
- POST `/api/orders/:id/cancel`

### Reviews

- GET `/api/products/:productId/reviews`
- GET `/api/products/:productId/rating-stats`
- POST `/api/reviews`
- PUT `/api/reviews/:id`

### Addresses

- GET `/api/customers/:customerId/shipping-addresses`
- GET `/api/customers/:customerId/shipping-addresses/default`
- POST `/api/customers/:customerId/shipping-addresses`
- PUT `/api/shipping-addresses/:id`
- DELETE `/api/shipping-addresses/:id`
- PUT `/api/shipping-addresses/:id/set-default`

### Vouchers

- GET `/api/vouchers`

### Payments

- POST `/api/payments/vnpay/create-payment-url`
- POST `/api/payments/momo/create-payment`
- GET `/api/payments/vnpay/callback`
- GET `/api/payments/momo/callback`

### Branches

- GET `/api/branches?city=&district=`

### Flash Sales

- GET `/api/flashsales/active` (✅ đã implement)
