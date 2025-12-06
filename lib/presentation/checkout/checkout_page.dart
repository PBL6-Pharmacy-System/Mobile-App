import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/home_screen.dart';
import 'package:pharmacy_app/models/address_model.dart';
import 'package:pharmacy_app/models/voucher_model.dart';
import 'package:pharmacy_app/presentation/order/order_detail_page.dart';
import 'package:pharmacy_app/presentation/order/order_page.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:pharmacy_app/provider/cart_provider.dart';
import 'package:pharmacy_app/services/checkout_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CheckoutService _checkoutService = CheckoutService();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _noteController = TextEditingController();
  final _voucherController = TextEditingController();

  // State
  String _paymentMethod = "COD";
  bool _isLoading = false;
  bool _isLoadingAddresses = true;
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _useNewAddress = false;

  // Voucher state
  bool _isApplyingVoucher = false;
  bool _isLoadingVouchers = false;
  double _voucherDiscount = 0;
  String? _appliedVoucherCode;
  String? _voucherError;
  List<VoucherModel> _availableVouchers = [];
  VoucherModel? _selectedVoucher;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadAvailableVouchers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _noteController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final authProvider = context.read<AuthProvider>();
    final customerId = authProvider.currentUser?.customerId;

    if (customerId == null) {
      setState(() => _isLoadingAddresses = false);
      return;
    }

    final addresses = await _checkoutService.getAddresses(customerId);

    setState(() {
      _addresses = addresses;
      _isLoadingAddresses = false;

      // Auto-select default address
      if (addresses.isNotEmpty) {
        _selectedAddress = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
        _useNewAddress = false;
      } else {
        _useNewAddress = true;
      }
    });
  }

  Future<void> _loadAvailableVouchers() async {
    setState(() => _isLoadingVouchers = true);

    final vouchers = await _checkoutService.getAvailableVouchers();

    setState(() {
      _availableVouchers = vouchers;
      _isLoadingVouchers = false;
    });
  }

  void _selectVoucher(VoucherModel voucher) {
    final cartProvider = context.read<CartProvider>();
    final subtotal = cartProvider.subtotal;

    print('🎫 [Checkout] Selecting voucher: ${voucher.code}');
    print('🎫 [Checkout] Voucher type: ${voucher.type}');
    print('🎫 [Checkout] Voucher value: ${voucher.value}');
    print('🎫 [Checkout] Subtotal: $subtotal');
    print('🎫 [Checkout] Min order value: ${voucher.minOrderValue}');

    // Check minimum order value
    if (voucher.minOrderValue != null && subtotal < voucher.minOrderValue!) {
      setState(() {
        _voucherError =
            'Đơn hàng tối thiểu ${currencyFormatter.format(voucher.minOrderValue)} để áp dụng mã này';
      });
      return;
    }

    // Calculate discount
    final discount = voucher.calculateDiscount(subtotal);
    print('🎫 [Checkout] Calculated discount: $discount');

    setState(() {
      _selectedVoucher = voucher;
      _appliedVoucherCode = voucher.code;
      _voucherDiscount = discount;
      _voucherError = null;
      _voucherController.text = voucher.code;
    });

    Navigator.pop(context); // Close bottom sheet
  }

  Future<void> _applyVoucher() async {
    final voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) {
      setState(() {
        _voucherError = 'Vui lòng nhập mã giảm giá';
      });
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final subtotal = cartProvider.subtotal;

    setState(() {
      _isApplyingVoucher = true;
      _voucherError = null;
    });

    // Sử dụng API /vouchers/check/:code
    final result = await _checkoutService.checkVoucherCode(
      voucherCode: voucherCode,
      orderAmount: subtotal,
    );

    setState(() {
      _isApplyingVoucher = false;
      if (result.valid) {
        // Tính tiền giảm giá
        final discount = result.calculateDiscount(subtotal);

        _voucherDiscount = discount;
        _appliedVoucherCode = result.voucherCode ?? voucherCode;
        _voucherError = null;

        // Tạo VoucherModel từ kết quả để lưu vào _selectedVoucher
        _selectedVoucher = VoucherModel(
          id: 0,
          code: result.voucherCode ?? voucherCode,
          type: result.discountType ?? 'fixed',
          value: result.discountValue ?? 0,
          minOrderValue: result.minOrderValue,
          maxDiscount: null,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          usageLimit: null,
          usedCount: 0,
          isActive: true,
          description: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        _voucherDiscount = 0;
        _appliedVoucherCode = null;
        _selectedVoucher = null;
        _voucherError = result.message;
      }
    });
  }

  void _removeVoucher() {
    setState(() {
      _voucherDiscount = 0;
      _appliedVoucherCode = null;
      _selectedVoucher = null;
      _voucherController.clear();
      _voucherError = null;
    });
  }

  Future<void> _handleCheckout() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final customerId = authProvider.currentUser?.customerId;

    if (customerId == null) {
      _showErrorDialog('Vui lòng đăng nhập để đặt hàng');
      return;
    }

    // Validate
    int? addressId;

    if (_useNewAddress) {
      // Validate new address fields
      if (_nameController.text.trim().isEmpty) {
        _showErrorDialog('Vui lòng nhập họ tên người nhận');
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        _showErrorDialog('Vui lòng nhập số điện thoại');
        return;
      }
      if (_addressController.text.trim().isEmpty) {
        _showErrorDialog('Vui lòng nhập địa chỉ giao hàng');
        return;
      }
      if (_cityController.text.trim().isEmpty) {
        _showErrorDialog('Vui lòng nhập thành phố');
        return;
      }

      // Create new address first
      setState(() => _isLoading = true);

      try {
        final newAddress = await _checkoutService.createAddress(
          customerId: customerId,
          recipientName: _nameController.text.trim(),
          recipientPhone: _phoneController.text.trim(),
          addressLine: _addressController.text.trim(),
          city: _cityController.text.trim(),
          isDefault: _addresses.isEmpty,
        );

        if (newAddress == null) {
          setState(() => _isLoading = false);
          _showErrorDialog('Không thể tạo địa chỉ mới');
          return;
        }

        addressId = newAddress.id;
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString());
        return;
      }
    } else {
      if (_selectedAddress == null) {
        _showErrorDialog('Vui lòng chọn địa chỉ giao hàng');
        return;
      }
      addressId = _selectedAddress!.id;
    }

    setState(() => _isLoading = true);

    // Call checkout API
    final result = await _checkoutService.checkout(
      shippingAddressId: addressId,
      paymentMethod: _paymentMethod,
      voucherCode: _appliedVoucherCode,
      note: _noteController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.success) {
      // Nếu thanh toán MoMo, gọi API tạo thanh toán MoMo
      if (_paymentMethod == 'momo' && result.order != null) {
        await _handleMoMoPayment(result.order!.id, customerId, cartProvider);
      } else {
        // COD hoặc các phương thức khác
        cartProvider.clearCart(customerId);
        if (mounted) {
          _showSuccessDialog(result.order?.id);
        }
      }
    } else {
      _showErrorDialog(result.message);
    }
  }

  /// Xử lý thanh toán MoMo
  Future<void> _handleMoMoPayment(
    int orderId,
    int customerId,
    CartProvider cartProvider,
  ) async {
    setState(() => _isLoading = true);

    final momoResult = await _checkoutService.createMoMoPayment(orderId);

    setState(() => _isLoading = false);

    if (momoResult.success) {
      // Clear cart
      cartProvider.clearCart(customerId);

      // Hiển thị dialog chọn cách thanh toán MoMo
      if (mounted) {
        _showMoMoPaymentDialog(momoResult);
      }
    } else {
      _showErrorDialog(momoResult.message);
    }
  }

  /// Hiển thị Bottom Sheet thanh toán MoMo với QR code
  void _showMoMoPaymentDialog(MoMoPaymentResult momoResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MoMoPaymentSheet(
        momoResult: momoResult,
        onOpenApp: () async {
          Navigator.pop(ctx);
          await _openMoMoApp(momoResult.deeplink!);
        },
        onOpenWeb: () async {
          Navigator.pop(ctx);
          await _openMoMoWeb(momoResult.payUrl!);
        },
        onClose: () {
          Navigator.pop(ctx);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  /// Mở app MoMo qua deeplink
  Future<void> _openMoMoApp(String deeplink) async {
    try {
      final uri = Uri.parse(deeplink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Nếu không có app MoMo, thông báo
        if (mounted) {
          _showErrorDialog('Vui lòng cài đặt ứng dụng MoMo để thanh toán');
        }
      }
    } catch (e) {
      print('❌ Error opening MoMo app: $e');
      if (mounted) {
        _showErrorDialog('Không thể mở ứng dụng MoMo');
      }
    }

    // Sau khi mở MoMo, về trang chủ
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  /// Mở trang web thanh toán MoMo
  Future<void> _openMoMoWeb(String payUrl) async {
    try {
      final uri = Uri.parse(payUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showErrorDialog('Không thể mở trang thanh toán');
        }
      }
    } catch (e) {
      print('❌ Error opening MoMo web: $e');
      if (mounted) {
        _showErrorDialog('Không thể mở trang thanh toán');
      }
    }

    // Sau khi mở web, về trang chủ
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(int? orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Expanded(child: Text('Đặt hàng thành công!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (orderId != null)
              Text(
                'Mã đơn hàng: #$orderId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 8),
            const Text(
              'Cảm ơn bạn đã đặt hàng. Chúng tôi sẽ xử lý đơn hàng của bạn trong thời gian sớm nhất.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to home
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Về trang chủ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to order detail or order list
              if (orderId != null) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailPage(orderId: orderId),
                  ),
                  (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text(
              'Xem đơn hàng',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Thanh toán",
          style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAddressSection(),
                  const SizedBox(height: 16),
                  _buildOrderSummary(),
                  const SizedBox(height: 16),
                  _buildVoucherSection(),
                  const SizedBox(height: 16),
                  _buildPaymentMethodCard(),
                  const SizedBox(height: 16),
                  _buildNoteSection(),
                  const SizedBox(height: 16),
                  _buildTotalSection(),
                  const SizedBox(height: 24),
                  ButtonApp(
                    onPressed: _handleCheckout,
                    child: const Text("Xác nhận đặt hàng"),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: primaryColor, size: 20),
              const SizedBox(width: 6),
              Text(
                "Địa chỉ giao hàng",
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_isLoadingAddresses)
            const Center(child: CircularProgressIndicator())
          else if (_addresses.isNotEmpty && !_useNewAddress) ...[
            // Lấy tối đa 2 địa chỉ: mặc định + mới nhất
            ..._getDisplayAddresses().map(
              (address) => _buildAddressOption(address),
            ),
            // Nút xem thêm nếu có nhiều hơn 2 địa chỉ
            if (_addresses.length > 2)
              Center(
                child: InkWell(
                  onTap: _showAllAddressesBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem ${_addresses.length - 2} địa chỉ khác',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Divider(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _useNewAddress = true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Thêm địa chỉ mới',
                style: TextStyle(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ] else ...[
            // New address form
            if (_addresses.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(() => _useNewAddress = false),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Chọn từ địa chỉ đã lưu'),
              ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              label: 'Họ và tên người nhận *',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: 'Số điện thoại *',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: 'Địa chỉ chi tiết *',
              icon: Icons.home,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _cityController,
              label: 'Thành phố *',
              icon: Icons.location_city,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressOption(AddressModel address) {
    final isSelected = _selectedAddress?.id == address.id;

    return InkWell(
      onTap: () => setState(() => _selectedAddress = address),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.05)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Radio nhỏ gọn
            SizedBox(
              width: 20,
              height: 20,
              child: Radio<int>(
                value: address.id,
                groupValue: _selectedAddress?.id,
                onChanged: (v) => setState(() => _selectedAddress = address),
                activeColor: primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name, phone và badge trên 1 dòng
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.recipientName ?? 'Chưa có tên',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected ? primaryColor : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.recipientPhone != null &&
                          address.recipientPhone!.isNotEmpty) ...[
                        Text(
                          '  •  ',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          address.recipientPhone!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (address.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'Mặc định',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Address line
                  Text(
                    address.fullAddress,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final items = cartProvider.cart?.items ?? [];

        return Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "Đơn hàng (${items.length} sản phẩm)",
                    style: context.textTheme.titleMedium,
                  ),
                ],
              ),
              const Divider(),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productUnit?.product?.name ?? 'Sản phẩm',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.productUnit?.unitName ?? ''} x ${item.quantity}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormatter.format(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: primaryColor),
              const SizedBox(width: 8),
              Text("Mã giảm giá", style: context.textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: _showVoucherBottomSheet,
                child: const Text('Chọn mã'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_appliedVoucherCode != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã: $_appliedVoucherCode',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Giảm: ${currencyFormatter.format(_voucherDiscount)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeVoucher,
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucherController,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã giảm giá',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      errorText: _voucherError,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isApplyingVoucher ? null : _applyVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: _isApplyingVoucher
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Áp dụng',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Lấy danh sách địa chỉ hiển thị (tối đa 2: mặc định + mới nhất)
  List<AddressModel> _getDisplayAddresses() {
    if (_addresses.length <= 2) {
      return _addresses;
    }

    // Tìm địa chỉ mặc định
    final defaultAddress = _addresses.where((a) => a.isDefault).toList();
    // Tìm địa chỉ mới nhất (không phải mặc định)
    final nonDefaultAddresses = _addresses.where((a) => !a.isDefault).toList();

    List<AddressModel> result = [];

    // Thêm địa chỉ mặc định
    if (defaultAddress.isNotEmpty) {
      result.add(defaultAddress.first);
    }

    // Thêm địa chỉ mới nhất (nếu còn chỗ)
    if (nonDefaultAddresses.isNotEmpty && result.length < 2) {
      result.add(nonDefaultAddresses.first);
    }

    // Nếu chưa đủ 2, thêm từ danh sách còn lại
    if (result.length < 2 && nonDefaultAddresses.length > 1) {
      result.add(nonDefaultAddresses[1]);
    }

    return result;
  }

  /// Hiển thị bottom sheet tất cả địa chỉ
  void _showAllAddressesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Chọn địa chỉ giao hàng',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_addresses.length} địa chỉ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            // Address list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  return _buildAddressOptionInBottomSheet(address, ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Address option trong bottom sheet
  Widget _buildAddressOptionInBottomSheet(
    AddressModel address,
    BuildContext ctx,
  ) {
    final isSelected = _selectedAddress?.id == address.id;

    return InkWell(
      onTap: () {
        setState(() => _selectedAddress = address);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.05)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            SizedBox(
              width: 20,
              height: 20,
              child: Radio<int>(
                value: address.id,
                groupValue: _selectedAddress?.id,
                onChanged: (v) {
                  setState(() => _selectedAddress = address);
                  Navigator.pop(ctx);
                },
                activeColor: primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + phone + badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.recipientName ?? 'Chưa có tên',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isSelected ? primaryColor : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.recipientPhone != null &&
                          address.recipientPhone!.isNotEmpty) ...[
                        Text(
                          '  •  ',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          address.recipientPhone!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Mặc định',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Full address
                  Text(
                    address.fullAddress,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoucherBottomSheet() {
    final cartProvider = context.read<CartProvider>();
    final subtotal = cartProvider.subtotal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Chọn mã giảm giá',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: _isLoadingVouchers
                  ? const Center(child: CircularProgressIndicator())
                  : _availableVouchers.isEmpty
                  ? const Center(child: Text('Không có mã giảm giá nào'))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableVouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = _availableVouchers[index];
                        return _buildVoucherItem(voucher, subtotal);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherItem(VoucherModel voucher, double subtotal) {
    final isSelected = _selectedVoucher?.id == voucher.id;
    final isAlreadyUsed =
        voucher.isUsedByCurrentUser; // Voucher đã được user sử dụng
    final meetsMinOrder =
        voucher.minOrderValue == null || subtotal >= voucher.minOrderValue!;

    // Voucher có thể sử dụng: chưa dùng và đủ điều kiện đơn tối thiểu
    final canUse = !isAlreadyUsed && meetsMinOrder;

    return Opacity(
      opacity: isAlreadyUsed ? 0.5 : 1.0, // Làm mờ voucher đã sử dụng
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (canUse ? Colors.grey.shade300 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: canUse ? Colors.white : Colors.grey.shade100,
        ),
        child: InkWell(
          onTap: canUse ? () => _selectVoucher(voucher) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Voucher icon/badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: canUse
                        ? primaryColor.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.discount,
                        color: canUse ? primaryColor : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        voucher.displayValue,
                        style: TextStyle(
                          color: canUse ? primaryColor : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Voucher info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              voucher.code,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: canUse ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                          // Hiển thị badge "Đã dùng" nếu voucher đã sử dụng
                          if (isAlreadyUsed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Đã dùng',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.type == 'percentage'
                            ? 'Giảm ${voucher.value.toInt()}%'
                            : 'Giảm ${currencyFormatter.format(voucher.value)}',
                        style: TextStyle(
                          color: canUse ? Colors.green : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      if (voucher.minOrderValue != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Đơn tối thiểu: ${currencyFormatter.format(voucher.minOrderValue)}',
                          style: TextStyle(
                            color: canUse ? Colors.grey[600] : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      // Hiển thị lý do không thể sử dụng
                      if (isAlreadyUsed) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Bạn đã sử dụng mã này',
                          style: TextStyle(color: Colors.orange, fontSize: 11),
                        ),
                      ] else if (!meetsMinOrder) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Cần mua thêm ${currencyFormatter.format(voucher.minOrderValue! - subtotal)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Selection indicator
                if (isSelected)
                  const Icon(Icons.check_circle, color: primaryColor)
                else if (canUse)
                  Icon(Icons.radio_button_off, color: Colors.grey.shade400)
                else if (isAlreadyUsed)
                  const Icon(Icons.block, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: primaryColor, size: 20),
              const SizedBox(width: 6),
              Text(
                "Phương thức thanh toán",
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Danh sách dọc giống địa chỉ
          _paymentOption(
            "COD",
            "Thanh toán khi nhận hàng (COD)",
            Icons.local_shipping,
          ),
          _paymentOption("momo", "Ví MoMo", Icons.account_balance_wallet),
          _paymentOption("vnpay", "VNPay", Icons.credit_card),
          _paymentOption(
            "bank_transfer",
            "Chuyển khoản ngân hàng",
            Icons.account_balance,
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.05)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Radio nhỏ gọn
            SizedBox(
              width: 20,
              height: 20,
              child: Radio<String>(
                value: value,
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
                activeColor: primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Icon
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: isSelected ? primaryColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 10),
            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, color: primaryColor),
              const SizedBox(width: 8),
              Text("Ghi chú", style: context.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ghi chú cho đơn hàng (tùy chọn)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final subtotal = cartProvider.subtotal;
        final discount = _voucherDiscount;
        final total = subtotal - discount;

        return Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPriceRow('Tạm tính', subtotal),
              if (discount > 0)
                _buildPriceRow('Giảm giá', -discount, isDiscount: true),
              _buildPriceRow('Phí vận chuyển', 0, isFree: true),
              const Divider(),
              _buildPriceRow('Tổng cộng', total, isTotal: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isFree = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            isFree
                ? 'Miễn phí'
                : (isDiscount
                      ? '- ${currencyFormatter.format(amount.abs())}'
                      : currencyFormatter.format(amount)),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isDiscount
                  ? Colors.green
                  : (isFree ? Colors.green : (isTotal ? primaryColor : null)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget Bottom Sheet thanh toán MoMo với QR Code
class _MoMoPaymentSheet extends StatefulWidget {
  final MoMoPaymentResult momoResult;
  final VoidCallback onOpenApp;
  final VoidCallback onOpenWeb;
  final VoidCallback onClose;

  const _MoMoPaymentSheet({
    required this.momoResult,
    required this.onOpenApp,
    required this.onOpenWeb,
    required this.onClose,
  });

  @override
  State<_MoMoPaymentSheet> createState() => _MoMoPaymentSheetState();
}

class _MoMoPaymentSheetState extends State<_MoMoPaymentSheet> {
  bool _showQR = false;

  String _formatAmount(String? amount) {
    if (amount == null) return '0đ';
    final value = double.tryParse(amount) ?? 0;
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    const momoColor = Color(0xFFAE2070);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // MoMo Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [momoColor, momoColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thanh toán MoMo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Đơn hàng #${widget.momoResult.orderId} đã tạo',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Số tiền
                  Text(
                    _formatAmount(widget.momoResult.amount),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: momoColor,
                    ),
                  ),
                ],
              ),
            ),

            // QR Code Section (expandable)
            if (widget.momoResult.qrCodeUrl != null) ...[
              Divider(height: 1, color: Colors.grey[200]),
              InkWell(
                onTap: () => setState(() => _showQR = !_showQR),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.qr_code_2, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Quét mã QR để thanh toán',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        _showQR
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              // QR Code
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _showQR
                    ? Container(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: widget.momoResult.qrCodeUrl!,
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFFAE2070),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Mở app MoMo → Quét mã',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],

            Divider(height: 1, color: Colors.grey[200]),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Nút mở app MoMo
                  if (widget.momoResult.deeplink != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onOpenApp,
                        icon: const Icon(
                          Icons.phone_android,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Mở ứng dụng MoMo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: momoColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Row với 2 nút nhỏ
                  Row(
                    children: [
                      // Nút thanh toán web
                      if (widget.momoResult.payUrl != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onOpenWeb,
                            icon: Icon(Icons.language, color: momoColor),
                            label: Text(
                              'Thanh toán web',
                              style: TextStyle(color: momoColor),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: momoColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (widget.momoResult.payUrl != null)
                        const SizedBox(width: 12),
                      // Nút để sau
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onClose,
                          child: Text(
                            'Thanh toán sau',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
