// lib/models/cart_item_option_model.dart
import 'option_item_model.dart';
import 'option_group_model.dart';

class CartItemOption {
  final String id;
  final String cartItemId;
  final String optionItemId;
  final String optionGroupId;
  final DateTime createdAt;

  // Dữ liệu join
  OptionItem? optionItem;
  OptionGroup? optionGroup;

  CartItemOption({
    required this.id,
    required this.cartItemId,
    required this.optionItemId,
    required this.optionGroupId,
    required this.createdAt,
    this.optionItem,
    this.optionGroup,
  });

  factory CartItemOption.fromJson(Map<String, dynamic> json) {
    return CartItemOption(
      id: json['id'] as String,
      cartItemId: json['cart_item_id'] as String,
      optionItemId: json['option_item_id'] as String,
      optionGroupId: json['option_group_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      optionItem: json['option_items'] != null
          ? OptionItem.fromJson(json['option_items'])
          : null,
      optionGroup: json['option_groups'] != null
          ? OptionGroup.fromJson(json['option_groups'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_item_id': cartItemId,
      'option_item_id': optionItemId,
      'option_group_id': optionGroupId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Lấy tên option
  String get optionName => optionItem?.name ?? '';

  // Lấy giá điều chỉnh
  double get priceAdjustment => optionItem?.priceAdjustment ?? 0;

  // Format giá
  String get formattedPrice {
    if (priceAdjustment == 0) return 'Miễn phí';
    if (priceAdjustment > 0) {
      return '+${priceAdjustment.toStringAsFixed(0)}đ';
    }
    return '${priceAdjustment.toStringAsFixed(0)}đ';
  }
}