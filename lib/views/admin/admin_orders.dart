// lib/views/admin/admin_orders.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/admin_controller.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/order_model.dart';

class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders> {
  final AdminController adminController = Get.find();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    adminController.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm đơn hàng...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text('Tất cả trạng thái'),
                    value: selectedStatus,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tất cả')),
                      ...OrderStatus.values.map((status) => DropdownMenuItem(
                        value: status.value,
                        child: Text(status.displayName),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Orders table
        Expanded(
          child: Obx(() {
            if (adminController.isLoadingOrders.value) {
              return const Center(child: CircularProgressIndicator());
            }

            var filteredOrders = adminController.orders.toList();
            if (searchQuery.isNotEmpty) {
              final query = searchQuery.toLowerCase();
              filteredOrders = filteredOrders.where((o) =>
              o.id.contains(searchQuery) ||
                  (o.customer?.fullName?.toLowerCase().contains(query) ?? false) ||
                  (o.customer?.phone?.contains(searchQuery) ?? false)
              ).toList();
            }
            if (selectedStatus != null) {
              filteredOrders = filteredOrders.where((o) =>
              o.status.value == selectedStatus
              ).toList();
            }

            if (filteredOrders.isEmpty) {
              return const Center(child: Text('Chưa có đơn hàng nào'));
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Mã đơn')),
                  DataColumn(label: Text('Khách hàng')),
                  DataColumn(label: Text('Tổng tiền')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Thanh toán')),
                  DataColumn(label: Text('Ngày tạo')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: filteredOrders.map((order) {
                  return DataRow(cells: [
                    DataCell(Text(order.id.substring(0, 8))),
                    DataCell(Text(order.customer?.fullName ?? 'Khách hàng')),
                    DataCell(Text('${order.totalAmount.toStringAsFixed(0)}đ')),
                    DataCell(_buildStatusChip(order.status)),
                    DataCell(_buildPaymentChip(order.paymentStatus)),
                    DataCell(Text(_formatDate(order.createdAt))),
                    DataCell(Row(
                      children: [
                        if (order.status == OrderStatus.pending)
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _updateStatus(order, 'confirmed'),
                            tooltip: 'Xác nhận',
                          ),
                        if (order.status == OrderStatus.confirmed)
                          IconButton(
                            icon: const Icon(Icons.kitchen, color: Colors.orange),
                            onPressed: () => _updateStatus(order, 'preparing'),
                            tooltip: 'Đang chuẩn bị',
                          ),
                        if (order.status == OrderStatus.preparing)
                          IconButton(
                            icon: const Icon(Icons.delivery_dining, color: Colors.blue),
                            onPressed: () => _assignShipper(order),
                            tooltip: 'Giao cho shipper',
                          ),
                        if (order.status != OrderStatus.completed &&
                            order.status != OrderStatus.cancelled)
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _updateStatus(order, 'cancelled'),
                            tooltip: 'Hủy đơn',
                          ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.preparing:
        color = Colors.purple;
        break;
      case OrderStatus.delivering:
        color = Colors.cyan;
        break;
      case OrderStatus.completed:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color),
      ),
    );
  }

  Widget _buildPaymentChip(PaymentStatus status) {
    Color color = status == PaymentStatus.paid ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color),
      ),
    );
  }

  void _updateStatus(OrderModel order, String status) async {
    await adminController.updateOrderStatus(order.id, status);
  }

  void _assignShipper(OrderModel order) async {
    final shippers = await adminController.getShippers();
    if (shippers.isEmpty) {
      Get.snackbar('Lỗi', 'Không có shipper nào đang hoạt động');
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Chọn shipper'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shippers.length,
            itemBuilder: (context, index) {
              final shipper = shippers[index];
              return ListTile(
                leading: const Icon(Icons.delivery_dining),
                title: Text(shipper.fullName ?? 'Shipper'),
                subtitle: Text(shipper.phone ?? ''),
                onTap: () {
                  Get.back();
                  adminController.assignShipper(order.id, shipper.id);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}