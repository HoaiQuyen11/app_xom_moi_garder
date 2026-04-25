// lib/controller/controller_auth.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/user_model.dart';
import 'package:xommoigarden/views/user/my_home_page.dart';


class ControllerAuth extends GetxController {
  final supabase = Supabase.instance.client;

  var currentUser = Rx<UserModel?>(null);
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Lắng nghe thay đổi đăng nhập
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;

      if (session != null) {
        await fetchUserProfile(session.user.id);
      } else {
        currentUser.value = null;
      }
    });

    checkAuthStatus();
  }

  // Kiểm tra trạng thái đăng nhập
  Future<void> checkAuthStatus() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      await fetchUserProfile(session.user.id);
    }
  }

  // Lấy thông tin user profile
  Future<void> fetchUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      currentUser.value = UserModel.fromJson(response);

    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  // Đăng nhập
  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await fetchUserProfile(response.user!.id);

      Get.snackbar('Thành công', 'Đăng nhập thành công');
      return true;

    } catch (e) {
      Get.snackbar('Lỗi', 'Sai email hoặc mật khẩu');
      return false;

    } finally {
      isLoading.value = false;
    }
  }

  // Đăng ký
  Future<bool> register(String email, String password, String fullName, String phone) async {
    try {
      isLoading.value = true;

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        Get.snackbar('Thành công', 'Đăng ký thành công, vui lòng đăng nhập');
        return true;
      }

      return false;

    } catch (e) {
      Get.snackbar('Lỗi', 'Đăng ký thất bại');
      return false;

    } finally {
      isLoading.value = false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await supabase.auth.signOut();
    currentUser.value = null;
    Get.offAll(() => const MyHomePage());
    Get.snackbar('Thành công', 'Đã đăng xuất');
  }

  // Kiểm tra đã đăng nhập chưa
  bool get isLoggedIn => currentUser.value != null;

  // Kiểm tra role
  bool get isAdmin => currentUser.value?.role == 'admin';
  bool get isShipper => currentUser.value?.role == 'shipper';
}