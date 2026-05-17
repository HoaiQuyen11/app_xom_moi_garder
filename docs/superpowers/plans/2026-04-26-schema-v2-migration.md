# Schema v2.0 Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate toàn bộ Flutter code từ schema cũ (option_groups/option_items/cart_item_options/order_item_options + shipper role) sang schema v2.0 (product_options JSONB, options nhúng trong cart_items/order_items, bỏ shipper, thêm delivery_type/order_code).

**Architecture:** Thay thế hệ thống option 4-bảng bằng product_options.values JSONB + options nhúng trực tiếp trong cart_items.options và order_items.options. Bỏ hoàn toàn shipper role và shipper_id. Thêm các field mới cho orders (order_code, subtotal, delivery_type, cancel_reason...).

**Tech Stack:** Flutter, Dart, GetX, Supabase Flutter SDK

---

## File Map

### XÓA (không còn dùng)
- `lib/model/option_group_model.dart` — thay bằng ProductOption
- `lib/model/option_item_model.dart` — thay bằng OptionValue inside ProductOption
- `lib/model/cart_item_option_model.dart` — options giờ là JSONB trong cart_items
- `lib/model/order_item_option_model.dart` — options giờ là JSONB trong order_items

### SỬA
- `lib/model/enums.dart` — bỏ shipper/VehicleType/ShippingMethod, thêm DeliveryType
- `lib/model/user_model.dart` — bỏ shipper fields
- `lib/model/address_model.dart` — thêm label, recipientName, recipientPhone
- `lib/model/category_model.dart` — thêm imageUrl, displayOrder, isActive
- `lib/model/cart_item_model.dart` — options thành `List<Map<String,dynamic>>`
- `lib/model/order_item_model.dart` — options thành JSONB, thêm productName
- `lib/model/order_model.dart` — bỏ shipperId/shippingMethod/shipper, thêm orderCode/subtotal/deliveryType/cancelReason
- `lib/controller/cart_controller.dart` — bỏ cart_item_options, dùng JSONB
- `lib/controller/order_controller.dart` — bỏ order_item_options/shipping_method, thêm delivery_type/order_code
- `lib/controller/admin_controller.dart` — bỏ assignShipper/getShippers
- `lib/views/user/product_detail_page.dart` — load product_options thay vì option_groups
- `lib/views/user/checkout_page.dart` — bỏ ShippingMethod, dùng DeliveryType
- `lib/views/user/order_detail_page.dart` — bỏ shipper section, hiện order_code
- `lib/views/admin/admin_orders.dart` — bỏ shipper assignment
- `lib/views/admin/admin_users.dart` — bỏ shipper role filter

### TẠO MỚI
- `lib/model/product_option_model.dart` — ProductOption + OptionValue classes

---

## Task 1: Enums — bỏ shipper/VehicleType/ShippingMethod, thêm DeliveryType

**Files:**
- Modify: `lib/model/enums.dart`

- [ ] **Step 1: Sửa enums.dart**

Thay toàn bộ nội dung file:

```dart
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

enum DeliveryType {
  pickup,
  delivery;

  String get value => name;
  static DeliveryType fromString(String value) => DeliveryType.values.firstWhere(
        (e) => e.name == value,
    orElse: () => DeliveryType.delivery,
  );

  String get displayName {
    switch (this) {
      case DeliveryType.pickup:
        return 'Tự đến lấy';
      case DeliveryType.delivery:
        return 'Giao hàng tận nơi';
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/model/enums.dart
git commit -m "refactor: update enums for schema v2 - remove shipper/VehicleType/ShippingMethod, add DeliveryType"
```

---

## Task 2: UserModel — bỏ shipper fields

**Files:**
- Modify: `lib/model/user_model.dart`

- [ ] **Step 1: Sửa user_model.dart**

Thay toàn bộ nội dung:

```dart
// lib/models/user_model.dart
import 'enums.dart';

class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final int loyaltyPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.role = UserRole.customer,
    this.status = UserStatus.active,
    this.loyaltyPoints = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] ?? 'customer'),
      status: UserStatus.fromString(json['status'] ?? 'active'),
      loyaltyPoints: json['loyalty_points'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role.value,
      'status': status.value,
      'loyalty_points': loyaltyPoints,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
    int? loyaltyPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCustomer => role == UserRole.customer;
  bool get isAdmin => role == UserRole.admin;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/model/user_model.dart
git commit -m "refactor: remove shipper fields from UserModel"
```

