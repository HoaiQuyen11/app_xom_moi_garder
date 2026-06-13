// lib/models/enums.dart
import 'dart:ui';

enum UserRole {
  admin,
  customer;

  String get value => name;
  static UserRole fromString(String value) => UserRole.values.firstWhere(
    (e) => e.name == value,
    orElse: () => UserRole.customer,
  );

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.customer:
        return 'Khách hàng';
    }
  }
}

enum UserStatus {
  active,
  inactive,
  banned;

  String get value => name;
  static UserStatus fromString(String value) => UserStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => UserStatus.active,
  );

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Hoạt động';
      case UserStatus.inactive:
        return 'Bị khóa';
      case UserStatus.banned:
        return 'Bị cấm';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.active:
        return const Color(0xFF4CAF50);
      case UserStatus.inactive:
        return const Color(0xFFFF9800);
      case UserStatus.banned:
        return const Color(0xFFF44336);
    }
  }
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  delivering,
  completed,
  cancelled;

  String get value => name;
  static OrderStatus fromString(String value) => OrderStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => OrderStatus.pending,
  );

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

enum PaymentMethod {
  cod,
  momo,
  banking,
  viettel;

  String get value => name;
  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cod,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cod:
        return 'Thanh toán khi nhận hàng';
      case PaymentMethod.momo:
        return 'Ví MoMo';
      case PaymentMethod.banking:
        return 'Chuyển khoản ngân hàng';
      case PaymentMethod.viettel:
        return 'Viettel Money';
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed;

  String get value => name;
  static PaymentStatus fromString(String value) => PaymentStatus.values
      .firstWhere((e) => e.name == value, orElse: () => PaymentStatus.pending);

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Chờ thanh toán';
      case PaymentStatus.paid:
        return 'Đã thanh toán';
      case PaymentStatus.failed:
        return 'Thanh toán thất bại';
    }
  }
}

enum DeliveryType {
  pickup,
  delivery;

  String get value => name;
  static DeliveryType fromString(String value) => DeliveryType.values
      .firstWhere((e) => e.name == value, orElse: () => DeliveryType.delivery);

  String get displayName {
    switch (this) {
      case DeliveryType.pickup:
        return 'Tự đến lấy';
      case DeliveryType.delivery:
        return 'Giao hàng tận nơi';
    }
  }
}

enum NotificationType {
  order,
  system,
  promotion;

  String get value => name;
  static NotificationType fromString(String value) =>
      NotificationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationType.system,
      );

  String get displayName {
    switch (this) {
      case NotificationType.order:
        return 'Đơn hàng';
      case NotificationType.system:
        return 'Hệ thống';
      case NotificationType.promotion:
        return 'Khuyến mãi';
    }
  }
}
