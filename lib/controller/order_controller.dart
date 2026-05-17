// lib/controller/order_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/order_item_model.dart';
import 'package:xommoigarden/model/order_model.dart';
import 'auth_controller.dart';
import 'cart_controller.dart';

class ControllerOrder extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find();
  final ControllerCart cartController = Get.find();

  var orders = <OrderModel>[].obs;
  var currentOrder = Rx<OrderModel?>(null);
  var orderItems = <OrderItemModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(authController.currentUser, (_) {
      if (authController.isLoggedIn) fetchOrders();
    });
    if (authController.isLoggedIn) fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (!authController.isLoggedIn) return;
    try {
      isLoading.value = true;
      final response = await supabase
          .from('orders')
          .select('*, addresses(*)')
          .eq('user_id', authController.currentUser.value!.id)
          .order('created_at', ascending: false);

      orders.value = (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createOrder({
    required String addressId,
    required PaymentMethod paymentMethod,
    DeliveryType deliveryType = DeliveryType.delivery,
    double shippingFee = 0,
    String note = '',
  }) async {
    if (cartController.cartItems.isEmpty) {
      Get.snackbar('Lỗi', 'Giỏ hàng trống',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (!authController.isLoggedIn) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (addressId.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn địa chỉ giao hàng',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    try {
      isLoading.value = true;

      final double subtotal = cartController.totalAmount;
      final double totalAmount = subtotal + shippingFee;

      final orderResponse = await supabase
          .from('orders')
          .insert({
            'user_id': authController.currentUser.value!.id,
            'address_id': addressId,
            'delivery_type': deliveryType.value,
            'note': note,
            'subtotal': subtotal,
            'shipping_fee': shippingFee,
            'discount_amount': 0,
            'total_amount': totalAmount,
            'payment_method': paymentMethod.value,
            'status': 'pending',
            'payment_status': 'pending',
          })
          .select()
          .single();

      final orderId = orderResponse['id'];
      final orderCode = orderResponse['order_code'] ?? orderId.toString().substring(0, 8).toUpperCase();

      for (var item in cartController.cartItems) {
        await supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.product?.name,
          'quantity': item.quantity,
          'price': item.priceAtTime,
          'options': item.options,
        });
      }

      await cartController.clearCart();

      Get.snackbar(
        'Đặt hàng thành công!',
        'Mã đơn: $orderCode',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      await fetchOrders();
      return true;
    } catch (e) {
      print('Error creating order: $e');
      Get.snackbar(
        'Lỗi tạo đơn hàng',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOrderDetail(String orderId) async {
    try {
      isLoading.value = true;
      currentOrder.value = null;
      orderItems.clear();

      final orderResponse = await supabase
          .from('orders')
          .select('*, addresses(*), customer:users!user_id(*)')
          .eq('id', orderId)
          .single();

      currentOrder.value = OrderModel.fromJson(orderResponse);

      final itemsResponse = await supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId);

      orderItems.value = (itemsResponse as List)
          .map((json) => OrderItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching order detail: $e');
      Get.snackbar('Lỗi', 'Không tải được chi tiết đơn: $e',
          backgroundColor: Colors.red, colorText: Colors.white,
          duration: const Duration(seconds: 4));
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final updateData = <String, dynamic>{'status': 'cancelled'};
      if (reason != null && reason.isNotEmpty) {
        updateData['cancel_reason'] = reason;
      }
      await supabase.from('orders').update(updateData).eq('id', orderId);
      await fetchOrders();
      Get.snackbar('Thành công', 'Đã hủy đơn hàng',
          backgroundColor: Colors.green, colorText: Colors.white);
      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      Get.snackbar('Lỗi', 'Không thể hủy đơn hàng',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }
}
