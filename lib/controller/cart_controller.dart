// lib/controller/controller_cart.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/cart_item_model.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/views/pages/login_page.dart';

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

  Future<void> fetchCart() async {
    if (!authController.isLoggedIn) return;
    try {
      isLoading.value = true;
      final response = await supabase
          .from('cart_items')
          .select('*, products(*)')
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

  // selectedOptions: [{name: "Size", value: "L", price: 5000}, ...]
  Future<void> addToCart(
    ProductModel product,
    int quantity, {
    List<Map<String, dynamic>>? selectedOptions,
  }) async {
    if (!authController.isLoggedIn) {
      Get.to(() => const LoginPage());
      return;
    }

    try {
      final opts = selectedOptions ?? [];
      final hasOptions = opts.isNotEmpty;

      if (!hasOptions) {
        final existingItem = cartItems.firstWhereOrNull(
          (item) => item.productId == product.id && item.options.isEmpty,
        );
        if (existingItem != null) {
          await updateQuantity(existingItem, existingItem.quantity + quantity);
          return;
        }
      }

      await supabase.from('cart_items').insert({
        'user_id': authController.currentUser.value!.id,
        'product_id': product.id,
        'quantity': quantity,
        'price_at_time': product.price,
        'options': opts,
      });

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

  Future<void> removeFromCart(CartItemModel item) async {
    try {
      await supabase.from('cart_items').delete().eq('id', item.id);
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

  double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.subtotal);
  String get formattedTotal => '${totalAmount.toStringAsFixed(0)}đ';
  int get totalQuantity => cartItems.fold(0, (sum, item) => sum + item.quantity);
}
