// lib/models/order_item_model.dart
import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String? productName;
  final int quantity;
  final double price;
  final List<Map<String, dynamic>> options;

  ProductModel? product;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.price,
    this.options = const [],
    this.product,
  });

  double get optionsExtraPrice {
    return options.fold(
      0.0,
      (sum, o) => sum + ((o['price'] as num?)?.toDouble() ?? 0),
    );
  }

  double get subtotal => (price + optionsExtraPrice) * quantity;

  String get optionsText {
    if (options.isEmpty) return '';
    return options.map((o) => o['value'] ?? o['label'] ?? '').join(', ');
  }

  bool get hasOptions => options.isNotEmpty;

  String get formattedPrice => '${price.toStringAsFixed(0)}đ';
  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)}đ';

  String get displayName => productName ?? product?.name ?? 'Sản phẩm';

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<Map<String, dynamic>> opts = [];
    if (rawOptions is List) {
      opts = rawOptions
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      options: opts,
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'options': options,
    };
  }
}
