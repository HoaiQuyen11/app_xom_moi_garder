// lib/views/user/order_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/order_controller.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/order_model.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ControllerOrder orderController = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.fetchOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        }

        final order = orderController.currentOrder.value;
        if (order == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Không tìm thấy đơn hàng', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => orderController.fetchOrderDetail(widget.orderId),
          color: Colors.green.shade700,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildStatusTimeline(order),
              const SizedBox(height: 12),
              _buildOrderInfo(order),
              const SizedBox(height: 12),
              _buildDeliveryInfo(order),
              const SizedBox(height: 12),
              _buildProductList(),
              const SizedBox(height: 12),
              _buildOrderSummary(order),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _buildStatusTimeline(OrderModel order) {
    if (order.status == OrderStatus.cancelled) {
      return _buildCard(
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade600, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng đã bị hủy',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final statuses = const [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.delivering,
      OrderStatus.completed,
    ];
    final currentIndex = statuses.indexOf(order.status);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trạng thái đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(statuses.length, (index) {
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final color = isCompleted ? Colors.green.shade600 : Colors.grey.shade300;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index == 0
                                ? Colors.transparent
                                : (index <= currentIndex ? Colors.green.shade600 : Colors.grey.shade300),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: isCurrent
                                ? Border.all(color: Colors.green.shade800, width: 2)
                                : null,
                          ),
                          child: Icon(
                            _getStatusIcon(statuses[index]),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index == statuses.length - 1
                                ? Colors.transparent
                                : (index < currentIndex ? Colors.green.shade600 : Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statuses[index].displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? Colors.green.shade700 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
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
        return Icons.verified;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildOrderInfo(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildInfoRow('Mã đơn:', '#${order.id.substring(0, 8).toUpperCase()}'),
          _buildInfoRow('Ngày đặt:', _formatDateTime(order.createdAt)),
          _buildInfoRow('Thanh toán:', order.paymentMethod.displayName),
          _buildInfoRow(
            'Trạng thái TT:',
            order.paymentStatus.displayName,
            valueColor: order.paymentStatus == PaymentStatus.paid ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          if (order.note != null && order.note!.trim().isNotEmpty)
            _buildInfoRow('Ghi chú:', order.note!),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin giao hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildInfoRow('Địa chỉ:', order.address?.fullAddress ?? 'Chưa cập nhật'),
          _buildInfoRow('Hình thức:', order.shippingMethod.displayName),
          if (order.shipper != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green.shade50,
                  child: Icon(Icons.delivery_dining, color: Colors.green.shade700),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shipper!.fullName ?? 'Shipper',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        order.shipper!.phone ?? '---',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Obx(() {
      final items = orderController.orderItems;

      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sản phẩm (${items.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Không có sản phẩm',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.product?.imageUrl != null
                              ? Image.network(
                                  item.product!.imageUrl!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => _imagePlaceholder(),
                                )
                              : _imagePlaceholder(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product?.name ?? 'Sản phẩm',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.hasOptions) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.optionsText,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'x${item.quantity}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.formattedSubtotal,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      );
    });
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey.shade200,
      child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 28),
    );
  }

  Widget _buildOrderSummary(OrderModel order) {
    final shippingFee = order.shippingFee;
    final subtotal = order.totalAmount - shippingFee;

    return _buildCard(
      child: Column(
        children: [
          _buildSummaryRow('Tạm tính', '${subtotal.toStringAsFixed(0)}đ'),
          const SizedBox(height: 6),
          _buildSummaryRow('Phí giao hàng', '${shippingFee.toStringAsFixed(0)}đ'),
          const Divider(height: 20),
          _buildSummaryRow('Tổng cộng', order.formattedTotal, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 17 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.red.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
