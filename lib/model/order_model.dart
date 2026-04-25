// lib/models/order_model.dart
import 'enums.dart';
import 'address_model.dart';
import 'user_model.dart';
import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final String? shipperId;
  final String? addressId;
  final double totalAmount;
  final double shippingFee;
  final ShippingMethod shippingMethod;
  final String? note;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  // Dữ liệu join
  UserModel? customer;
  AddressModel? address;
  UserModel? shipper;
  List<OrderItemModel>? items;

  OrderModel({
    required this.id,
    required this.userId,
    this.shipperId,
    this.addressId,
    required this.totalAmount,
    this.shippingFee = 0,
    this.shippingMethod = ShippingMethod.standard,
    this.note,
    this.status = OrderStatus.pending,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    required this.createdAt,
    this.customer,
    this.address,
    this.shipper,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      shipperId: json['shipper_id'] as String?,
      addressId: json['address_id'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      shippingFee: json['shipping_fee'] != null
          ? (json['shipping_fee'] as num).toDouble()
          : 0,
      shippingMethod: ShippingMethod.fromString(json['shipping_method'] ?? 'standard'),
      note: json['note'] as String?,
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] ?? 'cod'),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
      customer: (json['customer'] ?? json['users']) != null
          ? UserModel.fromJson(json['customer'] ?? json['users'])
          : null,
      address: json['addresses'] != null
          ? AddressModel.fromJson(json['addresses'])
          : null,
      shipper: json['shipper'] != null
          ? UserModel.fromJson(json['shipper'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shipper_id': shipperId,
      'address_id': addressId,
      'total_amount': totalAmount,
      'shipping_fee': shippingFee,
      'shipping_method': shippingMethod.value,
      'note': note,
      'status': status.value,
      'payment_method': paymentMethod.value,
      'payment_status': paymentStatus.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Format tổng tiền
  String get formattedTotal => '${totalAmount.toStringAsFixed(0)}đ';

  // Kiểm tra trạng thái
  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isPreparing => status == OrderStatus.preparing;
  bool get isDelivering => status == OrderStatus.delivering;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  // Có thể hủy không
  bool get canCancel => status == OrderStatus.pending || status == OrderStatus.confirmed;

  // Có thể đánh giá không
  bool get canReview => status == OrderStatus.completed;
}

