// lib/services/map_service.dart
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:xommoigarden/config/shop_config.dart';

class RouteResult {
  final double distanceKm;
  final double durationMinutes;
  final List<LatLng> polyline;

  RouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polyline,
  });
}

class MapService {
  static const String _osrmBase = 'https://router.project-osrm.org/route/v1/driving';
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';

  // Lấy đường đi + khoảng cách từ OSRM
  static Future<RouteResult?> getRoute(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        '$_osrmBase/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data['routes'] == null || (data['routes'] as List).isEmpty) return null;

      final route = data['routes'][0];
      final coords = route['geometry']['coordinates'] as List;

      return RouteResult(
        distanceKm: (route['distance'] as num).toDouble() / 1000,
        durationMinutes: (route['duration'] as num).toDouble() / 60,
        polyline: coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList(),
      );
    } catch (e) {
      return null;
    }
  }

  // Reverse geocoding: lat/lng → địa chỉ
  static Future<String?> reverseGeocode(LatLng point) async {
    try {
      final url = Uri.parse(
        '$_nominatimBase/reverse?lat=${point.latitude}&lon=${point.longitude}'
        '&format=json&accept-language=vi',
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'XomMoiGarden/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      return data['display_name'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Search địa chỉ → lat/lng (giới hạn trong viewbox)
  static Future<List<GeocodeResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_nominatimBase/search?q=${Uri.encodeQueryComponent(query)}'
        '&format=json&limit=10&countrycodes=vn&accept-language=vi'
        '&viewbox=${ShopConfig.searchViewbox}&bounded=1'
        '&addressdetails=1',
      );

      final res = await http.get(
        url,
        headers: {'User-Agent': 'XomMoiGarden/1.0'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as List;
      return data.map((item) {
        final point = LatLng(
          double.parse(item['lat'] as String),
          double.parse(item['lon'] as String),
        );

        // Tính khoảng cách đường chim bay từ shop
        final distanceKm = const Distance().as(
          LengthUnit.Kilometer,
          ShopConfig.location,
          point,
        );

        // Parse tên chính: ưu tiên 'name', fallback phần đầu display_name
        final displayName = item['display_name'] as String;
        String mainName = item['name'] as String? ?? '';
        if (mainName.isEmpty) {
          mainName = displayName.split(',').first.trim();
        }

        return GeocodeResult(
          mainName: mainName,
          displayName: displayName,
          point: point,
          distanceKm: distanceKm,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Lấy vị trí hiện tại (GPS)
  static Future<LatLng?> getCurrentLocation() async {
    try {
      // Kiểm tra GPS bật chưa
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Kiểm tra quyền
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  // Tính phí ship theo khoảng cách
  static double calculateShippingFee(double distanceKm, {bool isFast = false}) {
    double fee = ShopConfig.baseFee;
    if (distanceKm > ShopConfig.baseDistanceKm) {
      fee += (distanceKm - ShopConfig.baseDistanceKm) * ShopConfig.feePerKm;
    }
    if (isFast) fee *= ShopConfig.fastMultiplier;
    return fee.roundToDouble();
  }

  // Kiểm tra có giao được không
  static bool isDeliverable(double distanceKm) {
    return distanceKm <= ShopConfig.maxDistanceKm;
  }
}

class GeocodeResult {
  final String mainName;
  final String displayName;
  final LatLng point;
  final double distanceKm;

  GeocodeResult({
    required this.mainName,
    required this.displayName,
    required this.point,
    required this.distanceKm,
  });

  String get distanceLabel {
    if (distanceKm < 1) return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    return '${distanceKm.toStringAsFixed(1)}km';
  }
}
