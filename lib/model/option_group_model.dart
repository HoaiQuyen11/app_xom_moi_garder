// lib/models/option_group_model.dart
import 'option_item_model.dart';

class OptionGroup {
  final String id;
  final String productId;
  final String name;
  final String selectionType; // 'single' hoặc 'multi'
  final bool isRequired;
  final int minSelect;
  final int maxSelect;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Dữ liệu join
  List<OptionItem>? items;

  OptionGroup({
    required this.id,
    required this.productId,
    required this.name,
    required this.selectionType,
    required this.isRequired,
    required this.minSelect,
    required this.maxSelect,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory OptionGroup.fromJson(Map<String, dynamic> json) {
    return OptionGroup(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      selectionType: json['selection_type'] as String? ?? 'single',
      isRequired: json['is_required'] as bool? ?? true,
      minSelect: json['min_select'] as int? ?? 1,
      maxSelect: json['max_select'] as int? ?? 1,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: json['option_items'] != null
          ? (json['option_items'] as List)
          .map((item) => OptionItem.fromJson(item))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'selection_type': selectionType,
      'is_required': isRequired,
      'min_select': minSelect,
      'max_select': maxSelect,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper
  bool get isSingleSelect => selectionType == 'single';
  bool get isMultiSelect => selectionType == 'multi';

  String get selectionTypeDisplay {
    switch (selectionType) {
      case 'single':
        return 'Chọn một';
      case 'multi':
        return 'Chọn nhiều';
      default:
        return 'Không xác định';
    }
  }
}