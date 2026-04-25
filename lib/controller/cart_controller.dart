// lib/controller/controller_cart.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/cart_item_model.dart';
import 'package:xommoigarden/model/option_item_model.dart';
import 'package:xommoigarden/model/product_model.dart';


class ControllerCart extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find();

  var cartItems = <CartItemModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(authController.currentUser, (_) {
      if (authController.isLoggedIn) {
        fetchCart();
      } else {
        cartItems.clear();
      }
    });
  }

  // Lấy giỏ hàng
  Future<void> fetchCart() async {
    if (!authController.isLoggedIn) return;

    try {
      isLoading.value = true;

      final response = await supabase
          .from('cart_items')
          .select('''
          *,
          products(*),
          cart_item_options(
            *,
            option_items(*),
            option_groups(*)
          )
        ''')
          .eq('user_id', authController.currentUser.value!.id)
          .order('created_at', ascending: false);

      cartItems.value = (response as List)
          .map((json) => CartItemModel.fromJson(json))
          .toList();

    } catch (e) {
      print('Error fetching cart: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Thêm vào giỏ hàng
  Future<void> addToCart(
    ProductModel product,
    int quantity, {
    List<OptionItem>? selectedOptions,
  }) async {
    if (!authController.isLoggedIn) {
      Get.toNamed('/pages');
      return;
    }

    try {
      final hasOptions = selectedOptions != null && selectedOptions.isNotEmpty;

      // Nếu sản phẩm không có option → merge vào item cũ (nếu tồn tại và cũng không có option)
      if (!hasOptions) {
        final existingItem = cartItems.firstWhereOrNull(
          (item) => item.productId == product.id &&
              (item.options == null || item.options!.isEmpty),
        );

        if (existingItem != null) {
          await updateQuantity(existingItem, existingItem.quantity + quantity);
          return;
        }
      }

      // Insert cart_item mới
      final cartItemRes = await supabase.from('cart_items').insert({
        'user_id': authController.currentUser.value!.id,
        'product_id': product.id,
        'quantity': quantity,
        'price_at_time': product.price,
      }).select().single();

      final cartItemId = cartItemRes['id'];

      // Insert cart_item_options (nếu có)
      if (hasOptions) {
        for (var opt in selectedOptions) {
          await supabase.from('cart_item_options').insert({
            'cart_item_id': cartItemId,
            'option_item_id': opt.id,
            'option_group_id': opt.groupId,
          });
        }
      }

      await fetchCart();

      Get.snackbar(
        'Thành công',
        'Đã thêm ${product.name} vào giỏ hàng',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      print('Error adding to cart: $e');
      Get.snackbar('Lỗi', 'Không thể thêm vào giỏ hàng');
    }
  }

  // Cập nhật số lượng
  Future<void> updateQuantity(CartItemModel item, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(item);
      return;
    }

    try {
      await supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', item.id);

      await fetchCart();

    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  // Xóa khỏi giỏ hàng
  Future<void> removeFromCart(CartItemModel item) async {
    try {
      await supabase
          .from('cart_items')
          .delete()
          .eq('id', item.id);

      await fetchCart();

      Get.snackbar(
        'Thành công',
        'Đã xóa sản phẩm khỏi giỏ hàng',
        snackPosition: SnackPosition.TOP,
      );

    } catch (e) {
      print('Error removing from cart: $e');
      Get.snackbar('Lỗi', 'Không thể xóa sản phẩm');
    }
  }

  // Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    if (!authController.isLoggedIn) return;

    try {
      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', authController.currentUser.value!.id);

      cartItems.clear();

    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  // Tính tổng tiền
  double get totalAmount {
    return cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Format tổng tiền
  String get formattedTotal => '${totalAmount.toStringAsFixed(0)}đ';

  // Tổng số lượng sản phẩm trong giỏ
  int get totalQuantity {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }
}