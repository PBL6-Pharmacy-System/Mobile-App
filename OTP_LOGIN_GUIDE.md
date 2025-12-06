# 📱 HƯỚNG DẪN ĐĂNG NHẬP BẰNG OTP

## 🎯 Tổng Quan

Chức năng đăng nhập bằng OTP cho phép khách hàng đăng nhập bằng **số điện thoại** hoặc **email** mà không cần mật khẩu.

---

## 🔧 Backend API Integration

### Endpoints Sử Dụng

#### 1. Request OTP

```http
POST /api/auth/otp/request
Content-Type: application/json

{
  "phone": "+84987654321",  // Hoặc
  "email": "user@example.com"
}
```

**Response:**

```json
{
  "success": true,
  "message": "OTP đã được gửi đến email của bạn",
  "data": {
    "email": "user@example.com",
    "expiresIn": 300
  }
}
```

#### 2. Login với OTP

```http
POST /api/auth/customer/login-otp
Content-Type: application/json

{
  "phone": "+84987654321",  // Hoặc
  "email": "user@example.com",
  "otp": "123456"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Đăng nhập thành công",
  "accessToken": "eyJhbGciOiJIUzI1...",
  "refreshToken": "eyJhbGciOiJIUzI1...",
  "user": {
    "id": 1,
    "username": "customer1",
    "email": "user@example.com",
    "role": "CUSTOMER"
  }
}
```

---

## 📱 User Flow

### Luồng Đăng Nhập OTP

```
1. Mở App → Login Screen
2. Toggle sang "Đăng nhập bằng OTP"
3. Nhập số điện thoại hoặc email
   - Ví dụ: 0987654321
   - Hoặc: user@example.com
4. Nhấn "Gửi OTP"
   ⏳ Đang gửi...
   ✅ "Mã OTP đã được gửi!"
5. Navigate → OTP Verification Screen
6. Nhập 6 chữ số OTP từ SMS/Email
   - Auto-submit khi nhập đủ 6 số
7. Verify OTP
   ⏳ Đang xác thực...
   ✅ "Xác thực thành công!"
8. Navigate → Home Screen
```

---

## ✨ Tính Năng

### Login Screen

- ✅ Toggle giữa **Password Mode** và **OTP Mode**
- ✅ Auto-detect input là phone hay email
- ✅ Validation số điện thoại/email
- ✅ Request OTP khi nhấn "Gửi OTP"
- ✅ Navigate sang OTP verification page

### OTP Verification Screen

- ✅ **6 ô nhập OTP** riêng biệt
- ✅ **Auto-focus** sang ô tiếp theo
- ✅ **Auto-submit** khi nhập đủ 6 số
- ✅ **Countdown timer** 60 giây
- ✅ **Resend OTP** khi hết thời gian
- ✅ **Clear fields** khi OTP sai
- ✅ Hiển thị số điện thoại/email đã gửi
- ✅ Loading states
- ✅ Error handling

### Backend Features

- ✅ Hỗ trợ cả **phone** và **email**
- ✅ OTP 6 chữ số random
- ✅ Expire sau **5 phút**
- ✅ Rate limiting (1 phút/request)
- ✅ Max 5 attempts verification
- ✅ Email thật qua Gmail SMTP
- ✅ SMS mock (dev mode)

---

## 🧪 Testing

### Test Case 1: OTP với Email

1. **Start Backend:**

   ```bash
   cd Back-End-Web
   npm start
   ```

2. **Configure Email (Backend):**
   File `.env`:

   ```env
   EMAIL_USER=your-gmail@gmail.com
   EMAIL_APP_PASSWORD=your-app-password
   ```

   > **Lấy App Password:**
   >
   > 1. Google Account → Security
   > 2. Enable 2FA
   > 3. App passwords → Generate

3. **Run App:**

   ```bash
   cd pharmacy_app
   flutter run
   ```

4. **Test Flow:**
   - Mở app → Login
   - Toggle "Đăng nhập bằng OTP"
   - Nhập email: `your-email@gmail.com`
   - Tap "Gửi OTP"
   - Check email inbox
   - Nhập OTP từ email
   - ✅ Login thành công

### Test Case 2: OTP với Phone (Dev Mode)

1. **Backend Console:**

   - Backend sẽ log OTP trong console
   - Tìm dòng: `✅ [DEV MODE] OTP SMS: 123456`

2. **Test Flow:**
   - Nhập số điện thoại: `0987654321`
   - Tap "Gửi OTP"
   - Check backend console để lấy OTP
   - Nhập OTP
   - ✅ Login thành công

### Test Case 3: Resend OTP

