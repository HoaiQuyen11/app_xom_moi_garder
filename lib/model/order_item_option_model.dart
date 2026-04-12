
class OrderItemOption {
  final String id;
  final String orderItemId;
  final String optionItemId;
  final String optionGroupId;
  final String optionName; // Snapshot tên
  final double optionPriceAdjustment; // Snapshot giá
  final DateTime createdAt;

  OrderItemOption({
    required this.id,
    required this.orderItemId,
    required this.optionItemId,
    required this.optionGroupId,
    required this.optionName,
    required this.optionPriceAdjustment,
    required this.createdAt,
  });

  factory OrderItemOption.fromJson(Map<String, dynamic> json) {
    return OrderItemOption(
      id: json['id'] as String,
      orderItemId: json['order_item_id'] as String,
      optionItemId: json['option_item_id'] as String,
      optionGroupId: json['option_group_id'] as String,
      optionName: json['option_name'] as String,
      optionPriceAdjustment: (json['option_price_adjustment'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_item_id': orderItemId,
      'option_item_id': optionItemId,
      'option_group_id': optionGroupId,
      'option_name': optionName,
      'option_price_adjustment': optionPriceAdjustment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedPrice {
    if (optionPriceAdjustment == 0) return 'Miễn phí';
    if (optionPriceAdjustment > 0) {
      return '+${optionPriceAdjustment.toStringAsFixed(0)}đ';
    }
    return '${optionPriceAdjustment.toStringAsFixed(0)}đ';
  }
}