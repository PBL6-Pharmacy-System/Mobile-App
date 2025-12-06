# Fix Lỗi "Đơn Vị Sản Phẩm Không Tồn Tại"

## 🐛 Vấn Đề

Khi thêm sản phẩm vào giỏ hàng, báo lỗi:

```
❌ {"success":false,"error":"Đơn vị sản phẩm không tồn tại"}
```

## 🔍 Nguyên Nhân

Backend cần `productUnitId` (ID từ bảng `productunits`), KHÔNG phải `baseUnitId`.

Mỗi sản phẩm có thể có nhiều đơn vị (hộp, viên, vỉ...), mỗi đơn vị có:

- `id`: Product Unit ID (cần gửi cho backend)
- `unit_name`: Tên đơn vị (hộp, viên...)
- `conversion_factor`: Hệ số chuyển đổi (1 = đơn vị cơ bản)
- `price`: Giá của đơn vị này

## ✅ Đã Sửa

### 1. **Thêm ProductUnit Model**

```dart
class ProductUnit {
  int id;                    // ← CÁI NÀY CẦN GỬI CHO BACKEND
  int productId;
  int unitId;
  String unitName;
  int conversionFactor;      // 1 = base unit
  String price;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 2. **Parse productunits từ API**

Backend trả về:

```json
{
  "id": 123,
  "name": "Paracetamol",
  "price": "5000",
  "productunits": [
    // ← Parse cái này
    {
      "id": 456, // ← productUnitId
      "unit_name": "Hộp",
      "conversion_factor": 1,
      "price": "50000"
    },
    {
      "id": 457,
      "unit_name": "Viên",
      "conversion_factor": 10,
      "price": "5000"
    }
  ]
}
```

### 3. **Sử dụng đúng productUnitId**

```dart
// CŨ (SAI):
productUnitId: widget.product.baseUnitId  // ← Đây là unit TYPE id, không phải unit id

// MỚI (ĐÚNG):
final defaultUnit = widget.product.defaultUnit;  // Lấy unit có conversion_factor = 1
productUnitId: defaultUnit.id  // ← Đây mới là productUnitId đúng
```

### 4. **Getter defaultUnit**

```dart
// Trong ProductModel
ProductUnit? get defaultUnit {
  if (productUnits.isEmpty) return null;

  // Tìm unit có conversion_factor = 1 (base unit)
  try {
    return productUnits.firstWhere(
      (unit) => unit.conversionFactor == 1,
    );
  } catch (e) {
    // Nếu không tìm thấy, trả về unit đầu tiên
    return productUnits.first;
  }
}
```

## 🧪 Kiểm Tra Logs

### Khi load sản phẩm:

```
✅ Parsed 2 product units for Paracetamol
⚠️ No productunits in response for Product X  // ← Backend không trả về productunits
⚠️ Error parsing productunits: ...            // ← Lỗi parse JSON
```

### Khi thêm giỏ hàng:

```
📦 Adding to cart: productId=123, productUnitId=456, price=5000
✅ Added to cart successfully

// HOẶC
❌ No product units available  // ← product.defaultUnit là null
```

## 🔧 Nếu Vẫn Lỗi

### 1. Kiểm tra backend có trả về productunits không

Thêm log trong `product_service.dart`:

```dart
final response = await _dio.get('/products/category/$categoryName');
print('📦 Full response: ${response.data}');
```

Xem có `productunits` trong response không.

### 2. Kiểm tra productunits có được parse không

Console sẽ có log:

```
✅ Parsed 2 product units for [tên SP]
```

Nếu thấy:

```
⚠️ No productunits in response
```

→ Backend KHÔNG trả về `productunits`. Cần check backend query.

### 3. Backend query có include productunits không?

Check file `productService.js`:

```javascript
const product = await prisma.products.findUnique({
  where: { id: Number(id) },
  include: {
    categories: true,
    suppliers: true,
    unittype: true,
    productunits: true, // ← PHẢI CÓ DÒNG NÀY
  },
});
```

### 4. Test trực tiếp API

```bash
curl http://localhost:3000/api/products/1
```

Response phải có:

```json
{
  "id": 1,
  "name": "...",
  "productunits": [...]  // ← PHẢI CÓ
}
```

## 📋 Các Case Lỗi Khác

### Case 1: "No product units available"

**Nguyên nhân**: `product.productUnits` là empty array

**Giải pháp**:

1. Kiểm tra backend có trả về productunits không
2. Kiểm tra database có data trong bảng `productunits` không
3. Tạo product units cho sản phẩm trong database

### Case 2: Parse error khi đọc productunits

**Nguyên nhân**: JSON structure không đúng

**Giải pháp**:

```dart
// Thêm log chi tiết
print('Raw productunits data: ${json["productunits"]}');
```

### Case 3: Backend 404 "Đơn vị sản phẩm không tồn tại"

**Nguyên nhân**: `productUnitId` không có trong database

**Debug**:

```dart
print('Sending productUnitId: $productUnitId');
// Xem ID này có trong database không
```

```sql
-- Check trong database
SELECT * FROM productunits WHERE id = 456;
```

## 💡 Best Practices

### 1. Luôn kiểm tra defaultUnit trước khi dùng

```dart
final defaultUnit = product.defaultUnit;
if (defaultUnit == null) {
  showError('Sản phẩm không có đơn vị giá bán');
  return;
}
```

### 2. Show unit name trong UI

```dart
Text('${product.name} - ${product.defaultUnit?.unitName ?? ""}')
// Output: "Paracetamol - Hộp"
```

### 3. Cho phép user chọn đơn vị

```dart
DropdownButton<int>(
  value: selectedUnitId,
  items: product.productUnits.map((unit) {
    return DropdownMenuItem(
      value: unit.id,
      child: Text('${unit.unitName} - ${unit.price} VNĐ'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => selectedUnitId = value);
  },
)
```

## 🎯 Expected Behavior

Sau khi sửa:

1. **Load sản phẩm** → Parse productunits thành công

   ```
   ✅ Parsed 2 product units for Paracetamol
   ```

2. **Nhấn "Thêm giỏ"** → Gửi đúng productUnitId

   ```
   📦 Adding to cart: productId=123, productUnitId=456
   ✅ Added to cart successfully
   ```

3. **Hiển thị thông báo** → "Đã thêm Paracetamol vào giỏ hàng" ✅

## 🆘 Nếu Cần Hỗ Trợ

Cung cấp:

1. Console logs khi load sản phẩm
2. Console logs khi thêm giỏ hàng
3. Backend response (full JSON)
4. Screenshot lỗi

---

**Last Updated**: 27/11/2025
**Backend API**: v1.0.0
**Fix Version**: 2.0.0