---

## Task 3: AddressModel — thêm label, recipientName, recipientPhone

**Files:**
- Modify: `lib/model/address_model.dart`

- [ ] **Step 1: Sửa address_model.dart**

```dart
// lib/models/address_model.dart
class AddressModel {
  final String id;
  final String userId;
  final String? label;
  final String? recipientName;
  final String? recipientPhone;
  final String fullAddress;
  final double? lat;
  final double? lng;
  final bool isDefault;
  final DateTime createdAt;

  AddressModel({
    required this.id,
    required this.userId,
    this.label,
    this.recipientName,
    this.recipientPhone,
    required this.fullAddress,
    this.lat,
    this.lng,
    this.isDefault = false,
    required this.createdAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      fullAddress: json['full_address'] as String,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'label': label,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'full_address': fullAddress,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/model/address_model.dart
git commit -m "feat: add label/recipientName/recipientPhone to AddressModel"
```

---

## Task 4: CategoryModel — thêm imageUrl, displayOrder, isActive

**Files:**
- Modify: `lib/model/category_model.dart`

- [ ] **Step 1: Sửa category_model.dart**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/model/category_model.dart
git commit -m "feat: add imageUrl/displayOrder/isActive to CategoryModel"
```

---

## Task 5: Tạo ProductOptionModel mới (thay option_groups + option_items)

**Files:**
- Create: `lib/model/product_option_model.dart`

- [ ] **Step 1: Tạo product_option_model.dart**

```dart
// lib/model/product_option_model.dart

class OptionValue {
  final String label;
  final double price;

  OptionValue({required this.label, required this.price});

  factory OptionValue.fromJson(Map<String, dynamic> json) {
    return OptionValue(
      label: json['label'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'price': price};

  String get formattedPrice {
    if (price == 0) return 'Miễn phí';
    if (price > 0) return '+${price.toStringAsFixed(0)}đ';
    return '${price.toStringAsFixed(0)}đ';
  }
}

class ProductOption {
  final String id;
  final String productId;
  final String name;
  final List<OptionValue> values;
  final bool isRequired;
  final DateTime createdAt;

  ProductOption({
    required this.id,
    required this.productId,
    required this.name,
    required this.values,
    this.isRequired = false,
    required this.createdAt,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as List? ?? [];
    return ProductOption(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      values: rawValues
          .map((v) => OptionValue.fromJson(v as Map<String, dynamic>))
          .toList(),
      isRequired: json['is_required'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'values': values.map((v) => v.toJson()).toList(),
        'is_required': isRequired,
      };
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/model/product_option_model.dart
git commit -m "feat: add ProductOption + OptionValue models for schema v2"
```

---

## Task 6: CartItemModel — options thành JSONB

**Files:**
- Modify: `lib/model/cart_item_model.dart`

- [ ] **Step 1: Sửa cart_item_model.dart**

Options giờ là `List<Map<String,dynamic>>` đọc trực tiếp từ JSONB. Mỗi phần tử: `{name: "Size", value: "L", price: 5000}`.

```dart
// lib/models/cart_item_model.dart
import 'product_model.dart';

class CartItemModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final double priceAtTime;
  final List<Map<String, dynamic>> options;
  final DateTime createdAt;

  ProductModel? product;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.priceAtTime,
    this.options = const [],
    required this.createdAt,
    this.product,
  });

  double get optionsExtraPrice {
    return options.fold(0.0, (sum, o) => sum + ((o['price'] as num?)?.toDouble() ?? 0));
  }

  double get subtotal => (priceAtTime + optionsExtraPrice) * quantity;

  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)}đ';

  String get optionsText {
    if (options.isEmpty) return '';
    return options.map((o) => o['value'] ?? o['label'] ?? '').join(', ');
  }

  bool get hasOptions => options.isNotEmpty;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<Map<String, dynamic>> opts = [];
    if (rawOptions is List) {
      opts = rawOptions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return CartItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      priceAtTime: (json['price_at_time'] as num).toDouble(),
      options: opts,
      createdAt: DateTime.parse(json['created_at'] as String),
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_time': priceAtTime,
      'options': options,
    };
  }

