// lib/controller/controller_address.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/address_model.dart';


class ControllerAddress extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find();

  var addresses = <AddressModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(authController.currentUser, (_) {
      if (authController.isLoggedIn) {
        fetchAddresses();
      }
    });
  }

  Future<void> fetchAddresses() async {
    if (!authController.isLoggedIn) return;

    try {
      isLoading.value = true;

      final response = await supabase
          .from('addresses')
          .select()
          .eq('user_id', authController.currentUser.value!.id)
          .order('is_default', ascending: false);

      addresses.value = (response as List)
          .map((json) => AddressModel.fromJson(json))
          .toList();

    } catch (e) {
      print('Error fetching addresses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addAddress(String fullAddress, double? lat, double? lng) async {
    try {
      await supabase.from('addresses').insert({
        'user_id': authController.currentUser.value!.id,
        'full_address': fullAddress,
        'lat': lat,
        'lng': lng,
      });

      await fetchAddresses();

      Get.snackbar('Thành công', 'Đã thêm địa chỉ');

    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể thêm địa chỉ');
    }
  }
}