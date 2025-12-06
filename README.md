# 🏥 Pharmacy App - Customer Mobile Application

A Flutter mobile application for customers to purchase medicines online, integrated with a Node.js backend.

## 📱 Overview

This is a **customer-only** mobile app that allows users to:

- Browse and search for medicines
- View flash sales and promotions
- Add products to cart
- Place orders with multiple payment methods
- Track order status
- Write product reviews

**Note:** This app does NOT include admin/staff features.

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (>=3.8.1)
- Backend server running on `http://localhost:3000`
- Android Emulator / iOS Simulator / Real Device

### Start Backend

```bash
cd d:\AppMobile\Backend-app\Back-End-Web
npm start
```

### Configure API

Edit `lib/configs/api_config.dart`:

```dart
static const String _host = '10.0.2.2'; // Android Emulator
// OR
static const String _host = 'YOUR_IP_ADDRESS'; // Real Device
```

### Run App

```bash
flutter pub get
flutter run
```

**📖 Detailed guide:** See [QUICKSTART.md](QUICKSTART.md)

---

## ✅ Phase 1 - Core Shopping (COMPLETED)

### Implemented Features

- ✅ Authentication (Login/Register with backend)
- ✅ Product listing from API
- ✅ Best sellers section
- ✅ Flash sales display
- ✅ Cart state management
- ✅ Reactive UI with Provider

### State Management

- `AuthProvider` - User authentication
- `ProductProvider` - Products & categories
- `CartProvider` - Shopping cart
- `FlashSaleProvider` - Flash sales

### API Integration

| Endpoint                     | Status     |
| ---------------------------- | ---------- |
| `POST /api/auth/login`       | ✅ Working |
| `GET /api/products`          | ✅ Working |
| `GET /api/cart/:customerId`  | ✅ Working |
| `GET /api/flashsales/active` | ✅ Working |

**📊 Full details:** See [PHASE1_SUMMARY.md](PHASE1_SUMMARY.md)

---

## 🔜 Upcoming (Phase 2+)

- [ ] Product detail page with Add to Cart
- [ ] Address management (CRUD)
- [ ] Checkout flow
- [ ] Payment integration (VNPay, Momo)
- [ ] Order tracking
- [ ] Review system
- [ ] Search & filters

**📋 Full roadmap:** See [INTEGRATION_PLAN.md](INTEGRATION_PLAN.md)

---

## 📂 Project Structure

```
lib/
├── configs/          # API config, constants, themes
├── models/           # Data models (User, Product, Cart, etc.)
├── provider/         # State management (Provider pattern)
├── services/         # API services (Auth, Product, Cart, etc.)
├── presentation/     # UI screens & widgets
│   ├── authentication/
│   ├── home/
│   ├── cart/
│   ├── order/
│   └── account/
├── common/           # Shared widgets
└── main.dart         # App entry point
```

---

## 🧪 Testing

### Test Backend Connection

```powershell
.\test_backend.ps1
```

### Run Tests

```bash
flutter test
```

**📋 Testing guide:** See [TESTING_GUIDE.md](TESTING_GUIDE.md)

---

## 🛠 Tech Stack

- **Framework:** Flutter 3.8.1+
- **State Management:** Provider
- **HTTP Client:** Dio
- **Storage:** flutter_secure_storage, shared_preferences
- **UI:** Material Design
- **Backend:** Node.js + Express + Prisma

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5+1 # State management
  dio: ^5.9.0 # HTTP requests
  flutter_secure_storage: ^9.2.2 # Secure token storage
  shared_preferences: ^2.3.5 # Local preferences
  intl: ^0.20.2 # Formatting
  another_flushbar: ^1.12.32 # Notifications
  carousel_slider: ^5.1.1 # Image slider
  flutter_svg: ^2.2.1 # SVG support
```

---

## 🔐 Authentication Flow

```
User enters credentials
  → AuthProvider.login()
    → AuthService.login() via Dio
      → Backend API validates
        → Returns JWT token
          → Save to FlutterSecureStorage
            → Update AuthProvider state
              → Navigate to Home
```

---

## 🎨 Design Guidelines

- **Primary Color:** `#00A19B` (Teal/Green)
- **Font:** System default (SF Pro / Roboto)
- **Language:** Vietnamese
- **Currency:** Vietnamese Dong (₫)

---

## 📄 Documentation Files

- `README.md` - This file
- `QUICKSTART.md` - Quick start guide
- `PHASE1_SUMMARY.md` - Phase 1 implementation details
- `TESTING_GUIDE.md` - Testing instructions
- `INTEGRATION_PLAN.md` - Full integration roadmap
- `API_INTEGRATION_GUIDE.md` - API usage guide
- `FLASH_SALE_API_SETUP.md` - Flash sale setup

---

## 🐛 Common Issues

### Connection Error

**Problem:** Cannot connect to backend  
**Solution:**

1. Check backend is running: `npm start`
2. Verify IP in `api_config.dart`
3. Disable firewall if using real device

### Login Failed

**Problem:** 401 Unauthorized  
**Solution:** Create test account in backend database

### Products Not Loading

**Problem:** Empty product list  
**Solution:**

1. Test API: `http://localhost:3000/api/products`
2. Check backend has products in database
3. Verify ProductModel parsing

---

## 👥 For Developers

### State Management Pattern

```dart
// In Widget
final provider = context.read<YourProvider>();
await provider.someAction();

// OR with reactive updates
Consumer<YourProvider>(
  builder: (context, provider, child) {
    return Text(provider.someData);
  },
)
```

### Adding New Features

1. Create model in `lib/models/`
2. Create service in `lib/services/`
3. Create provider in `lib/provider/`
4. Create UI in `lib/presentation/`
5. Register provider in `main.dart`

---

## 📞 Support

- Check console logs with prefixes: `✅`, `❌`, `📦`
- Enable Dart DevTools for debugging
- Review `TESTING_GUIDE.md` for troubleshooting

---

## 📝 License

This project is part of a pharmacy management system.

---

**Status:** Phase 1 Complete ✅  
**Next:** Phase 2 - Checkout Flow  
**Last Updated:** 2025-11-26