  CartItemModel copyWithQuantity(int newQuantity) {
    return CartItemModel(
      id: id,
      userId: userId,
      productId: productId,
      quantity: newQuantity,
      priceAtTime: priceAtTime,
      options: options,
      createdAt: createdAt,
      product: product,
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/model/cart_item_model.dart
git commit -m "refactor: CartItemModel options now JSONB list instead of separate table"
```

---

## Task 7: OrderItemModel — options thành JSONB, thêm productName

**Files:**
- Modify: `lib/model/order_item_model.dart`

- [ ] **Step 1: Sửa order_item_model.dart**

```dart
// lib/models/order_item_model.dart
import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String? productName;
  final int quantity;
  final double price;
  final List<Map<String, dynamic>> options;

  ProductModel? product;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.price,
    this.options = const [],
    this.product,
  });

  double get optionsExtraPrice {
    return options.fold(0.0, (sum, o) => sum + ((o['price'] as num?)?.toDouble() ?? 0));
  }

  double get subtotal => (price + optionsExtraPrice) * quantity;

  String get optionsText {
    if (options.isEmpty) return '';
    return options.map((o) => o['value'] ?? o['label'] ?? '').join(', ');
  }

  bool get hasOptions => options.isNotEmpty;

  String get formattedPrice => '${price.toStringAsFixed(0)}đ';
  String get formattedSubtotal => '${subtotal.toStringAsFixed(0)}đ';

  String get displayName => productName ?? product?.name ?? 'Sản phẩm';

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<Map<String, dynamic>> opts = [];
    if (rawOptions is List) {
      opts = rawOptions.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      options: opts,
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'options': options,
    };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/model/order_item_model.dart
git commit -m "refactor: OrderItemModel options now JSONB, add productName snapshot"
```

---

## Task 8: OrderModel — bỏ shipper/shippingMethod, thêm orderCode/subtotal/deliveryType

**Files:**
- Modify: `lib/model/order_model.dart`

- [ ] **Step 1: Sửa order_model.dart**

```dart
// lib/models/order_model.dart
import 'enums.dart';
import 'address_model.dart';
import 'user_model.dart';
import 'order_item_model.dart';

class OrderModel {
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
      deliveryType: DeliveryType.fromString(json['delivery_type'] ?? 'delivery'),
      note: json['note'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: OrderStatus.fromString(json['status'] ?? 'pending'),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] ?? 'cod'),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] ?? 'pending'),
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
  bool get canCancel => status == OrderStatus.pending;
  bool get canReview => status == OrderStatus.completed;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/model/order_model.dart
git commit -m "refactor: OrderModel v2 - remove shipper/shippingMethod, add orderCode/subtotal/deliveryType"
```

---

## Task 9: CartController — options JSONB, bỏ cart_item_options

**Files:**
- Modify: `lib/controller/cart_controller.dart`

- [ ] **Step 1: Sửa cart_controller.dart**

`selectedOptions` giờ là `List<Map<String,dynamic>>` dạng `[{name, value, price}]` thay vì `List<OptionItem>`.

```dart
// lib/controller/controller_cart.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/cart_item_model.dart';
import 'package:xommoigarden/model/product_model.dart';

