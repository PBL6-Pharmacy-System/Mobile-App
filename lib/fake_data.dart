import 'package:pharmacy_app/models/category_model.dart';
import 'package:pharmacy_app/models/product_model.dart';

final List<CategoryModel> categories = [
  CategoryModel('Thuốc', 'assets/images/pill.svg'),
  CategoryModel('Thực phẩm chức năng', 'assets/images/apple.svg'),
  CategoryModel('Dụng cụ y tế', 'assets/images/stethoscope.svg'),
  CategoryModel('Mẹ & bé', 'assets/images/baby.svg'),
  CategoryModel('Chăm sóc sức khỏe', 'assets/images/heart.svg'),
];
final List<ProductModel> products = [
  ProductModel(
    category: categories[0],
    name: 'Paracetamol 500mg',
    price: 15000,
    image: 'https://picsum.photos/id/1011/400/400',
  ),
  ProductModel(
    category: categories[0],
    name: 'Aspirin 81mg',
    price: 18000,
    image: 'https://picsum.photos/id/1012/400/400',
  ),
  ProductModel(
    category: categories[0],
    name: 'Amoxicillin 500mg',
    price: 24000,
    image: 'https://picsum.photos/id/1013/400/400',
  ),
  ProductModel(
    category: categories[1],
    name: 'Vitamin C 1000mg',
    price: 55000,
    image: 'https://picsum.photos/id/1014/400/400',
  ),
  ProductModel(
    category: categories[1],
    name: 'Omega 3 Fish Oil',
    price: 120000,
    image: 'https://picsum.photos/id/1015/400/400',
  ),
  ProductModel(
    category: categories[1],
    name: 'Collagen Dạng Nước',
    price: 89000,
    image: 'https://picsum.photos/id/1016/400/400',
  ),
  ProductModel(
    category: categories[2],
    name: 'Máy Đo Huyết Áp Omron',
    price: 850000,
    image: 'https://picsum.photos/id/1018/400/400',
  ),
  ProductModel(
    category: categories[2],
    name: 'Nhiệt Kế Điện Tử Microlife',
    price: 120000,
    image: 'https://picsum.photos/id/1020/400/400',
  ),
  ProductModel(
    category: categories[2],
    name: 'Băng Gạc Y Tế',
    price: 25000,
    image: 'https://picsum.photos/id/1024/400/400',
  ),
  ProductModel(
    category: categories[3],
    name: 'Sữa Dành Cho Bé Friso Gold',
    price: 520000,
    image: 'https://picsum.photos/id/1025/400/400',
  ),
  ProductModel(
    category: categories[3],
    name: 'Tã Dán Huggies M',
    price: 260000,
    image: 'https://picsum.photos/id/1027/400/400',
  ),
  ProductModel(
    category: categories[3],
    name: 'Khăn Ướt Cho Bé Bobby',
    price: 35000,
    image: 'https://picsum.photos/id/1029/400/400',
  ),
  ProductModel(
    category: categories[4],
    name: 'Khẩu Trang 3D Mask',
    price: 75000,
    image: 'https://picsum.photos/id/1031/400/400',
  ),
  ProductModel(
    category: categories[4],
    name: 'Dung Dịch Rửa Tay Lifebuoy',
    price: 45000,
    image: 'https://picsum.photos/id/1033/400/400',
  ),
  ProductModel(
    category: categories[4],
    name: 'Nước Súc Miệng Listerine',
    price: 89000,
    image: 'https://picsum.photos/id/1035/400/400',
  ),
];
