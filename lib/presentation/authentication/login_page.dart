import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/text_field_app.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/home_screen.dart';
import 'package:pharmacy_app/presentation/authentication/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.favorite, size: 80, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                "Nhà thuốc Long Châu",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Chăm sóc sức khỏe toàn diện",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // CARD LOGIN
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 8),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Đăng nhập",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFieldApp(
                      controller: emailController,
                      labelText: "Email",
                      hintText: "Nhập email của bạn",
                    ),
                    const SizedBox(height: 16),

                    TextFieldApp(
                      controller: passwordController,
                      hintText: 'Nhập mật khẩu',
                      labelText: 'Mật khẩu',
                      obscureText: isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => isPasswordVisible = !isPasswordVisible,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Quên mật khẩu?",
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ),

                    Gap.smHeight,
                    ButtonApp(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      },
                      child: const Text("Đăng nhập"),
                    ),
                    Gap.mdHeight,

                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Gap.sm),
                          child: Text("hoặc"),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    Gap.sMHeight,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Chưa có tài khoản?  "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Đăng ký ngay",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Bằng cách đăng nhập, bạn đồng ý với Điều khoản sử dụng của chúng tôi",
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
