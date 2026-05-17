// lib/model/product_option_model.dart

class OptionValue {
  final String label;
  final double price;

  OptionValue({required this.label, required this.price});

  factory OptionValue.fromJson(Map<String, dynamic> json) {
    return OptionValue(
      label: json['label'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'price': price};

  String get formattedPrice {
    if (price == 0) return 'Miễn phí';
    if (price > 0) return '+${price.toStringAsFixed(0)}đ';
    return '${price.toStringAsFixed(0)}đ';
  }
}

class ProductOption {
  final String id;
  final String productId;
  final String name;
  final List<OptionValue> values;
  final bool isRequired;
  final DateTime createdAt;

  ProductOption({
    required this.id,
    required this.productId,
    required this.name,
    required this.values,
    this.isRequired = false,
    required this.createdAt,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as List? ?? [];
    return ProductOption(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      values: rawValues
          .map((v) => OptionValue.fromJson(v as Map<String, dynamic>))
          .toList(),
      isRequired: json['is_required'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'values': values.map((v) => v.toJson()).toList(),
        'is_required': isRequired,
      };
}
