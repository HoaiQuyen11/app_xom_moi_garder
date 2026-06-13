// lib/model/voucher_model.dart
enum DiscountType {
  percent,
  fixed;

  String get value => name;
  static DiscountType fromString(String value) => DiscountType.values
      .firstWhere((e) => e.name == value, orElse: () => DiscountType.fixed);
}

class VoucherModel {
  final String id;
  final String code;
  final String? description;
  final DiscountType discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final int? usageLimit;
  final int usedCount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;

  VoucherModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.usageLimit,
    this.usedCount = 0,
    this.expiresAt,
    this.isActive = true,
    required this.createdAt,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: DiscountType.fromString(json['discount_type'] ?? 'fixed'),
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      usageLimit: json['usage_limit'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'discount_type': discountType.value,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      'max_discount': maxDiscount,
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUsageLimitReached =>
      usageLimit != null && usedCount >= usageLimit!;
  bool get canUse => isActive && !isExpired && !isUsageLimitReached;
}
