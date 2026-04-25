// lib/views/user/add_address_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:xommoigarden/config/shop_config.dart';
import 'package:xommoigarden/controller/address_controller.dart';
import 'package:xommoigarden/services/map_service.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final ControllerAddress addressController = Get.find();
  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController detailCtrl = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  final box = GetStorage();
  static const String _recentKey = 'recent_address_searches';

  List<GeocodeResult> results = [];
  List<Map<String, dynamic>> recentSearches = [];
  bool isSearching = false;
  Timer? _searchDebounce;

  // Current location
  String? currentLocationAddress;
  LatLng? currentLocationPoint;
  bool isLoadingCurrentLocation = false;

  // Confirm mode
  GeocodeResult? selectedResult;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => isLoadingCurrentLocation = true);
    final point = await MapService.getCurrentLocation();
    if (point == null) {
      if (mounted) setState(() => isLoadingCurrentLocation = false);
      return;
    }

    final address = await MapService.reverseGeocode(point);

    if (mounted) {
      setState(() {
        currentLocationPoint = point;
        currentLocationAddress = address;
        isLoadingCurrentLocation = false;
      });
    }
  }

  void _useCurrentLocation() {
    if (currentLocationPoint == null || currentLocationAddress == null) {
      // Thử lấy lại vị trí
      _loadCurrentLocation();
      return;
    }

    final distanceKm = const Distance().as(
      LengthUnit.Kilometer,
      ShopConfig.location,
      currentLocationPoint!,
    );

    final firstComma = currentLocationAddress!.indexOf(',');
    final mainName = firstComma > 0
        ? currentLocationAddress!.substring(0, firstComma).trim()
        : 'Vị trí hiện tại';

    final r = GeocodeResult(
      mainName: mainName,
      displayName: currentLocationAddress!,
      point: currentLocationPoint!,
      distanceKm: distanceKm,
    );
    _selectResult(r);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchCtrl.dispose();
    detailCtrl.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void _loadRecent() {
    final saved = box.read<List>(_recentKey);
    if (saved != null) {
      recentSearches = saved.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  void _saveRecent(GeocodeResult r) {
    recentSearches.removeWhere((e) => e['display_name'] == r.displayName);
    recentSearches.insert(0, {
      'main_name': r.mainName,
      'display_name': r.displayName,
      'lat': r.point.latitude,
      'lng': r.point.longitude,
      'distance_km': r.distanceKm,
    });
    if (recentSearches.length > 10) recentSearches = recentSearches.take(10).toList();
    box.write(_recentKey, recentSearches);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => results = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => isSearching = true);
      final data = await MapService.searchAddress(value);
      if (mounted) {
        setState(() {
          results = data;
          isSearching = false;
        });
      }
    });
  }

  void _selectResult(GeocodeResult r) {
    _saveRecent(r);
    setState(() {
      selectedResult = r;
      detailCtrl.text = r.displayName;
    });
    searchFocus.unfocus();
  }

  void _selectRecent(Map<String, dynamic> item) {
    final r = GeocodeResult(
      mainName: item['main_name'] as String,
      displayName: item['display_name'] as String,
      point: LatLng((item['lat'] as num).toDouble(), (item['lng'] as num).toDouble()),
      distanceKm: (item['distance_km'] as num).toDouble(),
    );
    _selectResult(r);
  }

  Future<void> _saveAddress() async {
    if (selectedResult == null) return;
    if (detailCtrl.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập địa chỉ chi tiết');
      return;
    }

    await addressController.addAddress(
      detailCtrl.text.trim(),
      selectedResult!.point.latitude,
      selectedResult!.point.longitude,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: selectedResult == null ? _buildSearchMode() : _buildConfirmMode(),
    );
  }

  // ==================== SEARCH MODE ====================

  Widget _buildSearchMode() {
    return SafeArea(
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                ),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.green.shade600, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.location_on, color: Colors.red.shade600, size: 22),
                        ),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            focusNode: searchFocus,
                            autofocus: true,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Giao tới',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              searchCtrl.clear();
                              setState(() => results = []);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.cancel, color: Colors.grey.shade400, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (isSearching)
            const LinearProgressIndicator(minHeight: 2),

          // Content
          Expanded(
            child: searchCtrl.text.trim().isEmpty
                ? _buildDefaultList()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationItem() {
    return InkWell(
      onTap: _useCurrentLocation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: Icon(Icons.gps_fixed, size: 22, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vị trí hiện tại',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  if (isLoadingCurrentLocation)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đang lấy vị trí...',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    )
                  else if (currentLocationAddress != null)
                    Text(
                      currentLocationAddress!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Nhấn để lấy vị trí hiện tại',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.more_vert, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultList() {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        // Tabs header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildTabLabel('Dùng gần đây', true),
              const SizedBox(width: 24),
              _buildTabLabel('Đề xuất', false),
              const SizedBox(width: 24),
              _buildTabLabel('Đã lưu', false),
            ],
          ),
        ),
        const Divider(height: 1),

        // Current location
        _buildCurrentLocationItem(),
        Divider(height: 1, color: Colors.grey.shade200),

        // Recent searches
        if (recentSearches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Chưa có lịch sử tìm kiếm',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ),
          )
        else
          ...recentSearches.map((item) => _buildRecentItem(item)),

        // Help section
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Cần trợ giúp?',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 14),
          ),
        ),
        _buildHelpTile(
          icon: Icons.gps_fixed,
          text: 'Vẫn không tìm thấy địa điểm bạn muốn?\nHãy thử tìm với từ khóa đầy đủ hơn.',
        ),
        _buildHelpTile(
          icon: Icons.edit_note,
          text: 'Bạn có thể nhập "tên đường + phường + Nha Trang" để kết quả chính xác hơn.',
        ),
      ],
    );
  }

  Widget _buildTabLabel(String text, bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      );
    }
    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
    );
  }

  Widget _buildRecentItem(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => _selectRecent(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_outlined, size: 20, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['main_name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['display_name'] as String,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (results.isEmpty && !isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Không tìm thấy địa điểm', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text(
              'Thử tìm với từ khóa khác',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) => _buildResultItem(results[index]),
    );
  }

  Widget _buildResultItem(GeocodeResult r) {
    return InkWell(
      onTap: () => _selectResult(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, size: 20, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.distanceLabel,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(' · ', style: TextStyle(color: Colors.grey.shade400)),
                      Expanded(
                        child: Text(
                          r.mainName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.displayName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ==================== CONFIRM MODE ====================

  Widget _buildConfirmMode() {
    final customer = selectedResult!.point;
    final bounds = LatLngBounds.fromPoints([ShopConfig.location, customer]);
    final fee = MapService.calculateShippingFee(selectedResult!.distanceKm);
    final deliverable = MapService.isDeliverable(selectedResult!.distanceKm);

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => selectedResult = null),
                ),
                const Text('Xác nhận địa chỉ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Map
          SizedBox(
            height: 260,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.xommoigarden.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ShopConfig.location,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.store, color: Colors.orange, size: 36),
                    ),
                    Marker(
                      point: customer,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info & detail form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: deliverable ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: deliverable ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        deliverable ? Icons.check_circle : Icons.error_outline,
                        color: deliverable ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deliverable
                                  ? 'Giao được · ${selectedResult!.distanceLabel}'
                                  : 'Ngoài vùng giao hàng (>${ShopConfig.maxDistanceKm.toStringAsFixed(0)}km)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: deliverable ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                            if (deliverable)
                              Text(
                                'Phí ship tạm tính: ${fee.toStringAsFixed(0)}đ',
                                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main name display
                Text(
                  selectedResult!.mainName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedResult!.displayName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Detail input
                const Text(
                  'Địa chỉ chi tiết',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: detailCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Số nhà, tên đường, ghi chú cho shipper...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => ElevatedButton(
              onPressed: (addressController.isLoading.value || !deliverable) ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: addressController.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Xác nhận địa chỉ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
          ),
        ],
      ),
    );
  }
}
