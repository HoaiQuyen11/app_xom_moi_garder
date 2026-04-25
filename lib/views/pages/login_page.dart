// lib/views/pages/login_page.dart
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
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return isWide ? _buildWideLayout() : _buildNarrowLayout();
        },
      ),
    );
  }

  // ==================== MOBILE / TABLET ====================
  Widget _buildNarrowLayout() {
    return SafeArea(
      child: Stack(
        children: [
          // Back button
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildFormCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP / WEB ====================
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left branding
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, Colors.green.shade900],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 64),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Xóm Mới Garden',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tươi mới mỗi ngày — giao tận nhà',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _brandFeature(Icons.local_shipping, 'Giao nhanh trong 30 phút'),
                    const SizedBox(height: 14),
                    _brandFeature(Icons.eco_outlined, 'Sản phẩm tươi sạch'),
                    const SizedBox(height: 14),
                    _brandFeature(Icons.support_agent, 'Hỗ trợ 24/7'),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right form
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildFormCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _brandFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
        ),
      ],
    );
  }

  // ==================== FORM CARD ====================
  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, color: primaryColor, size: 56),
            const SizedBox(height: 12),
            Text(
              'Đăng nhập',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Chào mừng quay lại!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email', Icons.email_outlined),
            ),
            const SizedBox(height: 14),

            Obx(() => TextField(
                  controller: passwordController,
                  obscureText: isPasswordHidden.value,
                  decoration: _inputDecoration(
                    'Mật khẩu',
                    Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordHidden.value ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => isPasswordHidden.toggle(),
                    ),
                  ),
                )),
            const SizedBox(height: 22),

            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading.value ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                )),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Chưa có tài khoản? ', style: TextStyle(color: Colors.grey.shade600)),
                TextButton(
                  onPressed: () => Get.to(() => const RegisterPage()),
                  child: Text(
                    'Đăng ký ngay',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  // ==================== HANDLERS ====================
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
      final existingUser = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingUser == null) {
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
