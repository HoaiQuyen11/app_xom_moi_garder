// lib/models/cart_item_model.dart
import 'product_model.dart';

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final double priceAtTime;
  final List<Map<String, dynamic>> options;
  final DateTime createdAt;

  ProductModel? product;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.priceAtTime,
    this.options = const [],
    required this.createdAt,
    this.product,
  });

  double get optionsExtraPrice {
    return options.fold(
      0.0,
      (sum, o) => sum + ((o['price'] as num?)?.toDouble() ?? 0),
    );
  }

  double get subtotal => (priceAtTime + optionsExtraPrice) * quantity;

  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)}đ';

  String get optionsText {
    if (options.isEmpty) return '';
    return options.map((o) => o['value'] ?? o['label'] ?? '').join(', ');
  }

  bool get hasOptions => options.isNotEmpty;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<Map<String, dynamic>> opts = [];
    if (rawOptions is List) {
      opts = rawOptions
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return CartItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      priceAtTime: (json['price_at_time'] as num).toDouble(),
      options: opts,
      createdAt: DateTime.parse(json['created_at'] as String),
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_time': priceAtTime,
      'options': options,
    };
  }

  CartItemModel copyWithQuantity(int newQuantity) {
    return CartItemModel(
      id: id,
      userId: userId,
      productId: productId,
      quantity: newQuantity,
      priceAtTime: priceAtTime,
      options: options,
      createdAt: createdAt,
      product: product,
    );
  }
}
