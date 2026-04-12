// lib/models/option_item_model.dart
class OptionItem {
  final String id;
  final String groupId;
  final String name;
  final double priceAdjustment;
  final bool isDefault;
  final bool isAvailable;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  OptionItem({
    required this.id,
    required this.groupId,
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
    required this.isAvailable,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      priceAdjustment: (json['price_adjustment'] as num?)?.toDouble() ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'price_adjustment': priceAdjustment,
      'is_default': isDefault,
      'is_available': isAvailable,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper
  String get formattedPriceAdjustment {
    if (priceAdjustment == 0) return 'Miễn phí';
    if (priceAdjustment > 0) {
      return '+${priceAdjustment.toStringAsFixed(0)}đ';
    }
    return '${priceAdjustment.toStringAsFixed(0)}đ';
  }

  bool get isFree => priceAdjustment == 0;
  bool get isExtraCost => priceAdjustment > 0;
  bool get isDiscount => priceAdjustment < 0;
}