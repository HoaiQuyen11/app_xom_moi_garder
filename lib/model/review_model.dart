// lib/models/review_model.dart
import 'user_model.dart';
import 'product_model.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String productId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  // Dữ liệu join
  UserModel? user;
  ProductModel? product;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.user,
    this.product,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['users'] != null
          ? UserModel.fromJson(json['users'])
          : null,
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Hiển thị rating dạng sao
  String get starRating => '★' * rating + '☆' * (5 - rating);

  // Format ngày tháng
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}