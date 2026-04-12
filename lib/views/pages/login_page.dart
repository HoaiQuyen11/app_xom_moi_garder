// lib/views/user/login_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/user_model.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/views/admin/admin_dashboard.dart';
import 'package:xommoigarden/views/user/my_home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordHidden = true.obs;
  final RxBool isLoading = false.obs;

  final primaryColor = Colors.green.shade700;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Đăng nhập",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.storefront_rounded, color: primaryColor, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      "Xóm mới GarDen",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    Obx(() => TextField(
                      controller: passwordController,
                      obscureText: isPasswordHidden.value,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordHidden.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            isPasswordHidden.toggle();
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    )),
                    const SizedBox(height: 24),

                    // Login button
                    Obx(() => ElevatedButton(
                      onPressed: isLoading.value
                          ? null
                          : () => _handleLogin(),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Đăng nhập',
                        style: TextStyle(fontSize: 16),
                      ),
                    )),
                    const SizedBox(height: 16),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.to(() => const RegisterPage());
                          },
                          child: Text(
                            'Đăng ký ngay',
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
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập email');
      return;
    }

    if (password.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập mật khẩu');
      return;
    }

    isLoading.value = true;

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _handleLoginSuccess(response.user!.id, email);
      }
    } catch (e) {
      print('Login error: $e');
      Get.snackbar(
        'Lỗi',
        'Sai email hoặc mật khẩu',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleLoginSuccess(String userId, String email) async {
    try {
      // Kiểm tra user đã có trong bảng users chưa
      final existingUser = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingUser == null) {
        // Tạo user mới nếu chưa có
        await Supabase.instance.client.from('users').insert({
          'id': userId,
          'email': email,
          'full_name': '',
          'phone': '',
          'role': 'customer',
          'status': 'active',
          'loyalty_points': 0,
          'is_available': false,
          'shipper_rating': 5.0,
          'total_deliveries': 0,
        });
      }

      // Lấy thông tin user
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final user = UserModel.fromJson(userData);
      final authController = Get.find<ControllerAuth>();
      authController.currentUser.value = user;

      if (user.role == UserRole.admin) {
        Get.offAll(() => const AdminDashboard());
      } else {
        Get.offAll(() => const MyHomePage());
      }

      Get.snackbar(
        'Thành công',
        'Đăng nhập thành công',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Handle login success error: $e');
    }
  }
}