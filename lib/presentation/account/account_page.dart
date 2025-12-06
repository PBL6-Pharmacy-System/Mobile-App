import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/optimized_image.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/presentation/account/edit_profile_page.dart';
import 'package:pharmacy_app/presentation/order/order_page.dart';
import 'package:pharmacy_app/services/auth_service.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthService _authService = AuthService();
  bool _isLoggingOut = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Fetch fresh user data khi vào trang
    _refreshUserData();
  }

  Future<void> _refreshUserData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUser();
    } catch (e) {
      print('❌ Error refreshing user: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // Hiển thị dialog xác nhận
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (mounted) {
        // Cập nhật auth state trong provider nếu có
        final authProvider = context.read<AuthProvider>();
        authProvider.logout();

        // Navigate về trang login hoặc home
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng xuất thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          'Tài khoản của tôi',
          style: context.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leadingWidth: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshUserData,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryLightColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  OptimizedAvatar(
                    imageUrl: user?.avatar,
                    radius: 32,
                    backgroundColor: Colors.grey[200],
                  ),
                  Gap.mdWidth,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName
                              : (user?.username ?? 'Chưa cập nhật'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          user?.isCustomer == true
                              ? 'Khách hàng'
                              : (user?.role ?? 'Người dùng'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(),
                        ),
                      ).then((_) => _refreshUserData());
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: SvgPicture.asset(
                        'assets/images/square-pen.svg',
                        width: Gap.md,
                        height: Gap.md,
                        colorFilter: ColorFilter.mode(
                          Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin cá nhân
            Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius16,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin cá nhân',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Gap.sMHeight,
                  _infoRow(
                    context,
                    Icons.person,
                    'Họ và tên',
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName
                        : 'Chưa cập nhật',
                  ),
                  _infoRow(
                    context,
                    Icons.email,
                    'Email',
                    user?.email.isNotEmpty == true
                        ? user!.email
                        : 'Chưa cập nhật',
                  ),
                  _infoRow(
                    context,
                    Icons.phone,
                    'Số điện thoại',
                    user?.phoneNumber?.isNotEmpty == true
                        ? user!.phoneNumber!
                        : 'Chưa cập nhật',
                  ),
                  Gap.sMHeight,
                  ButtonApp(
                    child: Text('Cập nhật thông tin'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(),
                        ),
                      ).then((_) => _refreshUserData());
                    },
                  ),
                ],
              ),
            ),

            Gap.mdHeight,

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: radius16,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 8),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.history, color: primaryColor),
                title: const Text('Lịch sử mua hàng'),
                trailing: const Icon(Icons.arrow_forward_ios, size: Gap.md),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Đăng xuất
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: Gap.sM),
                  shape: RoundedRectangleBorder(borderRadius: radius12),
                ),
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sM),
      child: Row(
        spacing: Gap.sM,
        children: [
          Icon(icon, color: primaryColor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: textColor,
                  ),
                ),
                Text(value, style: context.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
