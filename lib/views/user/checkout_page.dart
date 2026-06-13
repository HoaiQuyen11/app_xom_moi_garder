// lib/views/user/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:xommoigarden/config/shop_config.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/controller/cart_controller.dart';
import 'package:xommoigarden/controller/order_controller.dart';
import 'package:xommoigarden/controller/address_controller.dart';
import 'package:xommoigarden/controller/voucher_controller.dart';
import 'package:xommoigarden/model/address_model.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/services/map_service.dart';
import 'add_address_page.dart';
import 'order_success_page.dart';
import 'select_address_page.dart';
import 'voucher_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final ControllerCart cartController = Get.find<ControllerCart>();
  final ControllerOrder orderController = Get.find<ControllerOrder>();
  final ControllerAuth authController = Get.find<ControllerAuth>();
  final ControllerAddress addressController = Get.put(ControllerAddress());
  final ControllerVoucher voucherController = Get.find<ControllerVoucher>();

  AddressModel? selectedAddress;
  DeliveryType selectedDeliveryType = DeliveryType.delivery;
  PaymentMethod selectedPaymentMethod = PaymentMethod.cod;
  bool useLoyaltyPoints = false;
  String note = '';

  final TextEditingController noteController = TextEditingController();

  RouteResult? routeResult;
  bool isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    await addressController.fetchAddresses();
    if (!mounted) return;

    if (selectedAddress == null && addressController.addresses.isNotEmpty) {
      final defaultAddr =
          addressController.addresses.firstWhereOrNull((a) => a.isDefault) ??
          addressController.addresses.first;
      setState(() => selectedAddress = defaultAddr);
      _fetchRoute(defaultAddr);
    }
  }

  Future<void> _pickAddress() async {
    final result = await Get.to<AddressModel>(
      () => SelectAddressPage(currentSelected: selectedAddress),
    );
    if (result != null) {
      setState(() => selectedAddress = result);
      _fetchRoute(result);
    }
  }

  double get subtotal => cartController.totalAmount;

  double get shippingFee {
    if (routeResult != null) {
      return MapService.calculateShippingFee(routeResult!.distanceKm);
    }
    return ShopConfig.baseFee;
  }

  double get discountAmount {
    final applied = voucherController.appliedVoucher.value;
    if (applied == null) return 0;
    return voucherController.calculateDiscount(applied.voucher, subtotal);
  }

  int get availableLoyaltyPoints =>
      authController.currentUser.value?.loyaltyPoints ?? 0;

  int get maxUsableLoyaltyPoints {
    final fee = selectedDeliveryType == DeliveryType.pickup ? 0.0 : shippingFee;
    final remaining = subtotal + fee - discountAmount;
    if (remaining <= 0 || availableLoyaltyPoints <= 0) return 0;
    return availableLoyaltyPoints.clamp(0, remaining.floor()).toInt();
  }

  int get loyaltyPointsToUse {
    if (!useLoyaltyPoints) return 0;
    return maxUsableLoyaltyPoints;
  }

  double get loyaltyDiscountAmount => loyaltyPointsToUse.toDouble();

  double get total =>
      subtotal + shippingFee - discountAmount - loyaltyDiscountAmount;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute(AddressModel address) async {
    if (address.lat == null || address.lng == null) {
      setState(() => routeResult = null);
      return;
    }

    setState(() => isLoadingRoute = true);
    final result = await MapService.getRoute(
      ShopConfig.location,
      LatLng(address.lat!, address.lng!),
    );
    setState(() {
      routeResult = result;
      isLoadingRoute = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Xác Nhận - Thanh Toán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (cartController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cartController.cartItems.isEmpty) {
          return _buildEmptyCart();
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeliveryInfo(),
              if (selectedAddress != null && selectedAddress!.lat != null)
                _buildRouteMap(),
              _buildDeliveryTypeSection(),
              _buildPaymentMethod(),
              _buildOrderItems(),
              _buildNoteSection(),
              _buildVoucherSection(),
              Obx(() => _buildLoyaltySection()),
              Obx(() => _buildSummary()),
              _buildPlaceOrderButton(),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Giỏ hàng trống',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm sản phẩm vào giỏ hàng',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tiếp tục mua sắm'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final user = authController.currentUser.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Thông tin nhận hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _pickAddress,
                child: Text(
                  'Thay đổi',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (selectedAddress == null)
            _buildNoAddress()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: user?.fullName ?? 'Khách hàng',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '  -  ',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      TextSpan(
                        text: user?.phone ?? '---',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedAddress!.fullAddress,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNoAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.location_off, color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Chưa có địa chỉ giao hàng',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            await Get.to(() => const AddAddressPage());
            await _loadAddresses();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Thêm địa chỉ giao hàng'),
          style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
        ),
      ],
    );
  }

  Widget _buildRouteMap() {
    final customer = LatLng(selectedAddress!.lat!, selectedAddress!.lng!);
    final bounds = LatLngBounds.fromPoints([ShopConfig.location, customer]);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.map, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Đường đi giao hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isLoadingRoute)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(40),
                      ),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.xommoigarden.app',
                      ),
                      if (routeResult != null)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routeResult!.polyline,
                              strokeWidth: 4,
                              color: Colors.green.shade700,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: ShopConfig.location,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.store,
                              color: Colors.orange,
                              size: 36,
                            ),
                          ),
                          Marker(
                            point: customer,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (routeResult != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.near_me,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${routeResult!.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '~${routeResult!.durationMinutes.toStringAsFixed(0)} phút',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (!MapService.isDeliverable(
                              routeResult!.distanceKm,
                            ))
                              Text(
                                'Ngoài vùng giao',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTypeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình thức nhận hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          RadioListTile<DeliveryType>(
            title: const Text('Giao hàng tận nơi'),
            subtitle: Text(
              routeResult != null
                  ? '${shippingFee.toStringAsFixed(0)}đ · ${routeResult!.distanceKm.toStringAsFixed(1)} km'
                  : '${shippingFee.toStringAsFixed(0)}đ (tạm tính)',
            ),
            value: DeliveryType.delivery,
            groupValue: selectedDeliveryType,
            onChanged: (value) => setState(() => selectedDeliveryType = value!),
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<DeliveryType>(
            title: const Text('Tự đến lấy'),
            subtitle: const Text('Miễn phí giao hàng'),
            value: DeliveryType.pickup,
            groupValue: selectedDeliveryType,
            onChanged: (value) => setState(() => selectedDeliveryType = value!),
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
          if (routeResult == null && selectedAddress != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Phí tạm tính — chọn địa chỉ có GPS để tính phí thật',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình thức thanh toán',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          RadioListTile<PaymentMethod>(
            title: const Text('Thanh toán tiền mặt'),
            value: PaymentMethod.cod,
            groupValue: selectedPaymentMethod,
            onChanged: (value) =>
                setState(() => selectedPaymentMethod = value!),
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
          // RadioListTile<PaymentMethod>(
          //   title: const Text('Viettel Money'),
          //   value: PaymentMethod.viettel,
          //   groupValue: selectedPaymentMethod,
          //   onChanged: (value) => setState(() => selectedPaymentMethod = value!),
          //   activeColor: Colors.green,
          //   contentPadding: EdgeInsets.zero,
          // ),
          // RadioListTile<PaymentMethod>(
          //   title: const Text('Chuyển khoản ngân hàng'),
          //   value: PaymentMethod.banking,
          //   groupValue: selectedPaymentMethod,
          //   onChanged: (value) => setState(() => selectedPaymentMethod = value!),
          //   activeColor: Colors.green,
          //   contentPadding: EdgeInsets.zero,
          // ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Obx(() {
      final applied = voucherController.appliedVoucher.value;
      final trailingText = applied == null
          ? 'Chọn hoặc nhập mã'
          : '${applied.voucher.code} - Giảm ${discountAmount.toStringAsFixed(0)}đ';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Get.to(() => VoucherPage(subtotal: subtotal)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.red.shade400,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Voucher',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trailingText,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: applied == null
                          ? Colors.grey.shade500
                          : Colors.green.shade700,
                      fontWeight: applied == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLoyaltySection() {
    final points = availableLoyaltyPoints;
    final usablePoints = maxUsableLoyaltyPoints;
    final canUse = usablePoints > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.shade50,
              ),
              child: Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.orange.shade600,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                points <= 0
                    ? 'Bạn chưa có Tích điểm'
                    : 'Dùng $usablePoints Tích điểm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Switch(
              value: useLoyaltyPoints && canUse,
              onChanged: canUse
                  ? (value) => setState(() => useLoyaltyPoints = value)
                  : null,
              activeThumbColor: Colors.green,
              activeTrackColor: Colors.green.shade100,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade200,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin đơn hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...cartController.cartItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.product?.imageUrl != null
                        ? Image.network(
                            item.product!.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.fastfood, size: 30),
                                ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood, size: 30),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product?.name ?? 'Sản phẩm',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.hasOptions) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.optionsText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '× ${item.quantity}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              item.formattedSubtotal,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính:', style: TextStyle(fontSize: 14)),
              Text(
                '${subtotal.toStringAsFixed(0)}đ',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú cho shop',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (value) => note = value,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final fee = selectedDeliveryType == DeliveryType.pickup ? 0.0 : shippingFee;
    final discount = discountAmount;
    final pointDiscount = loyaltyDiscountAmount;
    final totalVal = subtotal + fee - discount - pointDiscount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Tạm tính (${cartController.totalQuantity} sản phẩm):',
            '${subtotal.toStringAsFixed(0)}đ',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Phí vận chuyển:',
            selectedDeliveryType == DeliveryType.pickup
                ? 'Miễn phí'
                : '${fee.toStringAsFixed(0)}đ',
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Mã giảm giá:',
              '-${discount.toStringAsFixed(0)}đ',
              valueColor: Colors.green.shade700,
            ),
          ],
          if (pointDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Điểm tích lũy:',
              '-${pointDiscount.toStringAsFixed(0)}đ',
              valueColor: Colors.green.shade700,
            ),
          ],
          const Divider(height: 24),
          _buildSummaryRow(
            'Tổng tiền',
            '${totalVal.clamp(0, double.infinity).toStringAsFixed(0)}đ',
            isTotal: true,
            valueColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? (isTotal ? Colors.red : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    final fee = selectedDeliveryType == DeliveryType.pickup ? 0.0 : shippingFee;

    return Container(
      margin: const EdgeInsets.all(12),
      child: Obx(
        () => ElevatedButton(
          onPressed: orderController.isLoading.value || selectedAddress == null
              ? null
              : () async {
                  if (selectedAddress == null) {
                    Get.snackbar(
                      'Lỗi',
                      'Vui lòng chọn địa chỉ giao hàng',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (cartController.cartItems.isEmpty) {
                    Get.snackbar(
                      'Lỗi',
                      'Giỏ hàng trống',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (routeResult != null &&
                      !MapService.isDeliverable(routeResult!.distanceKm) &&
                      selectedDeliveryType == DeliveryType.delivery) {
                    Get.snackbar(
                      'Lỗi',
                      'Địa chỉ giao hàng vượt quá bán kính ${ShopConfig.maxDistanceKm.toStringAsFixed(0)} km',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  final confirm = await Get.dialog<bool>(
                    AlertDialog(
                      title: const Text('Xác nhận đặt hàng'),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Hủy'),
                            ),

                            ElevatedButton(
                              onPressed: () => Get.back(result: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  final applied = voucherController.appliedVoucher.value;
                  if (applied != null) {
                    final validationMessage = voucherController.validateVoucher(
                      applied.voucher,
                      subtotal,
                    );
                    if (validationMessage != null) {
                      voucherController.clearAppliedVoucher();
                      Get.snackbar(
                        'Không áp dụng được mã',
                        validationMessage,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }
                  }

                  final success = await orderController.createOrder(
                    addressId: selectedAddress!.id,
                    paymentMethod: selectedPaymentMethod,
                    deliveryType: selectedDeliveryType,
                    shippingFee: fee,
                    voucherId: applied?.voucher.id,
                    discountAmount: applied == null ? 0 : discountAmount,
                    loyaltyPointsToUse: loyaltyPointsToUse,
                    note: note,
                  );

                  if (success) {
                    voucherController.clearAppliedVoucher();
                    Get.offAll(() => const OrderSuccessPage());
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: orderController.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'ĐẶT HÀNG',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
