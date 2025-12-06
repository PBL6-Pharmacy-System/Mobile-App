# ⚡ QUICK START - Test Ngay Phase 1

## 🚀 3 Bước Đơn Giản

### 1️⃣ Start Backend

```powershell
cd d:\AppMobile\Backend-app\Back-End-Web
npm start
```

Đợi thấy: `Server running on port 3000` ✅

---

### 2️⃣ Cấu hình IP

Mở: `lib/configs/api_config.dart`

**Nếu dùng Android Emulator:**

```dart
static const String _host = '10.0.2.2';
```

**Nếu dùng Real Device:**

1. Mở CMD → gõ `ipconfig`
2. Copy IPv4 Address (vd: `192.168.1.100`)
3. Paste vào:

```dart
static const String _host = '192.168.1.100'; // 👈 IP máy bạn
```

---

### 3️⃣ Run App

```powershell
cd d:\AppMobile\pharmacy_app
flutter run
```

---

## 🎯 Test Flow

### Login

1. Chọn "Đăng nhập bằng mật khẩu"
2. Nhập username/email + password từ database backend
3. Tap "Đăng nhập"
4. ✅ Thấy Home Screen

### Home

1. Cuộn xuống "Sản phẩm nổi bật"
2. ✅ Thấy products load từ backend
3. ✅ Flash Sales hiển thị

### Cart

1. Tap icon "Giỏ hàng"
2. ✅ Thấy "Giỏ hàng trống" (normal - chưa add items)

---

## 🐛 Lỗi?

**Connection refused:**
→ Check backend đang chạy: http://localhost:3000

**Login failed:**
→ Kiểm tra username/password trong database

**Products không load:**
→ Test API: http://localhost:3000/api/products

---

## 📁 Files Quan Trọng

- `PHASE1_SUMMARY.md` - Tổng quan chi tiết
- `TESTING_GUIDE.md` - Hướng dẫn test đầy đủ
- `test_backend.ps1` - Script kiểm tra backend

---

## ✨ Đã Implement

✅ Login với backend  
✅ Load products từ API  
✅ Cart state management  
✅ Flash sales hoạt động  
✅ State management với Provider

## 🔜 Tiếp Theo (Phase 2)

- Product detail page
- Add to cart
- Checkout flow
- Address management

---

**Ready? → `flutter run` 🚀**
