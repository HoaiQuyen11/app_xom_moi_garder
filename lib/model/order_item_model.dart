// lib/models/order_item_model.dart
import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price;

  // Dữ liệu join
  ProductModel? product;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
    };
  }

  // Tính tổng tiền của item này
  double get subtotal => price * quantity;

  // Format giá
  String get formattedPrice => '${price.toStringAsFixed(0)}đ';
  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)}đ';
}