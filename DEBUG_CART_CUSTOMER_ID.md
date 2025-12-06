# Hướng Dẫn Debug Lỗi "Không Tìm Thấy Khách Hàng"

## 🐛 Vấn Đề

Khi nhấn nút "Thêm giỏ hàng", xuất hiện lỗi: **"Không tìm thấy thông tin khách hàng"**

## 🔍 Nguyên Nhân

`customer_id` không được lưu hoặc parse đúng từ backend response khi đăng nhập.

## ✅ Đã Sửa

### 1. **Parse `customer_id` từ `customers` relation**

Backend trả về:

```json
{
  "user": {
    "id": 123,
    "username": "user@example.com",
    "customers": {
      "id": 456 // <-- customer_id ở đây
    }
  }
}
```

Flutter giờ parse từ cả 2 nguồn:

- `json['customer_id']` (trực tiếp)
- `json['customers']['id']` (từ relation)

### 2. **Thêm Debug Logs**

Các logs sẽ giúp xác định vấn đề:

```dart
// Khi login
✅ Saved customer_id: 456
⚠️ No customer_id in user data

// Khi load user
📦 Loading user: id=123, role=CUSTOMER, customerId=456
⚠️ WARNING: Customer user but no customerId!

// Khi thêm giỏ hàng
📦 Current user: user@example.com, customerId: 456
❌ No customerId found for user
```

### 3. **Giảm kích thước nút**

Nút "Thêm giỏ hàng" đã được tối ưu:

- Padding: 24x12 → 12x8
- Icon: 20 → 16
- Font: 15 → 13
- Text: "Thêm vào giỏ" → "Thêm giỏ"
- Thêm `Flexible` để text không tràn

## 🛠️ Cách Debug

### Bước 1: In thông tin user

```dart
import 'package:pharmacy_app/utils/auth_debug.dart';

// Trong code của bạn
await AuthDebug.printAllUserData();
```

Output mong muốn:

```
🔍 ===== AUTH DEBUG START =====
User ID: 123
Username: user@example.com
Email: user@example.com
Full Name: null
Role: CUSTOMER
Customer ID: 456  ✅ PHẢI CÓ GIÁ TRỊ
Staff ID: null
Admin ID: null
🔍 ===== AUTH DEBUG END =====
```

### Bước 2: Kiểm tra backend response

Trong console khi đăng nhập OTP, xem:

```
📦 [AuthService] Login response: {...}
✅ Saved customer_id: 456  // PHẢI THẤY DÒNG NÀY
```

Nếu thấy `⚠️ No customer_id in user data`, nghĩa là backend không trả về đúng.

### Bước 3: Test lại từ đầu

1. **Đăng xuất**

```dart
await AuthProvider().logout();
await AuthDebug.clearAllAuthData();
```

2. **Đăng nhập lại** bằng OTP

3. **Kiểm tra logs** trong console

4. **Thử thêm giỏ hàng**

## 📋 Checklist Troubleshooting

- [ ] User đã đăng nhập bằng OTP (không phải username/password)
- [ ] Backend đang chạy và trả về đúng data
- [ ] Console có log `✅ Saved customer_id: xxx`
- [ ] `AuthDebug.printAllUserData()` hiển thị customer_id
- [ ] User role là "CUSTOMER"
- [ ] Token còn hạn (chưa bị expire)

## 🔧 Nếu Vẫn Lỗi

### Kiểm tra backend response

Thêm log trong `auth_service.dart`:

```dart
// Trong loginWithOTP()
print('📦 Full response: ${response.data}');
print('📦 User data: ${response.data['data']['user']}');
```

Xem backend có trả về:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": 123,
      "customers": {
        "id": 456 // <-- PHẢI CÓ
      }
    }
  }
}
```

### Kiểm tra JWT token

Backend có thể lưu `customer_id` trong token. Decode token để xem:

```dart
// Thêm package: jwt_decoder
import 'package:jwt_decoder/jwt_decoder.dart';

final token = await AuthService().getAccessToken();
if (token != null) {
  final decoded = JwtDecoder.decode(token);
  print('Token payload: $decoded');
  // Xem có customer_id không
}
```

## 💡 Tips

1. **Luôn test với fresh login**: Đăng xuất hoàn toàn rồi đăng nhập lại
2. **Xóa storage**: `await AuthDebug.clearAllAuthData()`
3. **Restart app**: Hot reload không đủ, cần restart
4. **Check network**: Đảm bảo backend running và có thể access

## 🎯 Expected Behavior

Sau khi sửa:

1. Đăng nhập OTP → Lưu `customer_id` thành công
2. Thêm sản phẩm vào giỏ → Gọi API với `customerId` hợp lệ
3. Hiện thông báo: "Đã thêm [tên SP] vào giỏ hàng" ✅

## 📞 Nếu Cần Hỗ Trợ

Cung cấp các thông tin sau:

1. Output của `AuthDebug.printAllUserData()`
2. Console logs khi đăng nhập
3. Console logs khi thêm giỏ hàng
4. Backend response (nếu có)

---

**Last Updated**: 27/11/2025
