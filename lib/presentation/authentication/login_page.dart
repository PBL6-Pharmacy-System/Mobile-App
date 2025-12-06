import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_app/common/widgets/button_app.dart';
import 'package:pharmacy_app/common/widgets/text_field_app.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/extensions.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/presentation/authentication/otp_verification_page.dart';
import 'package:pharmacy_app/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: isError ? Colors.red : Colors.green,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  Future<void> _handleSendOTP() async {
    final input = phoneController.text.trim();

    if (input.isEmpty) {
      _showMessage('Vui lòng nhập số điện thoại hoặc email', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _showMessage('Đang gửi mã OTP...');

    // Detect if input is email or phone
    final bool isEmail = input.contains('@');
    final result = await authProvider.requestOTP(
      phone: isEmail ? null : input,
      email: isEmail ? input : null,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _showMessage('Mã OTP đã được gửi!');

      // Navigate to OTP verification page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(
            phoneNumber: isEmail ? null : input,
            email: isEmail ? input : null,
          ),
        ),
      );
    } else {
      _showMessage(result['message'] ?? 'Không thể gửi OTP', isError: true);
    }
  }

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

                    const Text(
                      "Nhập số điện thoại hoặc email để nhận mã OTP",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: greyColor),
                    ),
                    const SizedBox(height: 20),

                    TextFieldApp(
                      controller: phoneController,
                      labelText: "Số điện thoại / Email",
                      hintText: "Nhập SĐT hoặc email",
                      prefixIcon: const Icon(Icons.phone_android),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 24),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return ButtonApp(
                          onPressed: authProvider.isLoading
                              ? null
                              : _handleSendOTP,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Gửi mã OTP"),
                        );
                      },
                    ),

                    Gap.mdHeight,
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
