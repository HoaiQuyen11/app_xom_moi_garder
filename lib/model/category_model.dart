// lib/models/category_model.dart
class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;
  final int productCount;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.displayOrder = 0,
    this.isActive = true,
    this.productCount = 0,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['products'] is List) {
      final products = json['products'] as List;
      if (products.isNotEmpty && products.first is Map && products.first.containsKey('count')) {
        count = products.first['count'] as int? ?? 0;
      } else {
        count = products.length;
      }
    }

    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      productCount: count,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}
