// // lib/pages/order_page.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:xommoigarden/controller/address_controller.dart';
// import 'package:xommoigarden/controller/cart_controller.dart';
// import 'package:xommoigarden/controller/order_controller.dart';
// import 'package:xommoigarden/model/address_model.dart';
// import 'package:xommoigarden/model/enums.dart';
// import 'package:xommoigarden/views/user/add_address_page.dart';
// import 'package:xommoigarden/views/user/order_success_page.dart';
//
// class OrderPage extends StatefulWidget {
//   const OrderPage({super.key});
//
//   @override
//   State<OrderPage> createState() => _OrderPageState();
// }
//
// class _OrderPageState extends State<OrderPage> {
//   final ControllerCart cartController = Get.find();
//   final ControllerOrder orderController = Get.find();
//   final ControllerAddress addressController = Get.put(ControllerAddress());
//
//   AddressModel? selectedAddress;
//   PaymentMethod selectedPaymentMethod = PaymentMethod.cod;
//   String? selectedPaymentMethodValue;
//
//   @override
//   void initState() {
//     super.initState();
//     addressController.fetchAddresses();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Xác nhận đơn hàng'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: Obx(() {
//         if (addressController.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Địa chỉ giao hàng
//               _buildAddressSection(),
//               const SizedBox(height: 24),
//
//               // Danh sách sản phẩm
//               _buildOrderItems(),
//               const SizedBox(height: 24),
//
//               // Phương thức thanh toán
//               _buildPaymentSection(),
//               const SizedBox(height: 24),
//
//               // Tổng kết đơn hàng
//               _buildOrderSummary(),
//               const SizedBox(height: 24),
//
//               // Nút đặt hàng
//               _buildPlaceOrderButton(),
//               const SizedBox(height: 16),
//             ],
//           ),
//         );
//       }),
//     );
//   }
//
//   Widget _buildAddressSection() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Icon(Icons.location_on, color: Colors.green),
//                 SizedBox(width: 8),
//                 Text(
//                   'Địa chỉ giao hàng',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//
//           if (addressController.addresses.isEmpty)
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   const Text('Chưa có địa chỉ giao hàng'),
//                   const SizedBox(height: 8),
//                   ElevatedButton(
//                     onPressed: () {
//                       Get.to(() => AddAddressPage());
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text('Thêm địa chỉ'),
//                   ),
//                 ],
//               ),
//             )
//           else
//             Column(
//               children: [
//                 ...addressController.addresses.map((address) {
//                   final isSelected = selectedAddress?.id == address.id;
//                   return RadioListTile<AddressModel>(
//                     title: Text(address.fullAddress),
//                     subtitle: address.isDefault
//                         ? const Text('Mặc định', style: TextStyle(color: Colors.green))
//                         : null,
//                     value: address,
//                     groupValue: selectedAddress,
//                     onChanged: (value) {
//                       setState(() {
//                         selectedAddress = value;
//                       });
//                     },
//                     activeColor: Colors.green,
//                   );
//                 }),
//                 Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: TextButton.icon(
//                     onPressed: () {
//                       Get.to(() => AddAddressPage());
//                     },
//                     icon: const Icon(Icons.add),
//                     label: const Text('Thêm địa chỉ mới'),
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrderItems() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.all(16),
//             child: Text(
//               'Sản phẩm',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           const Divider(height: 1),
//
//           ListView.separated(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: cartController.cartItems.length,
//             separatorBuilder: (context, index) => const Divider(height: 1),
//             itemBuilder: (context, index) {
//               final item = cartController.cartItems[index];
//               return ListTile(
//                 leading: Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: item.product?.imageUrl != null
//                         ? Image.network(
//                       item.product!.imageUrl!,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) {
//                         return const Icon(Icons.fastfood);
//                       },
//                     )
//                         : const Icon(Icons.fastfood),
//                   ),
//                 ),
//                 title: Text(
//                   item.product?.name ?? 'Sản phẩm',
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 subtitle: Text('x${item.quantity}'),
//                 trailing: Text(
//                   item.formattedSubtotal,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPaymentSection() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.all(16),
//             child: Text(
//               'Phương thức thanh toán',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           const Divider(height: 1),
//
//           RadioListTile<PaymentMethod>(
//             title: const Text('Thanh toán khi nhận hàng (COD)'),
//             value: PaymentMethod.cod,
//             groupValue: selectedPaymentMethod,
//             onChanged: (value) {
//               setState(() {
//                 selectedPaymentMethod = value!;
//               });
//             },
//             activeColor: Colors.green,
//           ),
//           RadioListTile<PaymentMethod>(
//             title: const Text('Ví MoMo'),
//             value: PaymentMethod.momo,
//             groupValue: selectedPaymentMethod,
//             onChanged: (value) {
//               setState(() {
//                 selectedPaymentMethod = value!;
//               });
//             },
//             activeColor: Colors.green,
//           ),
//           RadioListTile<PaymentMethod>(
//             title: const Text('Chuyển khoản ngân hàng'),
//             value: PaymentMethod.banking,
//             groupValue: selectedPaymentMethod,
//             onChanged: (value) {
//               setState(() {
//                 selectedPaymentMethod = value!;
//               });
//             },
//             activeColor: Colors.green,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOrderSummary() {
//     final shippingFee = 15000.0;
//     final total = cartController.totalAmount + shippingFee;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildSummaryRow('Tạm tính', cartController.formattedTotal),
//             const SizedBox(height: 8),
//             _buildSummaryRow('Phí giao hàng', '${shippingFee.toStringAsFixed(0)}đ'),
//             const Divider(height: 24),
//             _buildSummaryRow(
//               'Tổng cộng',
//               '${total.toStringAsFixed(0)}đ',
//               isTotal: true,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: isTotal ? 16 : 14,
//             fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: isTotal ? 18 : 14,
//             fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
//             color: isTotal ? Colors.green : Colors.black,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPlaceOrderButton() {
//     return Obx(() => SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: orderController.isLoading.value || selectedAddress == null
//             ? null
//             : () async {
//           final success = await orderController.createOrder(
//             addressId: selectedAddress!.id,
//             paymentMethod: selectedPaymentMethod,
//           );
//
//           if (success) {
//             Get.offAll(() => const OrderSuccessPage());
//           }
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.green,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: orderController.isLoading.value
//             ? const SizedBox(
//           height: 20,
//           width: 20,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//           ),
//         )
//             : const Text(
//           'ĐẶT HÀNG',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//       ),
//     ));
//   }
// }