1. Gửi OTP lần đầu
2. Đợi countdown hết (60s)
3. Tap "Gửi lại mã OTP"
4. Nhận OTP mới
5. Verify OTP mới

### Test Case 4: Wrong OTP

1. Nhập OTP sai
2. ❌ "Mã OTP không đúng"
3. Fields tự động clear
4. Focus về ô đầu tiên
5. Thử lại

### Test Case 5: Expired OTP

1. Gửi OTP
2. Đợi > 5 phút
3. Nhập OTP cũ
4. ❌ "Mã OTP không hợp lệ hoặc đã hết hạn"
5. Request OTP mới

---

## 🔐 Security Features

### Backend Protection

- ✅ Rate limiting: 1 OTP/phút/user
- ✅ OTP expires sau 5 phút
- ✅ Max 5 lần verify sai → phải request mới
- ✅ OTP code 6 chữ số random
- ✅ Cleanup expired OTPs tự động

### Frontend Validation

- ✅ Validate phone format: `0xxxxxxxxx` hoặc `+84xxxxxxxxx`
- ✅ Validate email format
- ✅ Prevent spam resend (countdown 60s)
- ✅ Auto-clear fields khi sai
- ✅ Token storage secure

---

## 📊 Database Schema

Backend sử dụng table `otp_verifications`:

```sql
CREATE TABLE otp_verifications (
  id INT PRIMARY KEY AUTO_INCREMENT,
  phone VARCHAR(20),
  email VARCHAR(255),
  otp_code VARCHAR(6),
  verified BOOLEAN DEFAULT FALSE,
  attempts INT DEFAULT 0,
  expires_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🎨 UI Components

### Login Page

```dart
// Toggle button
TextButton(
  onPressed: () {
    setState(() {
      _isPasswordMode = !_isPasswordMode;
    });
  },
  child: Text(_isPasswordMode
    ? "Đăng nhập bằng OTP"
    : "Đăng nhập bằng mật khẩu"),
)
```

### OTP Fields

```dart
// 6 TextField widgets in Row
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: List.generate(6, (index) => _buildOtpField(index)),
)
```

### Countdown Timer

```dart
Timer.periodic(const Duration(seconds: 1), (timer) {
  setState(() {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
    } else {
      _canResend = true;
      timer.cancel();
    }
  });
});
```

---

## 🐛 Troubleshooting

### Lỗi: "Không thể gửi OTP"

**Nguyên nhân:** Backend email chưa config

**Giải pháp:**

1. Check `.env` có `EMAIL_USER` và `EMAIL_APP_PASSWORD`
2. Test email với Gmail SMTP
3. Enable 2FA và tạo App Password

### Lỗi: "OTP không hợp lệ"

**Nguyên nhân:**

- OTP đã expire (>5 phút)
- Nhập sai quá 5 lần
- Backend database lỗi

**Giải pháp:**

1. Request OTP mới
2. Check backend logs
3. Verify database connection

### Lỗi: "Rate limit exceeded"

**Nguyên nhân:** Gửi OTP quá nhanh (<1 phút)

**Giải pháp:** Đợi 1 phút rồi thử lại

---

## 📝 Code Files

### Modified Files

- ✅ `lib/services/auth_service.dart`

  - `loginWithOTP({phone, email, otp})`
  - `requestOTP({phone, email})`

- ✅ `lib/provider/auth_provider.dart`

  - `loginWithOTP({phone, email, otp})`
  - `requestOTP({phone, email})`

- ✅ `lib/presentation/authentication/login_page.dart`
  - OTP mode toggle
  - Auto-detect phone/email
  - Navigate to OTP verification

### New Files

- ✅ `lib/presentation/authentication/otp_verification_page.dart`
  - Full OTP UI
  - 6-digit input
  - Countdown timer
  - Resend functionality

---

## 🚀 Next Steps

### Enhancements (Optional)

- [ ] SMS integration thật (Twilio, AWS SNS)
- [ ] Biometric login after first OTP
- [ ] Remember device
- [ ] OTP for password reset
- [ ] Multi-language support

---

## 📞 Support

**Backend API Issues:**

- Check `Back-End-Web/src/modules/auth/otpService.js`
- Check backend console logs

**Frontend Issues:**

- Check Flutter console logs
- Enable Dart DevTools

**Email Not Sending:**

1. Verify Gmail settings
2. Check App Password
3. Test with Postman first

---

**Status:** ✅ Fully Implemented & Tested
**Last Updated:** 2025-11-26
**Backend Compatible:** ✅ Yes
**Production Ready:** ⚠️ Email only (SMS needs real service)
