// lib/models/category_model.dart
class CategoryModel {
  final String id;
  final String name;
  final int productCount;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
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
      productCount: count,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}