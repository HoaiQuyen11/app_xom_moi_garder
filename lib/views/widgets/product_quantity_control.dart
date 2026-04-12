// lib/views/widgets/product_quantity_control.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/cart_controller.dart';
import 'package:xommoigarden/controller/product_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import '../user/product_detail_page.dart';

class ProductQuantityControl extends StatefulWidget {
  final ProductModel product;
  final bool isHorizontal;
  final GlobalKey? addBtnKey;

  const ProductQuantityControl({
    super.key,
    required this.product,
    this.isHorizontal = true,
    this.addBtnKey,
  });

  @override
  State<ProductQuantityControl> createState() => _ProductQuantityControlState();
}

class _ProductQuantityControlState extends State<ProductQuantityControl> {
  final ControllerCart cartController = Get.find<ControllerCart>();
  final ControllerProduct productController = Get.find<ControllerProduct>();

  // Constants UI
  final double btnSize = 36;
  final double iconSize = 25;
  final double radius = 20;

  Color get mainColor => Colors.green.shade800;


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Tìm item trong giỏ hàng
      final cartItem = cartController.cartItems.firstWhereOrNull(
            (item) => item.productId == widget.product.id,
      );

      final int soLuong = cartItem?.quantity ?? 0;

      if (soLuong == 0) {
        return _buildAddButton();
      }

      return _buildQuantityControl(soLuong, cartItem?.id);
    });
  }

  Widget _buildAddButton() {
    return GestureDetector(
      key: widget.addBtnKey,
      onTap: () async {
        // Kiểm tra sản phẩm có option không
        final hasOptions = await _checkHasOptions();

        if (hasOptions) {
          // Có option -> mở trang chi tiết
          _showProductDetailWithOptions();
          return;
        }

        // Không có option -> thêm thẳng vào giỏ
        await cartController.addToCart(widget.product, 1);

        // Chạy animation nếu có
        if (productController.animateAddToCart != null && widget.addBtnKey != null) {
          productController.animateAddToCart!(widget.product, widget.addBtnKey!);
        }
      },
      child: Container(
        width: btnSize,
        height: btnSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: mainColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildQuantityControl(int soLuong, String? cartItemId) {
    return Container(
      height: btnSize,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: mainColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconButton(
            icon: Icons.remove,
            onTap: () async {
              if (cartItemId != null) {
                final item = cartController.cartItems.firstWhere(
                      (e) => e.id == cartItemId,
                );
                await cartController.updateQuantity(item, soLuong - 1);
              }
            },
          ),
          const SizedBox(width: 6),
          Text(
            '$soLuong',
            style: TextStyle(
              color: mainColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 6),
          _buildIconButton(
            icon: Icons.add,
            onTap: () async {
              if (cartItemId != null) {
                final item = cartController.cartItems.firstWhere(
                      (e) => e.id == cartItemId,
                );
                await cartController.updateQuantity(item, soLuong + 1);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: btnSize,
        height: btnSize,
        child: Icon(
          icon,
          color: mainColor,
          size: iconSize,
        ),
      ),
    );
  }

  Future<bool> _checkHasOptions() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from("option_groups")
          .select("id")
          .eq("product_id", widget.product.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking options: $e');
      return false;
    }
  }

  void _showProductDetailWithOptions() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: ProductDetailPage(
                product: widget.product,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }
}