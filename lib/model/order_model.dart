// lib/models/order_model.dart
import 'enums.dart';
import 'address_model.dart';
import 'user_model.dart';
import 'order_item_model.dart';

class OrderModel {
  static const Duration cancelWindow = Duration(seconds: 15);

  final String id;
  final String? orderCode;
  final String userId;
  final String? addressId;
  final String? voucherId;
  final DeliveryType deliveryType;
  final String? note;
  final double subtotal;
  final double shippingFee;
  final double discountAmount;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel? customer;
  AddressModel? address;
  List<OrderItemModel>? items;

  OrderModel({
    required this.id,
    this.orderCode,
    required this.userId,
    this.addressId,
    this.voucherId,
    this.deliveryType = DeliveryType.delivery,
    this.note,
    this.subtotal = 0,
    this.shippingFee = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.cancelReason,
    this.cancelledAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.address,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderCode: json['order_code'] as String?,
      userId: json['user_id'] as String,
      addressId: json['address_id'] as String?,
      voucherId: json['voucher_id'] as String?,
      deliveryType: DeliveryType.fromString(
        json['delivery_type'] ?? 'delivery',
      ),
      note: json['note'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] ?? 'cod'),
      paymentStatus: PaymentStatus.fromString(
        json['payment_status'] ?? 'pending',
      ),
      cancelReason: json['cancel_reason'] as String?,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      customer: (json['customer'] ?? json['users']) != null
          ? UserModel.fromJson(json['customer'] ?? json['users'])
          : null,
      address: json['addresses'] != null
          ? AddressModel.fromJson(json['addresses'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'address_id': addressId,
      'voucher_id': voucherId,
      'delivery_type': deliveryType.value,
      'note': note,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'status': status.value,
      'payment_method': paymentMethod.value,
      'payment_status': paymentStatus.value,
    };
  }

  String get formattedTotal => '${totalAmount.toStringAsFixed(0)}đ';
  String get displayCode => orderCode ?? id.substring(0, 8).toUpperCase();

  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isPreparing => status == OrderStatus.preparing;
  bool get isDelivering => status == OrderStatus.delivering;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  DateTime get cancelDeadline => createdAt.add(cancelWindow);
  Duration get cancelTimeRemaining => cancelDeadline.difference(DateTime.now());
  int get cancelSecondsRemaining {
    final seconds = cancelTimeRemaining.inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  bool get canCancel =>
      status == OrderStatus.pending && cancelTimeRemaining > Duration.zero;
  bool get canReview => status == OrderStatus.completed;
}
