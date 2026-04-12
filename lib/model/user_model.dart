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
  final bool isAvailable;
  final VehicleType? vehicleType;
  final double shipperRating;
  final int totalDeliveries;
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
    this.isAvailable = false,
    this.vehicleType,
    this.shipperRating = 5.0,
    this.totalDeliveries = 0,
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
      isAvailable: json['is_available'] as bool? ?? false,
      vehicleType: json['vehicle_type'] != null
          ? VehicleType.fromString(json['vehicle_type'])
          : null,
      shipperRating: (json['shipper_rating'] as num?)?.toDouble() ?? 5.0,
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
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
      'is_available': isAvailable,
      'vehicle_type': vehicleType?.value,
      'shipper_rating': shipperRating,
      'total_deliveries': totalDeliveries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy với các tham số thay đổi
  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    UserStatus? status,
    int? loyaltyPoints,
    bool? isAvailable,
    VehicleType? vehicleType,
    double? shipperRating,
    int? totalDeliveries,
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
      isAvailable: isAvailable ?? this.isAvailable,
      vehicleType: vehicleType ?? this.vehicleType,
      shipperRating: shipperRating ?? this.shipperRating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper để kiểm tra role
  bool get isCustomer => role == UserRole.customer;
  bool get isShipper => role == UserRole.shipper;
  bool get isAdmin => role == UserRole.admin;
}