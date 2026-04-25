// lib/models/order_item_model.dart
import 'order_item_option_model.dart';
import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price;

  // Dữ liệu join
  ProductModel? product;
  List<OrderItemOption>? options;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.product,
    this.options,
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
      options: json['order_item_options'] != null
          ? (json['order_item_options'] as List)
              .map((opt) => OrderItemOption.fromJson(opt))
              .toList()
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

  // Tính tổng tiền của item này (bao gồm options)
  double get subtotal {
    double optionsPrice = 0;
    if (options != null) {
      for (var opt in options!) {
        optionsPrice += opt.optionPriceAdjustment;
      }
    }
    return (price + optionsPrice) * quantity;
  }

  // Text mô tả options
  String get optionsText {
    if (options == null || options!.isEmpty) return '';
    return options!.map((opt) => opt.optionName).join(', ');
  }

  bool get hasOptions => options != null && options!.isNotEmpty;

  // Format giá
  String get formattedPrice => '${price.toStringAsFixed(0)}đ';
  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)}đ';
}