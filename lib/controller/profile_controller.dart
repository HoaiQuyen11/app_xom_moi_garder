// lib/controller/controller_profile.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/loyalty_transaction_model.dart';

class ControllerProfile extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find();

  var isLoading = false.obs;
  var loyaltyTransactions = <LoyaltyTransactionModel>[].obs;
  var isLoadingLoyalty = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(authController.currentUser, (_) {
      if (authController.isLoggedIn) {
        fetchLoyaltyTransactions();
      } else {
        loyaltyTransactions.clear();
      }
    });
    if (authController.isLoggedIn) fetchLoyaltyTransactions();
  }

  Future<void> refreshProfile() async {
    final userId = authController.currentUser.value?.id;
    if (userId == null) return;
    await authController.fetchUserProfile(userId);
    await fetchLoyaltyTransactions();
  }

  Future<void> fetchLoyaltyTransactions() async {
    if (!authController.isLoggedIn) return;

    try {
      isLoadingLoyalty.value = true;
      final userId = authController.currentUser.value!.id;
      final response = await supabase
          .from('loyalty_transactions')
          .select('*, orders(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      loyaltyTransactions.value = (response as List)
          .map((json) => LoyaltyTransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching loyalty transactions: $e');
    } finally {
      isLoadingLoyalty.value = false;
    }
  }

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

      await supabase.from('users').update(updates).eq('id', userId);

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
        isAvailable
            ? 'Đã bật trạng thái nhận đơn'
            : 'Đã tắt trạng thái nhận đơn',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      debugPrint('Error updating shipper status: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái');
    } finally {
      isLoading.value = false;
    }
  }
}
