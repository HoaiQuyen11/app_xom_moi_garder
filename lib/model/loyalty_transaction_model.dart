// lib/model/loyalty_transaction_model.dart
import 'order_model.dart';

class LoyaltyTransactionModel {
  final String id;
  final String userId;
  final String? orderId;
  final int points;
  final String? reason;
  final DateTime createdAt;

  OrderModel? order;

  LoyaltyTransactionModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.points,
    this.reason,
    required this.createdAt,
    this.order,
  });

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String?,
      points: json['points'] as int,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      order: json['orders'] != null
          ? OrderModel.fromJson(json['orders'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'order_id': orderId,
      'points': points,
      'reason': reason,
    };
  }

  bool get isEarned => points > 0;
  bool get isSpent => points < 0;
}
