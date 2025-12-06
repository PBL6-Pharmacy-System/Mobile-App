# Category Screen Integration Example

## Cách thêm CategoryScreen vào App

### Option 1: Add to Bottom Navigation

```dart
// lib/main.dart or home_screen.dart

import 'package:pharmacy_app/presentation/category/category_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const CategoryScreen(), // ⭐ Add here
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category), // ⭐ Category icon
            label: 'Danh mục',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
```

### Option 2: Navigate from Button

```dart
// Anywhere in your app
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryScreen(),
      ),
    );
  },
  child: const Text('Xem danh mục'),
)
```

### Option 3: Add to Home Screen Grid

```dart
// In your home screen
GridView(
  children: [
    CategoryTile(
      icon: Icons.category,
      title: 'Danh mục sản phẩm',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CategoryScreen(),
          ),
        );
      },
    ),
    // Other tiles...
  ],
)
```

## Test Backend trước khi chạy

```powershell
# Test category tree API
Invoke-RestMethod -Uri "http://localhost:3000/api/categories/tree" | ConvertTo-Json -Depth 10

# Test products API
Invoke-RestMethod -Uri "http://localhost:3000/api/products?categoryId=128&page=1&limit=6" | ConvertTo-Json -Depth 10
```

## Verify API Config

Make sure `lib/configs/api_config.dart` has correct baseUrl:

```dart
class ApiConfig {
  static const String _host = 'localhost'; // or your IP
  static const String _port = '3000';
  static const String baseUrl = 'http://$_host:$_port/api';
}
```

## Run the app

```powershell
cd D:\AppMobile\pharmacy_app
flutter run
```
