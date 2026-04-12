// lib/views/user/verify_otp_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/user_model.dart';
import 'package:xommoigarden/views/user/my_home_page.dart';
import 'login_page.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;
  final bool isRegister;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  const VerifyOtpPage({
    super.key,
    required this.email,
    this.isRegister = false,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final RxBool isLoading = false.obs;
  final primaryColor = Colors.green.shade700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Xác minh OTP", style: TextStyle(color: primaryColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Get.offAll(() => const LoginPage()),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, color: primaryColor, size: 60),
            const SizedBox(height: 16),
            Text(
              "Nhập mã OTP đã gửi đến",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            OtpTextField(
              numberOfFields: 6,
              borderRadius: BorderRadius.circular(10),
              focusedBorderColor: primaryColor,
              cursorColor: primaryColor,
              borderColor: Colors.grey.shade400,
              showFieldAsBox: true,
              fieldWidth: 45,
              onSubmit: (code) async {
                await _verifyOTP(code);
              },
            ),

            const SizedBox(height: 40),

            Obx(
              () => ElevatedButton(
                onPressed: isLoading.value ? null : _resendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text("Gửi lại mã OTP"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOTP(String code) async {
    isLoading.value = true;

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.email,
      );

      if (response.user != null) {
        await _handleVerifySuccess(response.user!.id);
      } else {
        Get.snackbar(
          'Lỗi',
          'Mã OTP không chính xác',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Verify OTP error: $e');
      Get.snackbar(
        'Lỗi',
        'Xác thực thất bại',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleVerifySuccess(String userId) async {
    try {
      // Kiểm tra user đã có trong bảng users chưa
      final existingUser = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingUser == null && widget.isRegister) {
        // Lấy metadata từ auth nếu có, ưu tiên dữ liệu đã chuyển từ màn hình đăng ký
        final userMetadata =
            Supabase.instance.client.auth.currentUser?.userMetadata
                as Map<String, dynamic>?;
        final fullName =
            widget.fullName ?? userMetadata?['full_name'] as String? ?? '';
        final phone = widget.phone ?? userMetadata?['phone'] as String? ?? '';
        final avatarUrl =
            widget.avatarUrl ?? userMetadata?['avatar_url'] as String? ?? '';

        // Tạo user mới khi đăng ký
        await Supabase.instance.client.from('users').insert({
          'id': userId,
          'email': widget.email,
          'full_name': fullName,
          'phone': phone,
          'avatar_url': avatarUrl,
          'role': 'customer',
          'status': 'active',
        });
      }

      // Lấy thông tin user
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userData != null) {
        final user = UserModel.fromJson(userData);
        final authController = Get.find<ControllerAuth>();
        authController.currentUser.value = user;

        Get.offAll(() => const MyHomePage());

        Get.snackbar(
          'Thành công',
          widget.isRegister ? 'Đăng ký thành công!' : 'Đăng nhập thành công!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.offAll(() => const LoginPage());
      }
    } catch (e) {
      print('Handle verify success error: $e');
      Get.offAll(() => const LoginPage());
    }
  }

  Future<void> _resendOTP() async {
    isLoading.value = true;

    try {
      await Supabase.instance.client.auth.signInWithOtp(email: widget.email);

      Get.snackbar(
        'Thành công',
        'OTP đã gửi đến ${widget.email}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Resend OTP error: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể gửi lại mã OTP',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
