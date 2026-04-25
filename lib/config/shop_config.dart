// lib/config/shop_config.dart
import 'package:latlong2/latlong.dart';

class ShopConfig {
  // Vị trí cửa hàng: 144 Võ Trứ, Tân Tiến, Nha Trang, Khánh Hòa
  static const LatLng location = LatLng(12.2427063, 109.1899543);

  static const String name = 'Xóm Mới Garden';
  static const String address = '144 Võ Trứ, Tân Tiến, Nha Trang, Khánh Hòa';

  // Viewbox giới hạn tìm kiếm Nominatim trong Khánh Hòa
  // Format: lon_min, lat_min, lon_max, lat_max
  static const String searchViewbox = '108.80,11.80,109.55,12.70';

  // Phí ship
  static const double baseFee = 15000;
  static const double baseDistanceKm = 2.0;
  static const double feePerKm = 5000;
  static const double fastMultiplier = 2.0;
  static const double maxDistanceKm = 30.0;
}
