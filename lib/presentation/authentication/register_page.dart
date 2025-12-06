import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/text_field_app.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _agree = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    "Quay lại",
                    style: context.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Gap.sm),
                child: const Icon(
                  Icons.favorite,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              Text(
                "Tạo tài khoản mới",
                style: context.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              Text(
                "Đăng ký để trải nghiệm dịch vụ",
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
              ),

              Gap.mLHeight,

              // Form chính
              Container(
                margin: EdgeInsets.only(bottom: Gap.md),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
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
                        labelText: "Họ và tên *",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      Gap.sMHeight,

                      // Số điện thoại
                      TextFieldApp(
                        labelText: "Số điện thoại *",
                        prefixIcon: Icon(Icons.phone_android_outlined),
                        keyboardType: TextInputType.phone,
                      ),
                      Gap.mdHeight,

                      // Checkbox đồng ý
                      Row(
                        children: [
                          Checkbox(
                            activeColor: primaryColor,
                            checkColor: Colors.white,
                            value: _agree,
                            onChanged: (value) {
                              setState(() {
                                _agree = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Wrap(
                              children: [
                                const Text("Tôi đồng ý với "),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    "Điều khoản sử dụng",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Text(" và "),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    "Chính sách bảo mật",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Gap.smHeight,
                      // Nút đăng ký
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ButtonApp(
                          onPressed: _agree ? () {} : null,
                          child: const Text("Đăng ký"),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Đăng nhập
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Đã có tài khoản? "),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Đăng nhập ngay",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
