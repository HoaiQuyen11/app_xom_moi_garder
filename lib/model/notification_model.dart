// lib/model/notification_model.dart
import 'enums.dart';
import 'order_model.dart';

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedOrderId;
  final bool isRead;
  final DateTime createdAt;

  OrderModel? relatedOrder;

  NotificationModel({
    required this.id,
    required this.userId,
    this.type = NotificationType.system,
    required this.title,
    required this.message,
    this.relatedOrderId,
    this.isRead = false,
    required this.createdAt,
    this.relatedOrder,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] ?? 'system'),
      title: json['title'] as String,
      message: json['message'] as String,
      relatedOrderId: json['related_order_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      relatedOrder: json['orders'] != null
          ? OrderModel.fromJson(json['orders'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'related_order_id': relatedOrderId,
      'is_read': isRead,
    };
  }
}
