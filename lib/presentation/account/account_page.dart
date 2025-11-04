import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/presentation/account/edit_profile_page.dart';
import 'package:pharmacy_app/presentation/order/order_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Tài khoản của tôi',
          style: context.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        leadingWidth: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2979FF), Color(0xFF448AFF)],
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
                  const CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=3',
                    ),
                  ),
                  Gap.mdWidth,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nguyễn Văn A',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Khách hàng thân thiết',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/square-pen.svg',
                    width: Gap.md,
                    height: Gap.md,
                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
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
                  _infoRow(context, Icons.person, 'Họ và tên', 'Nguyễn Văn A'),
                  _infoRow(context, Icons.phone, 'Số điện thoại', '0901234567'),
                  _infoRow(
                    context,
                    Icons.location_on,
                    'Địa chỉ',
                    '123 Đường ABC, Quận 1, TP.HCM',
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
                      );
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
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: Gap.sM),
                  shape: RoundedRectangleBorder(borderRadius: radius12),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
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
