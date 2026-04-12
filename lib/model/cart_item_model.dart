// lib/models/cart_item_model.dart
import 'package:xommoigarden/model/cart_item_option_model.dart';
import 'product_model.dart';

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final double priceAtTime;
  final DateTime createdAt;

  // Dữ liệu join (không lưu trong DB)
  ProductModel? product;
  List<CartItemOption>? options;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.priceAtTime,
    required this.createdAt,
    this.product,
    this.options, // Thêm options vào constructor
  });

  // Tính tổng tiền bao gồm options
  double get subtotal {
    double total = priceAtTime * quantity;
    if (options != null) {
      for (var option in options!) {
        if (option.optionItem != null) {
          total += option.optionItem!.priceAdjustment * quantity;
        }
      }
    }
    return total;
  }

  // Format subtotal
  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)}đ';

  // Lấy text mô tả các option đã chọn
  String get optionsText {
    if (options == null || options!.isEmpty) return '';
    return options!.map((opt) => opt.optionItem?.name ?? '').join(', ');
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      priceAtTime: (json['price_at_time'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
      options: json['cart_item_options'] != null
          ? (json['cart_item_options'] as List)
          .map((opt) => CartItemOption.fromJson(opt))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_time': priceAtTime,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy với số lượng mới
  CartItemModel copyWithQuantity(int newQuantity) {
    return CartItemModel(
      id: id,
      userId: userId,
      productId: productId,
      quantity: newQuantity,
      priceAtTime: priceAtTime,
      createdAt: createdAt,
      product: product,
      options: options, // Giữ nguyên options khi copy
    );
  }

  // Copy với options mới
  CartItemModel copyWithOptions(List<CartItemOption>? newOptions) {
    return CartItemModel(
      id: id,
      userId: userId,
      productId: productId,
      quantity: quantity,
      priceAtTime: priceAtTime,
      createdAt: createdAt,
      product: product,
      options: newOptions,
    );
  }
}