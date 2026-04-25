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
      if (authController.isLoggedIn) {
        fetchOrders();
      }
    });
    // Fetch ngay nếu user đã đăng nhập sẵn
    if (authController.isLoggedIn) {
      fetchOrders();
    }
  }

  // Lấy danh sách đơn hàng
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

  // Tạo đơn hàng mới
  Future<bool> createOrder({
    required String addressId,
    required PaymentMethod paymentMethod,
    required ShippingMethod shippingMethod,
    double? shippingFee,
    String note = '',
  }) async {
    // Kiểm tra giỏ hàng
    if (cartController.cartItems.isEmpty) {
      Get.snackbar('Lỗi', 'Giỏ hàng trống', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    // Kiểm tra đăng nhập
    if (!authController.isLoggedIn) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    // Kiểm tra địa chỉ
    if (addressId.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn địa chỉ giao hàng', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    try {
      isLoading.value = true;

      // Tính toán giá trị
      double subtotal = cartController.totalAmount;
      double finalShippingFee = shippingFee ?? shippingMethod.fee;
      double totalAmount = subtotal + finalShippingFee;

      print('=== TẠO ĐƠN HÀNG ===');
      print('User ID: ${authController.currentUser.value!.id}');
      print('Address ID: $addressId');
      print('Subtotal: $subtotal');
      print('Shipping Fee: $finalShippingFee');
      print('Total: $totalAmount');
      print('Payment Method: ${paymentMethod.value}');
      print('Shipping Method: ${shippingMethod.value}');
      print('Note: $note');

      // Tạo order
      final orderData = {
        'user_id': authController.currentUser.value!.id,
        'address_id': addressId,
        'total_amount': totalAmount,
        'shipping_fee': finalShippingFee,
        'shipping_method': shippingMethod.value,
        'note': note,
        'payment_method': paymentMethod.value,
        'status': 'pending',
        'payment_status': 'pending',
      };

      print('Order Data: $orderData');

      final orderResponse = await supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];
      print('Order created with ID: $orderId');

      // Tạo order items + options
      for (var item in cartController.cartItems) {
        final orderItemData = {
          'order_id': orderId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.priceAtTime,
        };

        print('Order Item Data: $orderItemData');

        final orderItemRes = await supabase
            .from('order_items')
            .insert(orderItemData)
            .select()
            .single();

        final orderItemId = orderItemRes['id'];

        // Lưu options nếu có (lỗi ở đây không làm hỏng đơn hàng)
        if (item.options != null && item.options!.isNotEmpty) {
          for (var opt in item.options!) {
            try {
              await supabase.from('order_item_options').insert({
                'order_item_id': orderItemId,
                'option_item_id': opt.optionItemId,
                'option_group_id': opt.optionGroupId,
                'option_name': opt.optionItem?.name ?? '',
                'option_price_adjustment': opt.optionItem?.priceAdjustment ?? 0,
              });
            } catch (e) {
              print('WARN: Không lưu được option ${opt.optionItemId}: $e');
            }
          }
        }
      }

      // Xóa giỏ hàng
      await cartController.clearCart();

      Get.snackbar(
        'Thành công',
        'Đặt hàng thành công! Mã đơn: ${orderId.substring(0, 8)}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      await fetchOrders();

      return true;

    } catch (e) {
      print('Error creating order: $e');

      // Hiển thị lỗi chi tiết
      String errorMessage = 'Không thể tạo đơn hàng';
      if (e.toString().contains('violates foreign key')) {
        errorMessage = 'Dữ liệu không hợp lệ, vui lòng thử lại';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Lỗi kết nối, vui lòng kiểm tra mạng';
      }

      Get.snackbar(
        'Lỗi',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;

    } finally {
      isLoading.value = false;
    }
  }

  // Lấy chi tiết đơn hàng
  Future<void> fetchOrderDetail(String orderId) async {
    try {
      isLoading.value = true;
      currentOrder.value = null;
      orderItems.clear();

      final orderResponse = await supabase
          .from('orders')
          .select(
            '*, addresses(*), '
            'customer:users!user_id(*), '
            'shipper:users!shipper_id(*)',
          )
          .eq('id', orderId)
          .single();

      print('Order detail response: $orderResponse');

      currentOrder.value = OrderModel.fromJson(orderResponse);

      final itemsResponse = await supabase
          .from('order_items')
          .select('*, products(*), order_item_options(*)')
          .eq('order_id', orderId);

      print('Order items response: $itemsResponse');

      orderItems.value = (itemsResponse as List)
          .map((json) => OrderItemModel.fromJson(json))
          .toList();

    } catch (e) {
      print('Error fetching order detail: $e');
      Get.snackbar(
        'Lỗi',
        'Không tải được chi tiết đơn: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Hủy đơn hàng
  Future<bool> cancelOrder(String orderId) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId);

      await fetchOrders();

      Get.snackbar('Thành công', 'Đã hủy đơn hàng', backgroundColor: Colors.green, colorText: Colors.white);
      return true;

    } catch (e) {
      print('Error cancelling order: $e');
      Get.snackbar('Lỗi', 'Không thể hủy đơn hàng', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }
}