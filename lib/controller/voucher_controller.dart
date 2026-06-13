import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/voucher_model.dart';

class AppliedVoucher {
  final VoucherModel voucher;
  final double discountAmount;

  const AppliedVoucher({required this.voucher, required this.discountAmount});
}

class ControllerVoucher extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find();

  final adminVouchers = <VoucherModel>[].obs;
  final availableVouchers = <VoucherModel>[].obs;
  final appliedVoucher = Rx<AppliedVoucher?>(null);
  final isLoading = false.obs;
  final isApplying = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(authController.currentUser, (_) {
      clearAppliedVoucher();
      fetchAvailableVouchers();
    });
    fetchAvailableVouchers();
  }

  Future<void> fetchAdminVouchers() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('vouchers')
          .select()
          .order('created_at', ascending: false);

      adminVouchers.value = (response as List)
          .map((json) => VoucherModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching admin vouchers: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách voucher',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createVoucher(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      await supabase.from('vouchers').insert(data);
      await _refreshVoucherLists();
      Get.snackbar(
        'Thành công',
        'Đã tạo voucher',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error creating voucher: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tạo voucher',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateVoucher(
    String voucherId,
    Map<String, dynamic> data,
  ) async {
    try {
      isLoading.value = true;
      await supabase.from('vouchers').update(data).eq('id', voucherId);
      await _refreshVoucherLists();
      Get.snackbar(
        'Thành công',
        'Đã cập nhật voucher',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error updating voucher: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật voucher',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteVoucher(String voucherId) async {
    try {
      isLoading.value = true;
      await supabase.from('vouchers').delete().eq('id', voucherId);
      await _refreshVoucherLists();
      Get.snackbar(
        'Thành công',
        'Đã xóa voucher',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting voucher, deactivating instead: $e');
      try {
        await supabase
            .from('vouchers')
            .update({'is_active': false})
            .eq('id', voucherId);
        await _refreshVoucherLists();
        Get.snackbar(
          'Đã tắt voucher',
          'Voucher đã có đơn sử dụng nên không xóa cứng được',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return true;
      } catch (fallbackError) {
        debugPrint('Error deactivating voucher: $fallbackError');
        Get.snackbar(
          'Lỗi',
          'Không thể xóa voucher',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshVoucherLists() async {
    await fetchAdminVouchers();
    await fetchAvailableVouchers();
  }

  Future<void> fetchAvailableVouchers() async {
    try {
      isLoading.value = true;
      final response = await supabase
          .from('vouchers')
          .select()
          .order('created_at', ascending: false);

      availableVouchers.value = (response as List)
          .map((json) => VoucherModel.fromJson(json))
          .where((voucher) => voucher.canUse)
          .toList();
    } catch (e) {
      debugPrint('Error fetching available vouchers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> applyVoucherCode(String rawCode, double subtotal) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập mã giảm giá',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (!authController.isLoggedIn) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng đăng nhập để dùng mã giảm giá',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      isApplying.value = true;
      final voucherResponse = await supabase
          .from('vouchers')
          .select()
          .ilike('code', code)
          .maybeSingle();

      if (voucherResponse == null) {
        _showVoucherError('Mã giảm giá không tồn tại hoặc đã hết hiệu lực');
        return false;
      }

      final voucher = VoucherModel.fromJson(voucherResponse);
      final validationMessage = validateVoucher(voucher, subtotal);
      if (validationMessage != null) {
        _showVoucherError(validationMessage);
        return false;
      }

      final hasUsed = await hasUserUsedVoucher(voucher.id);
      if (hasUsed) {
        _showVoucherError('Bạn đã sử dụng mã giảm giá này');
        return false;
      }

      final discount = calculateDiscount(voucher, subtotal);
      if (discount <= 0) {
        _showVoucherError('Mã giảm giá không áp dụng được cho đơn hàng này');
        return false;
      }

      appliedVoucher.value = AppliedVoucher(
        voucher: voucher,
        discountAmount: discount,
      );

      Get.snackbar(
        'Thành công',
        'Đã áp dụng mã ${voucher.code}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error applying voucher: $e');
      _showVoucherError('Không thể áp dụng mã giảm giá');
      return false;
    } finally {
      isApplying.value = false;
    }
  }

  Future<bool> applyVoucher(VoucherModel voucher, double subtotal) async {
    final validationMessage = validateVoucher(voucher, subtotal);
    if (validationMessage != null) {
      _showVoucherError(validationMessage);
      return false;
    }

    final hasUsed = await hasUserUsedVoucher(voucher.id);
    if (hasUsed) {
      _showVoucherError('Bạn đã sử dụng mã giảm giá này');
      return false;
    }

    final discount = calculateDiscount(voucher, subtotal);
    if (discount <= 0) {
      _showVoucherError('Mã giảm giá không áp dụng được cho đơn hàng này');
      return false;
    }

    appliedVoucher.value = AppliedVoucher(
      voucher: voucher,
      discountAmount: discount,
    );
    return true;
  }

  String? validateVoucher(VoucherModel voucher, double subtotal) {
    if (!voucher.canUse) {
      return 'Mã giảm giá đã hết hạn hoặc hết lượt sử dụng';
    }
    if (subtotal < voucher.minOrderAmount) {
      return 'Đơn hàng tối thiểu ${voucher.minOrderAmount.toStringAsFixed(0)}đ để dùng mã này';
    }
    return null;
  }

  Future<bool> hasUserUsedVoucher(String voucherId) async {
    if (!authController.isLoggedIn) return false;

    try {
      final response = await supabase
          .from('orders')
          .select('id')
          .eq('user_id', authController.currentUser.value!.id)
          .eq('voucher_id', voucherId)
          .neq('status', 'cancelled')
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking voucher usage: $e');
      return false;
    }
  }

  double calculateDiscount(VoucherModel voucher, double subtotal) {
    if (voucher.discountType == DiscountType.percent) {
      final percentDiscount = subtotal * voucher.discountValue / 100;
      final cappedDiscount = voucher.maxDiscount == null
          ? percentDiscount
          : min(percentDiscount, voucher.maxDiscount!);
      return min(cappedDiscount, subtotal);
    }

    return min(voucher.discountValue, subtotal);
  }

  void clearAppliedVoucher() {
    appliedVoucher.value = null;
  }

  void _showVoucherError(String message) {
    Get.snackbar(
      'Không áp dụng được mã',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
