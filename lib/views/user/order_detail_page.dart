// lib/pages/order_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/order_controller.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/order_model.dart';
import 'package:xommoigarden/views/user/loading_widget.dart';


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
    orderController.fetchOrderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (orderController.isLoading.value) {
          return const LoadingWidget();
        }

        final order = orderController.currentOrder.value;
        if (order == null) {
          return const Center(child: Text('Không tìm thấy đơn hàng'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trạng thái đơn hàng
              _buildStatusTimeline(order),
              const SizedBox(height: 24),

              // Thông tin đơn hàng
              _buildOrderInfo(order),
              const SizedBox(height: 16),

              // Thông tin giao hàng
              _buildDeliveryInfo(order),
              const SizedBox(height: 16),

              // Danh sách sản phẩm
              _buildProductList(),
              const SizedBox(height: 16),

              // Tổng kết
              _buildOrderSummary(order),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusTimeline(OrderModel order) {
    final List<OrderStatus> statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.delivering,
      OrderStatus.completed,
    ];

    final currentIndex = statuses.indexOf(order.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(statuses.length, (index) {
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? Colors.green : Colors.grey
                              .shade300,
                          border: isCurrent
                              ? Border.all(color: Colors.green, width: 3)
                              : null,
                        ),
                        child: Icon(
                          _getStatusIcon(statuses[index]),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statuses[index].displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight
                              .normal,
                          color: isCompleted ? Colors.green : Colors.grey,
                        ),
                      ),
                      if (index < statuses.length - 1)
                        Container(
                          height: 2,
                          color: isCompleted ? Colors.green : Colors.grey
                              .shade300,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_outlined;
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

  Widget _buildOrderInfo(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            _buildInfoRow(
              'Mã đơn hàng:',
              '#${order.id.substring(0, 8)}',
            ),
            _buildInfoRow(
              'Ngày đặt:',
              _formatDateTime(order.createdAt),
            ),
            _buildInfoRow(
              'Phương thức thanh toán:',
              order.paymentMethod.displayName,
            ),
            _buildInfoRow(
              'Trạng thái thanh toán:',
              order.paymentStatus.displayName,
              valueColor: order.paymentStatus == PaymentStatus.paid
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(OrderModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin giao hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Địa chỉ:',
              order.address?.fullAddress ?? 'Chưa cập nhật',
            ),
            if (order.shipper != null) ...[
              _buildInfoRow(
                'Shipper:',
                order.shipper!.fullName ?? 'Đang chờ',
              ),
              _buildInfoRow(
                'SĐT Shipper:',
                order.shipper!.phone ?? 'Chưa cập nhật',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...orderController.orderItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.product?.imageUrl != null
                            ? Image.network(
                          item.product!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.fastfood);
                          },
                        )
                            : const Icon(Icons.fastfood),
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
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.formattedSubtotal,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(OrderModel order) {
    final shippingFee = 15000.0;
    final subtotal = order.totalAmount - shippingFee;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('Tạm tính', '${subtotal.toStringAsFixed(0)}đ'),
            const SizedBox(height: 8),
            _buildSummaryRow(
                'Phí giao hàng', '${shippingFee.toStringAsFixed(0)}đ'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Tổng cộng',
              order.formattedTotal,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Thêm vào cuối class _OrderDetailPageState trong OrderDetailPage.dart

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
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
            color: isTotal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

}