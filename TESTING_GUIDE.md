# 🚀 HƯỚNG DẪN TEST APP SAU KHI TRIỂN KHAI PHASE 1

## ✅ ĐÃ TRIỂN KHAI

### 1. **State Management Providers**

- ✅ `AuthProvider` - Quản lý đăng nhập, đăng ký, user state
- ✅ `ProductProvider` - Load sản phẩm, best sellers từ backend
- ✅ `CartProvider` - Quản lý giỏ hàng (add, update, remove items)
- ✅ `FlashSaleProvider` - Đã có sẵn
- ✅ Setup `MultiProvider` trong `main.dart`

### 2. **Updated UI Components**

- ✅ `LoginPage` - Kết nối với AuthProvider, hỗ trợ login bằng password
- ✅ `OutstandingProduct` widget - Load best sellers từ ProductProvider
- ✅ `CartPage` - Hiển thị giỏ hàng từ CartProvider với tính toán tổng tiền

---

## 🧪 CÁC BƯỚC TEST

### Bước 1: Khởi động Backend

```bash
cd d:\AppMobile\Backend-app\Back-End-Web
npm start
```

Backend sẽ chạy tại: `http://localhost:3000`

### Bước 2: Kiểm tra API Config

Mở file: `lib/configs/api_config.dart`

```dart
static const String _host = '192.168.10.136'; // 👈 ĐỔI THÀNH IP MÁY BẠN
```

**Cách lấy IP máy:**

- Windows: Mở CMD → gõ `ipconfig` → tìm IPv4 Address
- Hoặc dùng: `10.0.2.2` (cho Android Emulator)
- Hoặc dùng: `localhost` (cho iOS Simulator)

### Bước 3: Chạy Flutter App

```bash
cd d:\AppMobile\pharmacy_app
flutter run
```

---

## 🎯 TEST CASES

### Test 1: Login với Backend

1. Mở app → Thấy màn hình Login
2. Chọn "Đăng nhập bằng mật khẩu"
3. Nhập:
   - **Username/Email:** (tài khoản có sẵn trong DB backend)
   - **Password:** (mật khẩu tương ứng)
4. Nhấn "Đăng nhập"
5. **Kỳ vọng:**
   - ✅ Loading indicator hiện ra
   - ✅ Thông báo "Đăng nhập thành công!"
   - ✅ Chuyển sang màn hình Home

### Test 2: Home Page Load Products

1. Sau khi đăng nhập thành công
2. Ở Home Page, cuộn xuống phần "Sản phẩm nổi bật"
3. **Kỳ vọng:**
   - ✅ Loading indicator xuất hiện
   - ✅ Hiển thị danh sách sản phẩm từ backend
   - ✅ Thông tin sản phẩm: tên, giá, hình ảnh

### Test 3: Flash Sales (đã có)

1. Ở Home Page, phần "Flash Sale"
2. **Kỳ vọng:**
   - ✅ Hiển thị flash sales đang active
   - ✅ Countdown timer hoạt động

### Test 4: Cart Page (chưa có data)

1. Tap vào icon "Giỏ hàng" ở bottom navigation
2. **Kỳ vọng:**
   - ✅ Hiển thị "Giỏ hàng trống" (vì chưa add items)
   - ✅ Badge hiển thị số lượng items = 0

---

## 🐛 XỬ LÝ LỖI THƯỜNG GẶP

### Lỗi 1: Connection refused / Network error

**Nguyên nhân:** Backend chưa chạy hoặc IP sai
**Giải pháp:**

1. Kiểm tra backend: `http://localhost:3000/api/products`
2. Đổi IP trong `api_config.dart` đúng với máy bạn
3. Tắt firewall nếu dùng real device

### Lỗi 2: Login failed - 401 Unauthorized

**Nguyên nhân:** Tài khoản không tồn tại trong DB
**Giải pháp:**

1. Tạo tài khoản mới qua backend hoặc database
2. Hoặc dùng tài khoản có sẵn (kiểm tra database)

### Lỗi 3: Products không hiển thị

**Nguyên nhân:** API response format không đúng
**Giải pháp:**

1. Kiểm tra console logs: `📦 [ProductService] ...`
2. Verify API endpoint: `GET /api/products`
3. Kiểm tra ProductModel parsing

### Lỗi 4: Compile errors

**Giải pháp:**

```bash
flutter clean
flutter pub get
flutter run
```

---

## 📝 NHỮNG GÌ CÒN THIẾU (PHASE 2, 3, 4)

❌ **Chưa có:**

- Add to cart functionality (product detail page)
- Order checkout flow
- Address management
- Payment integration
- Review system
- Register screen với backend
- OTP login
- Product search
- Category filtering

✅ **Đã có foundation:**

- Auth flow hoàn chỉnh
- State management setup
- Service layer structure
- UI components base

---

## 🔄 TIẾP THEO - PHASE 2 (Checkout Flow)

Khi Phase 1 test thành công, chúng ta sẽ triển khai:

1. Address Service + Address CRUD
2. Order Service + Checkout
3. Checkout Page với address/payment selection
4. Order Success Page

---

## 📞 DEBUG TIPS

**Xem logs trong VSCode:**

- Mở Debug Console
- Tìm các dòng:
  - `📦 [CartService] ...`
  - `✅ [AuthService] ...`
  - `❌ [ProductProvider] ...`

**Test API trực tiếp:**

```bash
# Test products API
curl http://192.168.10.136:3000/api/products

# Test login API
curl -X POST http://192.168.10.136:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'
```

**Flutter DevTools:**

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 🎉 EXPECTED RESULTS

Sau khi test thành công Phase 1:

- ✅ Đăng nhập thành công với backend
- ✅ Home page hiển thị sản phẩm thực
- ✅ Flash sales hoạt động (đã có)
- ✅ Cart page có state management (chờ add items)
- ✅ Bottom navigation hoạt động mượt

**Bước tiếp theo:** Implement product detail page để có thể add to cart!
