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
  final TextEditingController cancelReasonController = TextEditingController();

  String searchQuery = '';
  OrderStatus? selectedStatus;
  String? selectedCancelReason;

  static const List<String> cancelReasons = [
    'Không liên lạc được với khách hàng',
    'Làm sai yêu cầu của khách',
    'Đơn hàng bị hư hỏng trong quá trình giao',
    'Khác',
  ];

  final List<_OrderStatusFilter> statusFilters = const [
    _OrderStatusFilter('Tất cả', null),
    _OrderStatusFilter('Mới', OrderStatus.pending),
    _OrderStatusFilter('Đã xác nhận', OrderStatus.confirmed),
    _OrderStatusFilter('Chuẩn bị', OrderStatus.preparing),
    _OrderStatusFilter('Đang giao', OrderStatus.delivering),
    _OrderStatusFilter('Hoàn thành', OrderStatus.completed),
    _OrderStatusFilter('Đã hủy', OrderStatus.cancelled),
  ];

  @override
  void initState() {
    super.initState();
    adminController.fetchOrders();
  }

  @override
  void dispose() {
    searchController.dispose();
    cancelReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBox(),
        _buildStatusTabs(),
        const Divider(height: 1),
        Expanded(
          child: Obx(() {
            if (adminController.isLoadingOrders.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredOrders = _filteredOrders();
            if (filteredOrders.isEmpty) {
              return const Center(child: Text('Chưa có đơn hàng nào'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: SingleChildScrollView(
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
                  rows: filteredOrders
                      .map(
                        (order) => DataRow(
                          cells: [
                            DataCell(Text(order.displayCode)),
                            DataCell(
                              Text(order.customer?.fullName ?? 'Khách hàng'),
                            ),
                            DataCell(
                              Text('${order.totalAmount.toStringAsFixed(0)}đ'),
                            ),
                            DataCell(_buildStatusChip(order.status)),
                            DataCell(_buildPaymentChip(order.paymentStatus)),
                            DataCell(Text(_formatDate(order.createdAt))),
                            DataCell(_buildOrderActions(order)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: statusFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = statusFilters[index];
          final isSelected = selectedStatus == filter.status;

          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) => setState(() => selectedStatus = filter.status),
            selectedColor: Colors.green.shade100,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          );
        },
      ),
    );
  }

  List<OrderModel> _filteredOrders() {
    var filteredOrders = adminController.orders.toList();

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredOrders = filteredOrders
          .where(
            (order) =>
                order.id.toLowerCase().contains(query) ||
                (order.orderCode?.toLowerCase().contains(query) ?? false) ||
                (order.customer?.fullName?.toLowerCase().contains(query) ??
                    false) ||
                (order.customer?.phone?.contains(searchQuery) ?? false),
          )
          .toList();
    }

    if (selectedStatus != null) {
      filteredOrders = filteredOrders
          .where((order) => order.status == selectedStatus)
          .toList();
    }

    return filteredOrders;
  }

  Widget _buildOrderActions(OrderModel order) {
    final next = _nextStatusAction(order.status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (next != null)
          ElevatedButton.icon(
            onPressed: () => _updateStatus(order, next.status),
            icon: Icon(next.icon, size: 16),
            label: Text(next.label),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          Text(
            order.status == OrderStatus.completed ? 'Đã hoàn tất' : 'Đã hủy',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        if (order.status != OrderStatus.completed &&
            order.status != OrderStatus.cancelled) ...[
          const SizedBox(width: 4),
          PopupMenuButton<OrderStatus>(
            tooltip: 'Tùy chọn trạng thái',
            icon: const Icon(Icons.more_horiz),
            onSelected: (status) => _confirmManualStatus(order, status),
            itemBuilder: (context) => _statusMenuItems(order),
            /* old menu removed
          [
            ...OrderStatus.values
                .where((status) => status != order.status)
                .map(
                  (status) => PopupMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(status),
                          size: 18,
                          color: _statusColor(status),
                        ),
                        const SizedBox(width: 8),
                        Text(status.displayName),
                      ],
                    ),
                  ),
                ),
            if (canCancel) const PopupMenuDivider(),
            if (canCancel)
              const PopupMenuItem(
                value: OrderStatus.cancelled,
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hủy đơn'),
                  ],
                ),
              ),
          ],*/
          ),
        ],
      ],
    );
  }

  List<PopupMenuEntry<OrderStatus>> _statusMenuItems(OrderModel order) {
    final entries = <PopupMenuEntry<OrderStatus>>[];

    for (final status in OrderStatus.values) {
      if (status == order.status) continue;
      if (status == OrderStatus.cancelled &&
          (order.status == OrderStatus.completed ||
              order.status == OrderStatus.cancelled)) {
        continue;
      }

      entries.add(
        PopupMenuItem<OrderStatus>(
          value: status,
          child: Row(
            children: [
              Icon(_statusIcon(status), size: 18, color: _statusColor(status)),
              const SizedBox(width: 8),
              Text(
                status == OrderStatus.cancelled
                    ? 'Hủy đơn'
                    : status.displayName,
              ),
            ],
          ),
        ),
      );
    }

    return entries;
  }

  _NextStatusAction? _nextStatusAction(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const _NextStatusAction(
          status: OrderStatus.confirmed,
          label: 'Xác nhận',
          icon: Icons.check_circle_outline,
        );
      case OrderStatus.confirmed:
        return const _NextStatusAction(
          status: OrderStatus.preparing,
          label: 'Chuẩn bị',
          icon: Icons.kitchen_outlined,
        );
      case OrderStatus.preparing:
        return const _NextStatusAction(
          status: OrderStatus.delivering,
          label: 'Giao hàng',
          icon: Icons.delivery_dining,
        );
      case OrderStatus.delivering:
        return const _NextStatusAction(
          status: OrderStatus.completed,
          label: 'Hoàn thành',
          icon: Icons.verified_outlined,
        );
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return null;
    }
  }

  Widget _buildStatusChip(OrderStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.displayName, style: TextStyle(color: color)),
    );
  }

  Widget _buildPaymentChip(PaymentStatus status) {
    final color = status == PaymentStatus.paid ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.displayName, style: TextStyle(color: color)),
    );
  }

  Future<void> _confirmManualStatus(
    OrderModel order,
    OrderStatus status,
  ) async {
    if (status == order.status) return;

    if (status == OrderStatus.cancelled) {
      await _showCancelReasonDialog(order);
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cập nhật trạng thái?'),
        content: Text(
          'Chuyển đơn #${order.displayCode} sang "${status.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(order, status);
    }
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus status) async {
    await adminController.updateOrderStatus(order.id, status.value);
  }

  Future<void> _showCancelReasonDialog(OrderModel order) async {
    selectedCancelReason = cancelReasons.first;
    cancelReasonController.clear();

    final reason = await Get.dialog<String>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final isOther = selectedCancelReason == 'Khác';

          return AlertDialog(
            title: const Text('Lý do hủy đơn'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...cancelReasons.map(
                    (reason) => RadioListTile<String>(
                      value: reason,
                      groupValue: selectedCancelReason,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(reason),
                      onChanged: (value) {
                        setDialogState(() => selectedCancelReason = value);
                      },
                    ),
                  ),
                  if (isOther) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: cancelReasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập lý do hủy đơn',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Không'),
              ),
              ElevatedButton(
                onPressed: () {
                  final selected = selectedCancelReason;
                  if (selected == null) return;

                  final resolvedReason = selected == 'Khác'
                      ? cancelReasonController.text.trim()
                      : selected;

                  if (resolvedReason.isEmpty) {
                    Get.snackbar(
                      'Thiếu lý do',
                      'Vui lòng nhập lý do hủy đơn',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  Get.back(result: resolvedReason);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hủy đơn'),
              ),
            ],
          );
        },
      ),
    );

    if (reason == null || reason.trim().isEmpty) return;

    await adminController.updateOrderStatus(
      order.id,
      OrderStatus.cancelled.value,
      cancelReason: reason,
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade700;
      case OrderStatus.confirmed:
        return Colors.blue.shade700;
      case OrderStatus.preparing:
        return Colors.purple.shade700;
      case OrderStatus.delivering:
        return Colors.cyan.shade700;
      case OrderStatus.completed:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red.shade700;
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.kitchen_outlined;
      case OrderStatus.delivering:
        return Icons.delivery_dining;
      case OrderStatus.completed:
        return Icons.verified_outlined;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _OrderStatusFilter {
  final String label;
  final OrderStatus? status;

  const _OrderStatusFilter(this.label, this.status);
}

class _NextStatusAction {
  final OrderStatus status;
  final String label;
  final IconData icon;

  const _NextStatusAction({
    required this.status,
    required this.label,
    required this.icon,
  });
}
