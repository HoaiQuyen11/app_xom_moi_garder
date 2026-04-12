// lib/views/user/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/controller/cart_controller.dart';
import 'package:xommoigarden/controller/order_controller.dart';
import 'package:xommoigarden/controller/address_controller.dart';
import 'package:xommoigarden/model/address_model.dart';
import 'package:xommoigarden/model/enums.dart';
import 'add_address_page.dart';
import 'order_success_page.dart';

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

  // Selected values
  AddressModel? selectedAddress;
  ShippingMethod selectedShippingMethod = ShippingMethod.standard;
  PaymentMethod selectedPaymentMethod = PaymentMethod.cod;
  String note = '';

  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    addressController.fetchAddresses();
  }

  double get subtotal {
    return cartController.totalAmount;
  }

  double get shippingFee {
    return selectedShippingMethod.fee;
  }

  double get total {
    return subtotal + shippingFee;
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
              _buildShippingMethod(),
              _buildPaymentMethod(),
              _buildOrderItems(),
              _buildNoteSection(),
              _buildSummary(),
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
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
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
    return Container(
      margin: const EdgeInsets.all(12),
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
            'Thông tin nhận hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (addressController.addresses.isEmpty)
            _buildEmptyAddress()
          else
            _buildAddressList(),
        ],
      ),
    );
  }

  Widget _buildEmptyAddress() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  authController.currentUser.value?.fullName ?? 'Chưa có địa chỉ',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            await Get.to(() => const AddAddressPage());
            addressController.fetchAddresses();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Thêm địa chỉ giao hàng'),
          style: TextButton.styleFrom(foregroundColor: Colors.green),
        ),
      ],
    );
  }

  Widget _buildAddressList() {
    return Column(
      children: [
        ...addressController.addresses.map((address) {
          final isSelected = selectedAddress?.id == address.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: RadioListTile<AddressModel>(
              title: Text(
                authController.currentUser.value?.fullName ?? 'Khách hàng',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authController.currentUser.value?.phone ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              value: address,
              groupValue: selectedAddress,
              onChanged: (value) {
                setState(() {
                  selectedAddress = value;
                });
              },
              activeColor: Colors.green,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () async {
            await Get.to(() => const AddAddressPage());
            addressController.fetchAddresses();
          },
          icon: const Icon(Icons.add_location, size: 18),
          label: const Text('Thêm địa chỉ mới'),
          style: TextButton.styleFrom(foregroundColor: Colors.green),
        ),
      ],
    );
  }

  Widget _buildShippingMethod() {
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
            'Hình thức giao hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          RadioListTile<ShippingMethod>(
            title: const Text('Giao hàng tiêu chuẩn'),
            subtitle: Text('${ShippingMethod.standard.fee.toStringAsFixed(0)}đ'),
            value: ShippingMethod.standard,
            groupValue: selectedShippingMethod,
            onChanged: (value) {
              setState(() {
                selectedShippingMethod = value!;
              });
            },
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<ShippingMethod>(
            title: const Text('FAST Giao Tiết Kiệm'),
            subtitle: Text('${ShippingMethod.fast.fee.toStringAsFixed(0)}đ'),
            value: ShippingMethod.fast,
            groupValue: selectedShippingMethod,
            onChanged: (value) {
              setState(() {
                selectedShippingMethod = value!;
              });
            },
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          RadioListTile<PaymentMethod>(
            title: const Text('Thanh toán tiền mặt'),
            value: PaymentMethod.cod,
            groupValue: selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value!;
              });
            },
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<PaymentMethod>(
            title: const Text('Viettel Money'),
            value: PaymentMethod.viettel_money,
            groupValue: selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value!;
              });
            },
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<PaymentMethod>(
            title: const Text('Chuyển khoản ngân hàng'),
            value: PaymentMethod.banking,
            groupValue: selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value!;
              });
            },
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
        ],
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, size: 30),
                        );
                      },
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
                        const SizedBox(height: 4),
                        if (item.options != null && item.options!.isNotEmpty)
                          Text(
                            item.optionsText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              note = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
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
          _buildSummaryRow('Tạm tính (${cartController.totalQuantity} sản phẩm):', '${subtotal.toStringAsFixed(0)}đ'),
          const SizedBox(height: 8),
          _buildSummaryRow('Phí vận chuyển:', '${shippingFee.toStringAsFixed(0)}đ'),
          const Divider(height: 24),
          _buildSummaryRow(
            'Tổng tiền',
            '${total.toStringAsFixed(0)}đ',
            isTotal: true,
            valueColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
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
    return Container(
      margin: const EdgeInsets.all(12),
      child: ElevatedButton(
        onPressed: orderController.isLoading.value || selectedAddress == null
            ? null
            : () async {
          // Kiểm tra lại trước khi đặt hàng
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

          // Hiển thị dialog xác nhận
          final confirm = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Xác nhận đặt hàng'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vui lòng kiểm tra lại thông tin:'),
                  const SizedBox(height: 12),
                  Text('• Địa chỉ: ${selectedAddress!.fullAddress}'),
                  Text('• Phương thức thanh toán: ${selectedPaymentMethod.displayName}'),
                  Text('• Tổng tiền: ${total.toStringAsFixed(0)}đ'),
                ],
              ),
              actions: [
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
          );

          if (confirm != true) return;

          // Tạo đơn hàng
          final success = await orderController.createOrder(
            addressId: selectedAddress!.id,
            paymentMethod: selectedPaymentMethod,
            shippingMethod: selectedShippingMethod,
            note: note,
          );

          if (success) {
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
    );
  }
}