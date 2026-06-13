// lib/views/user/order_success_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/order_controller.dart';
import 'package:xommoigarden/model/order_model.dart';

import 'my_home_page.dart';

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  final ControllerOrder orderController = Get.find();
  Timer? _cancelTimer;

  @override
  void initState() {
    super.initState();
    _cancelTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final order = orderController.lastCreatedOrder.value;
      if (order != null && order.isPending && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _cancelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            final order = orderController.lastCreatedOrder.value;
            final canCancel = order?.canCancel ?? false;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Đặt hàng thành công!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cảm ơn bạn đã đặt hàng.\nĐơn hàng của bạn đang được xử lý.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                if (order != null && canCancel) ...[
                  _buildCancelBox(order),
                  const SizedBox(height: 16),
                ],
                if (order != null && !canCancel && order.isPending) ...[
                  Text(
                    'Đã hết thời gian hủy nhanh.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.offAll(() => MyHomePage());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tiếp tục mua sắm'),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCancelBox(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Text(
            'Đặt nhầm? Bạn có thể hủy trong ${order.cancelSecondsRemaining}s',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: orderController.isLoading.value
                  ? null
                  : () => _confirmCancelOrder(order),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Hủy đơn hàng'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelOrder(OrderModel order) async {
    if (!order.canCancel) {
      setState(() {});
      return;
    }

    final shouldCancel = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn muốn hủy đơn vừa đặt?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Hủy đơn',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    final cancelled = await orderController.cancelOrder(
      order.id,
      reason: 'Khách hàng hủy nhanh sau khi đặt',
    );
    if (cancelled) {
      Get.offAll(() => MyHomePage());
    } else if (mounted) {
      setState(() {});
    }
  }
}
