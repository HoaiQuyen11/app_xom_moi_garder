// lib/views/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;
  final RxBool isAcceptedTerms = false.obs;
  final RxBool isLoading = false.obs;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
                constraints: const BoxConstraints(maxWidth: 480),
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
                      child: const Icon(Icons.person_add, color: Colors.white, size: 64),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Tham gia cùng chúng tôi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tạo tài khoản để nhận ưu đãi và giao hàng nhanh',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _brandFeature(Icons.card_giftcard, 'Ưu đãi thành viên'),
                    const SizedBox(height: 14),
                    _brandFeature(Icons.loyalty, 'Tích điểm đổi quà'),
                    const SizedBox(height: 14),
                    _brandFeature(Icons.history, 'Lưu lịch sử đơn hàng'),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add, size: 36, color: primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Đăng ký',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Tạo tài khoản mới',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 22),

              // Responsive fields: 2 cột trên wide, 1 cột trên narrow
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 420;
                  if (twoColumns) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildFullNameField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildPhoneField()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildEmailField(),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPasswordField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildConfirmPasswordField()),
                          ],
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildFullNameField(),
                      const SizedBox(height: 14),
                      _buildPhoneField(),
                      const SizedBox(height: 14),
                      _buildEmailField(),
                      const SizedBox(height: 14),
                      _buildPasswordField(),
                      const SizedBox(height: 14),
                      _buildConfirmPasswordField(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),

              // Terms checkbox
              Obx(() => Row(
                    children: [
                      Checkbox(
                        value: isAcceptedTerms.value,
                        onChanged: (value) => isAcceptedTerms.value = value ?? false,
                        activeColor: primaryColor,
                      ),
                      Expanded(
                        child: Text(
                          'Tôi đồng ý với điều khoản sử dụng',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 16),

              // Register button
              Obx(() => SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (isLoading.value || !isAcceptedTerms.value)
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await _handleRegister();
                              }
                            },
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
                          : const Text('Đăng ký', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  )),
              const SizedBox(height: 14),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Đã có tài khoản? ', style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Đăng nhập',
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullNameField() {
    return TextFormField(
      controller: fullNameController,
      decoration: _inputDecoration('Họ và tên *', Icons.person_outline),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập họ tên';
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      decoration: _inputDecoration('Số điện thoại *', Icons.phone_outlined),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập SĐT';
        if (value.length < 10) return 'SĐT không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration('Email *', Icons.email_outlined),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Vui lòng nhập email';
        if (!value.contains('@')) return 'Email không hợp lệ';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return Obx(() => TextFormField(
          controller: passwordController,
          obscureText: isPasswordHidden.value,
          decoration: _inputDecoration(
            'Mật khẩu *',
            Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(isPasswordHidden.value ? Icons.visibility_off : Icons.visibility),
              onPressed: () => isPasswordHidden.toggle(),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
            if (value.length < 6) return 'Ít nhất 6 ký tự';
            return null;
          },
        ));
  }

  Widget _buildConfirmPasswordField() {
    return Obx(() => TextFormField(
          controller: confirmPasswordController,
          obscureText: isConfirmPasswordHidden.value,
          decoration: _inputDecoration(
            'Xác nhận mật khẩu *',
            Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(isConfirmPasswordHidden.value ? Icons.visibility_off : Icons.visibility),
              onPressed: () => isConfirmPasswordHidden.toggle(),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
            if (value != passwordController.text) return 'Mật khẩu không khớp';
            return null;
          },
        ));
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

  // ==================== HANDLER ====================
  Future<void> _handleRegister() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final fullName = fullNameController.text;
    final phone = phoneController.text;

    isLoading.value = true;
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      if (response.user != null) {
        await Supabase.instance.client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': 'customer',
          'status': 'active',
          'loyalty_points': 0,
          'is_available': false,
          'shipper_rating': 5.0,
          'total_deliveries': 0,
        });

        Get.snackbar(
          'Thành công',
          'Đăng ký thành công! Vui lòng đăng nhập.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAll(() => const LoginPage());
      }
    } catch (e) {
      print('Register error: $e');
      Get.snackbar(
        'Lỗi',
        'Đăng ký thất bại. Email có thể đã được sử dụng.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
