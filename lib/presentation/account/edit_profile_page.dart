import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/outline_button_app.dart';
import 'package:pharmacy_app/common/widgets/text_field_app.dart';
import 'package:pharmacy_app/configs/common.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(
    text: "Nguyễn Văn A",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "myam@gmail.com",
  );
  final TextEditingController _phoneController = TextEditingController(
    text: "0901234567",
  );
  final TextEditingController _addressController = TextEditingController(
    text: "123 Đường ABC, Quận 1, TP.HCM",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: "Danh mục",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: "Giỏ hàng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: "Tư vấn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Tài khoản",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Chỉnh sửa thông tin",
                    style: context.textTheme.titleSmall,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Ảnh đại diện
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Text(
                          "N",
                          style: TextStyle(
                            fontSize: 40,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: radius20,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap.smHeight,
                  const Text(
                    "Nhấn để thay đổi ảnh đại diện",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              Gap.mLHeight,

              // Form thông tin cá nhân
              Container(
                padding: const EdgeInsets.all(Gap.mL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Họ và tên
                      TextFieldApp(
                        controller: _nameController,
                        labelText: "Họ và tên *",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      Gap.sMHeight,

                      // Email
                      TextFieldApp(
                        controller: _emailController,
                        labelText: "Email *",
                        prefixIcon: Icon(Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      Gap.sMHeight,

                      // Số điện thoại
                      TextFieldApp(
                        controller: _phoneController,
                        labelText: "Số điện thoại *",
                        prefixIcon: Icon(Icons.phone_android_outlined),
                        keyboardType: TextInputType.phone,
                      ),
                      Gap.sMHeight,

                      // Địa chỉ
                      TextFieldApp(
                        controller: _addressController,
                        labelText: "Địa chỉ *",
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      Gap.mLHeight,

                      Row(
                        spacing: Gap.md,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlineButtonApp(
                              onPressed: () {},
                              child: const Text("Hủy"),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: ButtonApp(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                              ),
                              child: const Text("Lưu thay đổi"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Gap.mLHeight,

              // Xóa tài khoản
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Xóa tài khoản",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
