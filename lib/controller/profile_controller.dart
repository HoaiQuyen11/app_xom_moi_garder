// lib/controller/controller_profile.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';


class ControllerProfile extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find();

  var isLoading = false.obs;

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      isLoading.value = true;

      final userId = authController.currentUser.value!.id;
      final updates = <String, dynamic>{};

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await supabase
          .from('users')
          .update(updates)
          .eq('id', userId);

      await authController.fetchUserProfile(userId);

      Get.snackbar('Thành công', 'Cập nhật thông tin thành công');

    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật thông tin');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateShipperStatus(bool isAvailable) async {
    try {
      isLoading.value = true;

      final userId = authController.currentUser.value!.id;

      await supabase
          .from('users')
          .update({'is_available': isAvailable})
          .eq('id', userId);

      await authController.fetchUserProfile(userId);

      Get.snackbar(
        'Thành công',
        isAvailable ? 'Đã bật trạng thái nhận đơn' : 'Đã tắt trạng thái nhận đơn',
        snackPosition: SnackPosition.TOP,
      );

    } catch (e) {
      print('Error updating shipper status: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái');
    } finally {
      isLoading.value = false;
    }
  }
}