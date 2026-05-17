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
