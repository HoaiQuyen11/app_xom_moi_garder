// lib/models/enums.dart
import 'dart:ui';

enum UserRole {
  admin,
  customer,
  shipper;

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
      case UserRole.shipper:
        return 'Shipper';
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
  pending,      // chờ xác nhận
  confirmed,    // admin xác nhận
  preparing,    // đang chuẩn bị
  delivering,   // đang giao
  completed,    // hoàn thành
  cancelled;    // hủy

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
  viettel_money;  // Thêm viettel_money

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
      case PaymentMethod.viettel_money:
        return 'Viettel Money';
    }
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed;

  String get value => name;
  static PaymentStatus fromString(String value) => PaymentStatus.values.firstWhere(
        (e) => e.name == value,
    orElse: () => PaymentStatus.pending,
  );

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

enum VehicleType {
  bike,
  car,
  scooter;

  String get value => name;
  static VehicleType fromString(String value) => VehicleType.values.firstWhere(
        (e) => e.name == value,
    orElse: () => VehicleType.bike,
  );

  String get displayName {
    switch (this) {
      case VehicleType.bike:
        return 'Xe máy';
      case VehicleType.car:
        return 'Xe ô tô';
      case VehicleType.scooter:
        return 'Xe tay ga';
    }
  }
}

// Thêm enum ShippingMethod
enum ShippingMethod {
  standard,
  fast;

  String get value => name;

  static ShippingMethod fromString(String value) {
    return ShippingMethod.values.firstWhere(
          (e) => e.name == value,
      orElse: () => ShippingMethod.standard,
    );
  }

  String get displayName {
    switch (this) {
      case ShippingMethod.standard:
        return 'Giao hàng tiêu chuẩn';
      case ShippingMethod.fast:
        return 'FAST Giao Tiết Kiệm';
    }
  }

  double get fee {
    switch (this) {
      case ShippingMethod.standard:
        return 16000;
      case ShippingMethod.fast:
        return 32000;
    }
  }
}