class ControllerCart extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find();

  var cartItems = <CartItemModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(authController.currentUser, (_) {
      if (authController.isLoggedIn) {
        fetchCart();
      } else {
        cartItems.clear();
      }
    });
  }

  Future<void> fetchCart() async {
    if (!authController.isLoggedIn) return;
    try {
      isLoading.value = true;
      final response = await supabase
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', authController.currentUser.value!.id)
          .order('created_at', ascending: false);

      cartItems.value = (response as List)
          .map((json) => CartItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching cart: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // selectedOptions: [{name: "Size", value: "L", price: 5000}, ...]
  Future<void> addToCart(
    ProductModel product,
    int quantity, {
    List<Map<String, dynamic>>? selectedOptions,
  }) async {
    if (!authController.isLoggedIn) {
      Get.toNamed('/pages');
      return;
    }

    try {
      final opts = selectedOptions ?? [];
      final hasOptions = opts.isNotEmpty;

      if (!hasOptions) {
        final existingItem = cartItems.firstWhereOrNull(
          (item) => item.productId == product.id && item.options.isEmpty,
        );
        if (existingItem != null) {
          await updateQuantity(existingItem, existingItem.quantity + quantity);
          return;
        }
      }

      await supabase.from('cart_items').insert({
        'user_id': authController.currentUser.value!.id,
        'product_id': product.id,
        'quantity': quantity,
        'price_at_time': product.price,
        'options': opts,
      });

      await fetchCart();

      Get.snackbar(
        'Thành công',
        'Đã thêm ${product.name} vào giỏ hàng',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      Get.snackbar('Lỗi', 'Không thể thêm vào giỏ hàng');
    }
  }

  Future<void> updateQuantity(CartItemModel item, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(item);
      return;
    }
    try {
      await supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', item.id);
      await fetchCart();
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> removeFromCart(CartItemModel item) async {
    try {
      await supabase.from('cart_items').delete().eq('id', item.id);
      await fetchCart();
      Get.snackbar('Thành công', 'Đã xóa sản phẩm khỏi giỏ hàng',
          snackPosition: SnackPosition.TOP);
    } catch (e) {
      print('Error removing from cart: $e');
      Get.snackbar('Lỗi', 'Không thể xóa sản phẩm');
    }
  }

  Future<void> clearCart() async {
    if (!authController.isLoggedIn) return;
    try {
      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', authController.currentUser.value!.id);
      cartItems.clear();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.subtotal);
  String get formattedTotal => '${totalAmount.toStringAsFixed(0)}đ';
  int get totalQuantity => cartItems.fold(0, (sum, item) => sum + item.quantity);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/controller/cart_controller.dart
git commit -m "refactor: CartController - options JSONB, remove cart_item_options"
```

---

## Task 10: OrderController — options JSONB, bỏ shipping_method, thêm delivery_type + order_code

**Files:**
- Modify: `lib/controller/order_controller.dart`

- [ ] **Step 1: Sửa order_controller.dart**

```dart
// lib/controller/order_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/order_item_model.dart';
import 'package:xommoigarden/model/order_model.dart';
import 'auth_controller.dart';
import 'cart_controller.dart';

class ControllerOrder extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find();
  final ControllerCart cartController = Get.find();

  var orders = <OrderModel>[].obs;
  var currentOrder = Rx<OrderModel?>(null);
  var orderItems = <OrderItemModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(authController.currentUser, (_) {
      if (authController.isLoggedIn) fetchOrders();
    });
    if (authController.isLoggedIn) fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (!authController.isLoggedIn) return;
    try {
      isLoading.value = true;
      final response = await supabase
          .from('orders')
          .select('*, addresses(*)')
          .eq('user_id', authController.currentUser.value!.id)
          .order('created_at', ascending: false);

      orders.value = (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createOrder({
    required String addressId,
    required PaymentMethod paymentMethod,
    DeliveryType deliveryType = DeliveryType.delivery,
    double shippingFee = 0,
    String note = '',
  }) async {
    if (cartController.cartItems.isEmpty) {
      Get.snackbar('Lỗi', 'Giỏ hàng trống',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (!authController.isLoggedIn) {
      Get.snackbar('Lỗi', 'Vui lòng đăng nhập',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (addressId.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn địa chỉ giao hàng',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }

    try {
      isLoading.value = true;

      final double subtotal = cartController.totalAmount;
      final double totalAmount = subtotal + shippingFee;

      final orderResponse = await supabase
          .from('orders')
          .insert({
            'user_id': authController.currentUser.value!.id,
            'address_id': addressId,
            'delivery_type': deliveryType.value,
            'note': note,
            'subtotal': subtotal,
            'shipping_fee': shippingFee,
            'discount_amount': 0,
            'total_amount': totalAmount,
            'payment_method': paymentMethod.value,
            'status': 'pending',
            'payment_status': 'pending',
          })
          .select()
          .single();

      final orderId = orderResponse['id'];
      final orderCode = orderResponse['order_code'] ?? orderId.substring(0, 8);

      for (var item in cartController.cartItems) {
        await supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.product?.name,
          'quantity': item.quantity,
          'price': item.priceAtTime,
          'options': item.options,
        });
      }

      await cartController.clearCart();

      Get.snackbar(
        'Đặt hàng thành công!',
        'Mã đơn: $orderCode',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      await fetchOrders();
      return true;
    } catch (e) {
      print('Error creating order: $e');
      String errorMessage = 'Không thể tạo đơn hàng';
      if (e.toString().contains('violates foreign key')) {
        errorMessage = 'Dữ liệu không hợp lệ, vui lòng thử lại';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Lỗi kết nối, vui lòng kiểm tra mạng';
      }
      Get.snackbar('Lỗi', errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOrderDetail(String orderId) async {
    try {
      isLoading.value = true;
      currentOrder.value = null;
      orderItems.clear();

      final orderResponse = await supabase
          .from('orders')
          .select('*, addresses(*), customer:users!user_id(*)')
          .eq('id', orderId)
          .single();

      currentOrder.value = OrderModel.fromJson(orderResponse);

      final itemsResponse = await supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId);

      orderItems.value = (itemsResponse as List)
          .map((json) => OrderItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching order detail: $e');
      Get.snackbar('Lỗi', 'Không tải được chi tiết đơn: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final updateData = <String, dynamic>{'status': 'cancelled'};
      if (reason != null && reason.isNotEmpty) {
        updateData['cancel_reason'] = reason;
      }
      await supabase.from('orders').update(updateData).eq('id', orderId);
      await fetchOrders();
      Get.snackbar('Thành công', 'Đã hủy đơn hàng',
          backgroundColor: Colors.green, colorText: Colors.white);
      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      Get.snackbar('Lỗi', 'Không thể hủy đơn hàng',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/controller/order_controller.dart
git commit -m "refactor: OrderController v2 - JSONB options, delivery_type, order_code"
```

---

## Task 11: AdminController — bỏ shipper methods, update queries

**Files:**
- Modify: `lib/controller/admin_controller.dart`

- [ ] **Step 1: Xóa assignShipper và getShippers, fix fetchOrders query**

Trong `admin_controller.dart`:
1. Xóa method `assignShipper()`
2. Xóa method `getShippers()`
3. Cập nhật `fetchOrders` bỏ `users!user_id(*)` join alias (dùng inline)

Sửa method `fetchOrders`:
```dart
Future<void> fetchOrders() async {
  try {
    isLoadingOrders.value = true;
    final response = await supabase
        .from('orders')
        .select('*, customer:users!user_id(*), addresses(*)')
        .order('created_at', ascending: false);

    orders.value = (response as List)
        .map((json) => OrderModel.fromJson(json))
        .toList();
  } catch (e) {
    print('Error fetching orders: $e');
  } finally {
    isLoadingOrders.value = false;
  }
}
```

Sửa method `updateOrderStatus` — bỏ `updated_at` manual (trigger tự xử lý):
```dart
Future<void> updateOrderStatus(String orderId, String status) async {
  try {
    await supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
    await fetchOrders();
    await fetchDashboardStats();
    Get.snackbar('Thành công', 'Đã cập nhật trạng thái đơn hàng',
        backgroundColor: Colors.green, colorText: Colors.white);
  } catch (e) {
    print('Error updating order status: $e');
    Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái',
        backgroundColor: Colors.red, colorText: Colors.white);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/controller/admin_controller.dart
git commit -m "refactor: AdminController - remove shipper methods, update order queries"
```

---

## Task 12: ProductDetailPage — load product_options thay vì option_groups

**Files:**
- Modify: `lib/views/user/product_detail_page.dart`

- [ ] **Step 1: Sửa toàn bộ phần options**

Trong `product_detail_page.dart`:

1. Thay imports — bỏ `option_group_model.dart`, `option_item_model.dart`, thêm `product_option_model.dart`
2. Thay state variables:
```dart
// CŨ:
List<OptionGroup> listGroup = [];
Map<String, List<OptionItem>> listItemTheoGroup = {};
Map<String, OptionItem?> selectedSingle = {};
Map<String, Set<OptionItem>> selectedMulti = {};

// MỚI:
List<ProductOption> productOptions = [];
Map<String, OptionValue?> selectedSingle = {}; // optionId → OptionValue?
```

3. Thay `loadOptions()`:
```dart
Future<void> loadOptions() async {
  final supabase = Supabase.instance.client;
  try {
    final res = await supabase
        .from('product_options')
        .select()
        .eq('product_id', widget.product.id)
        .order('created_at');

    productOptions = res
        .map<ProductOption>((m) => ProductOption.fromJson(m))
        .toList();

    for (var opt in productOptions) {
      if (opt.values.isNotEmpty) {
        selectedSingle[opt.id] = opt.values.first;
      }
    }
    setState(() {});
  } catch (e) {
    print('Error loading options: $e');
  }
}
```

4. Thay `tinhGiaSauCung()`:
```dart
double tinhGiaSauCung() {
  double extra = 0;
  for (var val in selectedSingle.values) {
    if (val != null) extra += val.price;
  }
  return widget.product.price + extra;
}
```

5. Thay build section options (thay `listGroup.isNotEmpty` → `productOptions.isNotEmpty`):
```dart
if (productOptions.isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: productOptions.map((opt) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              opt.name + (opt.isRequired ? ' *' : ''),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...opt.values.map((val) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: RadioListTile<String>(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  value: val.label,
                  groupValue: selectedSingle[opt.id]?.label,
                  title: Text(val.label, style: const TextStyle(fontSize: 16)),
                  secondary: Text(
                    val.formattedPrice,
                    style: TextStyle(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                  ),
                  onChanged: (_) => setState(() => selectedSingle[opt.id] = val),
                  activeColor: Colors.green,
                ),
              );
            }),
          ],
        );
      }).toList(),
    ),
  ),
```

6. Thay phần gom options khi nhấn "Thêm vào giỏ":
```dart
onPressed: () async {
  // Gom options đã chọn thành JSONB format
  final List<Map<String, dynamic>> selectedOptions = [];
  for (var opt in productOptions) {
    final val = selectedSingle[opt.id];
    if (val != null) {
      selectedOptions.add({
        'name': opt.name,
        'value': val.label,
        'price': val.price,
      });
    }
  }

  await cartController.addToCart(
    widget.product,
    quantity,
    selectedOptions: selectedOptions,
  );

  if (widget.scrollController != null) {
    Navigator.pop(context);
  } else {
    Get.back();
  }
},
```

7. Thêm import ở đầu file:
```dart
import 'package:xommoigarden/model/product_option_model.dart';
```
Và xóa:
```dart
import 'package:xommoigarden/model/option_group_model.dart';
import 'package:xommoigarden/model/option_item_model.dart';
```

- [ ] **Step 2: Commit**

```bash
git add lib/views/user/product_detail_page.dart
git commit -m "refactor: ProductDetailPage - load product_options JSONB instead of option_groups"
```

---

## Task 13: CheckoutPage — bỏ ShippingMethod, dùng DeliveryType

**Files:**
- Modify: `lib/views/user/checkout_page.dart`

- [ ] **Step 1: Cập nhật CheckoutPage**

1. Xóa `ShippingMethod` import và state variable
2. Thêm `DeliveryType _deliveryType = DeliveryType.delivery;`
3. Thay UI chọn phương thức giao (nếu có):
   - Nút "Giao hàng" (delivery) và "Tự lấy" (pickup)
4. Cập nhật gọi `createOrder()`:
```dart
// CŨ:
await orderController.createOrder(
  addressId: ...,
  paymentMethod: _paymentMethod,
  shippingMethod: _shippingMethod,
  shippingFee: _shippingFee,
  note: _noteController.text,
);

// MỚI:
await orderController.createOrder(
  addressId: ...,
  paymentMethod: _paymentMethod,
  deliveryType: _deliveryType,
  shippingFee: _shippingFee,
  note: _noteController.text,
);
```

5. Cập nhật label hiển thị phí ship (bỏ "Giao nhanh"/"Tiêu chuẩn"):
```dart
Text('Phí giao hàng: ${_shippingFee.toStringAsFixed(0)}đ')
```

- [ ] **Step 2: Commit**

```bash
git add lib/views/user/checkout_page.dart
git commit -m "refactor: CheckoutPage - replace ShippingMethod with DeliveryType"
```

---

## Task 14: OrderDetailPage — bỏ shipper section, hiện order_code

**Files:**
- Modify: `lib/views/user/order_detail_page.dart`

- [ ] **Step 1: Cập nhật OrderDetailPage**

1. Xóa section hiển thị shipper info (nếu có)
2. Thêm hiển thị `order.displayCode` thay vì `order.id.substring(0,8)`
3. Cập nhật options display — từ `opt.optionName` → `opt['value'] ?? opt['label']`:
```dart
// Trong section sản phẩm, khi hiển thị options của item:
if (item.hasOptions)
  Text(
    item.optionsText,
    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
  ),
```
(optionsText đã được cập nhật trong OrderItemModel Task 7)

4. Cập nhật hiển thị cancel_reason nếu đơn bị hủy:
```dart
if (order.isCancelled && order.cancelReason != null)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      'Lý do hủy: ${order.cancelReason}',
      style: const TextStyle(color: Colors.red, fontSize: 13),
    ),
  ),
```

- [ ] **Step 2: Commit**

```bash
git add lib/views/user/order_detail_page.dart
git commit -m "refactor: OrderDetailPage - remove shipper section, show order_code, show cancel_reason"
```

---

## Task 15: AdminOrders — bỏ shipper assignment UI

**Files:**
- Modify: `lib/views/admin/admin_orders.dart`

- [ ] **Step 1: Xóa shipper assignment UI**

Trong admin_orders.dart:
1. Xóa nút/dialog "Giao đơn cho shipper"
2. Xóa bất kỳ reference đến `shipper_id` hay `assignShipper`
3. Cập nhật hiển thị đơn hàng: thêm `order.displayCode` thay vì `order.id.substring(0,8)`
4. Cập nhật dropdown status change để không bao gồm option liên quan đến shipper

- [ ] **Step 2: Commit**

```bash
git add lib/views/admin/admin_orders.dart
git commit -m "refactor: AdminOrders - remove shipper assignment"
```

---

## Task 16: AdminUsers — bỏ shipper role filter

**Files:**
- Modify: `lib/views/admin/admin_users.dart`

- [ ] **Step 1: Xóa shipper filter chip và shipper-specific UI**

Trong admin_users.dart:
1. Xóa filter chip "Shipper" khỏi role filter row
2. Xóa bất kỳ display của shipper-specific fields (isAvailable, vehicleType, shipperRating, totalDeliveries)
3. Cập nhật role badge: chỉ hiển thị admin (đỏ) và customer (xanh)

- [ ] **Step 2: Commit**

```bash
git add lib/views/admin/admin_users.dart
git commit -m "refactor: AdminUsers - remove shipper role filter and fields"
```

---

## Task 17: Xóa các file model cũ không còn dùng

**Files:**
- Delete: `lib/model/option_group_model.dart`
- Delete: `lib/model/option_item_model.dart`
- Delete: `lib/model/cart_item_option_model.dart`
- Delete: `lib/model/order_item_option_model.dart`

- [ ] **Step 1: Xóa files**

```bash
rm lib/model/option_group_model.dart
rm lib/model/option_item_model.dart
rm lib/model/cart_item_option_model.dart
rm lib/model/order_item_option_model.dart
```

- [ ] **Step 2: Kiểm tra không còn import nào bị hỏng**

```bash
flutter analyze 2>&1 | grep -E "error:|warning:"
```

Fix bất kỳ import còn sót lại.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: delete obsolete option/cart_item_option/order_item_option models"
```

---

## Task 18: Final — flutter analyze + kiểm tra compile

- [ ] **Step 1: Chạy analyze**

```bash
flutter analyze
```

Expected: No errors.

- [ ] **Step 2: Build check**

```bash
flutter build apk --debug 2>&1 | tail -20
```

Expected: Build succeeded.

- [ ] **Step 3: Commit tổng kết nếu cần**

```bash
git add -A
git commit -m "fix: resolve any remaining compile errors after schema v2 migration"
```

---

## Self-Review

**Spec coverage:**
- ✅ `user_role` bỏ shipper → Task 1 (enums) + Task 2 (UserModel) + Task 16 (AdminUsers)
- ✅ `product_options` JSONB values → Task 5 (model) + Task 12 (ProductDetailPage)
- ✅ `cart_items.options` JSONB → Task 6 (CartItemModel) + Task 9 (CartController)
- ✅ `order_items.options` JSONB + product_name → Task 7 (OrderItemModel) + Task 10 (OrderController)
- ✅ `orders` new fields (order_code, subtotal, delivery_type, cancel_reason...) → Task 8 (OrderModel) + Task 10 (OrderController)
- ✅ `addresses` new fields (label, recipient_name, recipient_phone) → Task 3
- ✅ `categories` new fields (image_url, display_order, is_active) → Task 4
- ✅ Admin bỏ shipper → Task 11 (AdminController) + Task 15 (AdminOrders) + Task 16 (AdminUsers)
- ✅ Xóa obsolete models → Task 17
- ✅ Build verify → Task 18

**Gaps:** Không có — tất cả breaking changes đều được cover.
