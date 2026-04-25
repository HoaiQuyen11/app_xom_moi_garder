// lib/views/user/order_history_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/order_controller.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/order_model.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final ControllerOrder orderController = Get.find();

  final List<_StatusFilter> filters = const [
    _StatusFilter('Tất cả', null),
    _StatusFilter('Chờ xác nhận', OrderStatus.pending),
    _StatusFilter('Đang xử lý', OrderStatus.preparing),
    _StatusFilter('Đang giao', OrderStatus.delivering),
    _StatusFilter('Hoàn thành', OrderStatus.completed),
    _StatusFilter('Đã hủy', OrderStatus.cancelled),
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    orderController.fetchOrders();
  }

  List<OrderModel> _filterOrders(OrderStatus? status) {
    if (status == null) return orderController.orders.toList();
    if (status == OrderStatus.preparing) {
      return orderController.orders
          .where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.preparing)
          .toList();
    }
    return orderController.orders.where((o) => o.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 52,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = filters[index];
                final isActive = index == selectedIndex;
                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade700 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f.label,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // Orders list
          Expanded(
            child: Obx(() {
              if (orderController.isLoading.value && orderController.orders.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                );
              }

              final orders = _filterOrders(filters[selectedIndex].status);

              if (orders.isEmpty) {
                return _buildEmpty();
              }

              return RefreshIndicator(
                onRefresh: () => orderController.fetchOrders(),
                color: Colors.green.shade700,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _buildOrderCard(orders[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => OrderDetailPage(orderId: order.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 10),

              if (order.address?.fullAddress != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.address!.fullAddress,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.payment, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.paymentMethod.displayName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    'Tổng tiền:',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.formattedTotal,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Xem chi tiết',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Colors.green.shade700),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    final (color, icon) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _statusStyle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (Colors.orange.shade700, Icons.hourglass_empty);
      case OrderStatus.confirmed:
        return (Colors.blue.shade700, Icons.check_circle_outline);
      case OrderStatus.preparing:
        return (Colors.purple.shade700, Icons.kitchen_outlined);
      case OrderStatus.delivering:
        return (Colors.cyan.shade700, Icons.delivery_dining);
      case OrderStatus.completed:
        return (Colors.green.shade700, Icons.verified);
      case OrderStatus.cancelled:
        return (Colors.red.shade700, Icons.cancel_outlined);
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Chưa có đơn hàng nào',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Đơn hàng của bạn sẽ hiển thị tại đây',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Đi mua sắm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusFilter {
  final String label;
  final OrderStatus? status;
  const _StatusFilter(this.label, this.status);
}
