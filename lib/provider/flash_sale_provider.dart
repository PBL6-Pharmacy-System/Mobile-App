import 'package:flutter/material.dart';
import '../services/flash_sale_service.dart';
import '../models/flash_sale_product_model.dart';

class FlashSaleProvider extends ChangeNotifier {
  final FlashSaleService _service = FlashSaleService();

  List<FlashSaleProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  // Cache management
  DateTime? _lastLoadTime;
  static const _cacheValidDuration = Duration(
    minutes: 3,
  ); // Flash sale thay đổi nhanh hơn

  List<FlashSaleProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Kiểm tra cache còn hiệu lực không
  bool _isCacheValid() {
    if (_lastLoadTime == null) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  /// Fetch active flash sales from backend
  Future<void> fetchActiveFlashSales({bool forceRefresh = false}) async {
    // Nếu cache còn hiệu lực và không force refresh, skip API call
    if (!forceRefresh && _isCacheValid() && _products.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getActiveFlashSales();
      _lastLoadTime = DateTime.now();
    } catch (e) {
      _error = e.toString();
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch flash sale by ID
  Future<FlashSaleProductModel?> fetchFlashSaleById(int id) async {
    try {
      return await _service.getFlashSaleById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh flash sales (force reload)
  Future<void> refresh() async {
    await fetchActiveFlashSales(forceRefresh: true);
  }

  /// Invalidate cache
  void invalidateCache() {
    _lastLoadTime = null;
  }
}
