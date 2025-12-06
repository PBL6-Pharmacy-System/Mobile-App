import 'package:flutter/material.dart';
import 'package:pharmacy_app/models/cart_model.dart';
import 'package:pharmacy_app/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  // State
  CartModel? _cart;
  bool _isLoading = false;
  String? _error;

  // Track which item is being updated (for individual loading indicator)
  int? _updatingItemId;

  // Applied voucher info
  String? _appliedVoucherCode;
  double _voucherDiscount = 0.0;

  // Cache management
  DateTime? _lastLoadTime;
  int? _lastCustomerId;
  static const _cacheValidDuration = Duration(
    minutes: 2,
  ); // Cart thay đổi thường xuyên

  // Getters
  CartModel? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get updatingItemId => _updatingItemId;
  String? get appliedVoucherCode => _appliedVoucherCode;
  double get voucherDiscount => _voucherDiscount;

  // Cart summary getters
  int get itemCount => _cart?.items.length ?? 0;

  double get subtotal {
    if (_cart == null) return 0.0;
    return _cart!.items.fold(0.0, (sum, item) {
      return sum + (item.price * item.quantity);
    });
  }

  double get total {
    return subtotal - _voucherDiscount;
  }

  /// Kiểm tra cache còn hiệu lực không
  bool _isCacheValid(int customerId) {
    if (_lastLoadTime == null || _lastCustomerId != customerId) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  /// Fetch cart for customer
  Future<void> fetchCart(int customerId, {bool forceRefresh = false}) async {
    // Nếu cache còn hiệu lực và không force refresh, skip API call
    if (!forceRefresh && _isCacheValid(customerId) && _cart != null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _cartService.getCart(customerId);
      _lastLoadTime = DateTime.now();
      _lastCustomerId = customerId;
      print(
        '📦 [CartProvider] Cart loaded: ${_cart?.id}, items: ${_cart?.items.length}',
      );
      if (_cart != null) {
        for (var item in _cart!.items) {
          print(
            '📦 [CartProvider] Item: ${item.id}, product: ${item.productUnit?.product?.name}, qty: ${item.quantity}',
          );
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ [CartProvider] Fetch cart error: $e');
      _error = 'Không thể tải giỏ hàng';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add item to cart - Optimistic update for instant UI feedback
  Future<bool> addItem({
    required int customerId,
    required int productId,
    required int productUnitId,
    required int quantity,
    double? unitPrice,
    int? branchId,
    // Thông tin để hiển thị ngay - optional
    String? productName,
    String? productImage,
    String? unitName,
  }) async {
    _error = null;

    // Tạo temporary item để hiển thị ngay (Optimistic Update)
    CartItemModel? tempItem;
    int? existingItemIndex;
    int? oldQuantity;

    if (_cart != null && unitPrice != null) {
      // Kiểm tra xem item đã có trong cart chưa
      existingItemIndex = _cart!.items.indexWhere(
        (item) => item.productUnitId == productUnitId,
      );

      if (existingItemIndex != -1) {
        // Item đã có -> cập nhật số lượng
        oldQuantity = _cart!.items[existingItemIndex].quantity;
        _cart!.items[existingItemIndex] = _cart!.items[existingItemIndex]
            .copyWith(quantity: oldQuantity + quantity);
      } else {
        // Item mới -> thêm vào cart
        tempItem = CartItemModel(
          id: -DateTime.now().millisecondsSinceEpoch, // Temp ID âm
          cartId: _cart!.id,
          productId: productId,
          productUnitId: productUnitId,
          quantity: quantity,
          price: unitPrice,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          productUnit: ProductUnitInfo(
            id: productUnitId,
            productId: productId,
            unitName: unitName ?? '',
            conversionRate: 1.0,
            price: unitPrice,
            product: ProductBasicInfo(
              id: productId,
              name: productName ?? 'Đang tải...',
              imageUrl: productImage,
              images: productImage != null ? [productImage] : [],
            ),
          ),
        );
        _cart!.items.add(tempItem);
      }

      // Notify UI ngay lập tức
      notifyListeners();
    } else {
      // Không có cart hoặc thông tin -> hiển thị loading
      _isLoading = true;
      notifyListeners();
    }

    try {
      final success = await _cartService.addToCart(
        customerId: customerId,
        productId: productId,
        productUnitId: productUnitId,
        quantity: quantity,
        unitPrice: unitPrice,
        branchId: branchId,
      );

      if (success) {
        // Background refresh để lấy data chính xác từ server
        // Không cần await, chạy ngầm
        _refreshCartInBackground(customerId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Rollback nếu thất bại
        _rollbackOptimisticAdd(tempItem, existingItemIndex, oldQuantity);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [CartProvider] Add item error: $e');
      // Rollback on error
      _rollbackOptimisticAdd(tempItem, existingItemIndex, oldQuantity);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Rollback optimistic add khi API thất bại
  void _rollbackOptimisticAdd(
    CartItemModel? tempItem,
    int? existingItemIndex,
    int? oldQuantity,
  ) {
    if (_cart == null) return;

    if (tempItem != null) {
      // Xóa temp item
      _cart!.items.removeWhere((item) => item.id == tempItem.id);
    } else if (existingItemIndex != null &&
        oldQuantity != null &&
        existingItemIndex != -1) {
      // Restore old quantity
      _cart!.items[existingItemIndex] = _cart!.items[existingItemIndex]
          .copyWith(quantity: oldQuantity);
    }
  }

  /// Refresh cart in background without blocking UI
  Future<void> _refreshCartInBackground(int customerId) async {
    try {
      final newCart = await _cartService.getCart(customerId);
      if (newCart != null) {
        _cart = newCart;
        _lastLoadTime = DateTime.now();
        _lastCustomerId = customerId;
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ [CartProvider] Background refresh failed: $e');
      // Không show error vì đây là background task
    }
  }

  /// Update cart item quantity - Optimistic update (no full page reload)
  Future<bool> updateItemQuantity({
    required int customerId,
    required int itemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      // If quantity is 0 or less, remove the item
      return await removeItem(customerId: customerId, itemId: itemId);
    }

    // Find the item in cart
    final itemIndex =
        _cart?.items.indexWhere((item) => item.id == itemId) ?? -1;
    if (itemIndex == -1) {
      _error = 'Không tìm thấy sản phẩm trong giỏ hàng';
      notifyListeners();
      return false;
    }

    // Save old quantity for rollback
    final oldQuantity = _cart!.items[itemIndex].quantity;

    // Optimistic update - update UI immediately
    _updatingItemId = itemId;
    _cart!.items[itemIndex] = _cart!.items[itemIndex].copyWith(
      quantity: quantity,
    );
    _error = null;
    notifyListeners();

    try {
      final success =
          await _cartService.updateCartItem(
            customerId: customerId,
            itemId: itemId,
            quantity: quantity,
          ) !=
          null;

      _updatingItemId = null;

      if (!success) {
        // Rollback on failure
        _cart!.items[itemIndex] = _cart!.items[itemIndex].copyWith(
          quantity: oldQuantity,
        );
        _error = 'Không thể cập nhật số lượng';
      }

      notifyListeners();
      return success;
    } catch (e) {
      print('❌ [CartProvider] Update item error: $e');
      // Rollback on error
      _cart!.items[itemIndex] = _cart!.items[itemIndex].copyWith(
        quantity: oldQuantity,
      );
      _error = e.toString();
      _updatingItemId = null;
      notifyListeners();
      return false;
    }
  }

  /// Remove item from cart - Optimistic update
  Future<bool> removeItem({
    required int customerId,
    required int itemId,
  }) async {
    _error = null;

    // Tìm và lưu item để rollback nếu cần
    final itemIndex =
        _cart?.items.indexWhere((item) => item.id == itemId) ?? -1;
    CartItemModel? removedItem;

    if (itemIndex != -1 && _cart != null) {
      // Lưu item trước khi xóa
      removedItem = _cart!.items[itemIndex];
      // Optimistic remove - xóa ngay UI
      _cart!.items.removeAt(itemIndex);
      notifyListeners();
    } else {
      _isLoading = true;
      notifyListeners();
    }

    try {
      print(
        '🗑️ [CartProvider] Removing item: customerId=$customerId, itemId=$itemId',
      );

      await _cartService.removeCartItem(customerId: customerId, itemId: itemId);

      print('✅ [CartProvider] Item removed successfully');

      // Background refresh để đồng bộ với server
      _refreshCartInBackground(customerId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ [CartProvider] Remove item error: $e');

      // Rollback - thêm lại item nếu xóa thất bại
      if (removedItem != null && _cart != null) {
        _cart!.items.insert(itemIndex, removedItem);
      }

      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear entire cart
  Future<bool> clearCart(int customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _cartService.clearCart(customerId);

      if (success) {
        _cart = null;
        _appliedVoucherCode = null;
        _voucherDiscount = 0.0;
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('❌ [CartProvider] Clear cart error: $e');
      _error = 'Không thể xóa giỏ hàng';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Apply voucher (preview only - not saved on backend)
  Future<bool> applyVoucher({
    required int customerId,
    required String voucherCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _cartService.previewVoucher(
        customerId: customerId,
        voucherCode: voucherCode,
      );

      if (result['valid'] == true) {
        _appliedVoucherCode = voucherCode;
        _voucherDiscount = (result['discountAmount'] ?? 0.0).toDouble();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Mã voucher không hợp lệ';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ [CartProvider] Apply voucher error: $e');
      _error = 'Không thể áp dụng voucher';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove voucher
  void removeVoucher() {
    _appliedVoucherCode = null;
    _voucherDiscount = 0.0;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get cart summary (for badge display)
  Future<Map<String, dynamic>> getCartSummary(int customerId) async {
    try {
      return await _cartService.getCartSummary(customerId);
    } catch (e) {
      print('❌ [CartProvider] Get cart summary error: $e');
      return {'itemCount': 0, 'totalAmount': 0.0};
    }
  }

  /// Invalidate cache - gọi khi cần force reload
  void invalidateCache() {
    _lastLoadTime = null;
    _lastCustomerId = null;
  }
}
