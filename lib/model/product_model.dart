// lib/models/product_model.dart
class ProductModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? categoryId;
  final bool isAvailable;
  final double ratingAvg;
  final int totalReviews;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.categoryId,
    this.isAvailable = true,
    this.ratingAvg = 5.0,
    this.totalReviews = 0,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 5.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'is_available': isAvailable,
      'rating_avg': ratingAvg,
      'total_reviews': totalReviews,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Format giá tiền
  String get formattedPrice => '${price.toStringAsFixed(0)}đ';

  // Hiển thị rating
  String get ratingDisplay => ratingAvg.toStringAsFixed(1);
}