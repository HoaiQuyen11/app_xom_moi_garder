// lib/views/user/order_review_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/review_controller.dart';
import 'package:xommoigarden/model/order_item_model.dart';
import 'package:xommoigarden/model/order_model.dart';

class OrderReviewPage extends StatefulWidget {
  final OrderModel order;

  const OrderReviewPage({super.key, required this.order});

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  final ControllerReview reviewController = Get.find();
  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await reviewController.fetchOrderReviewData(widget.order.id);
      _syncExistingReviews();
    });
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncExistingReviews() {
    for (final item in reviewController.orderReviewItems) {
      final review = reviewController.orderReviews[item.productId];
      _ratings[item.productId] = review?.rating ?? 0;
      _commentControllers[item.productId] = TextEditingController(
        text: review?.comment ?? '',
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Đánh giá đơn hàng',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (reviewController.isLoading.value &&
            reviewController.orderReviewItems.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        }

        final items = reviewController.orderReviewItems;
        if (items.isEmpty) {
          return Center(
            child: Text(
              'Không có sản phẩm để đánh giá',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildReviewCard(items[index]),
              ),
            ),
            _buildSubmitBar(),
          ],
        );
      }),
    );
  }

  Widget _buildReviewCard(OrderItemModel item) {
    final productId = item.productId;
    final rating = _ratings[productId] ?? 0;
    final commentController = _commentControllers[productId] ??=
        TextEditingController();
    final hasReviewed = reviewController.orderReviews.containsKey(productId);

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.product?.imageUrl != null
                    ? Image.network(
                        item.product!.imageUrl!,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'x${item.quantity} · ${item.formattedSubtotal}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (hasReviewed) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Đã đánh giá',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: () {
                  setState(() => _ratings[productId] = star);
                },
                icon: Icon(
                  star <= rating ? Icons.star : Icons.star_border,
                  color: Colors.amber.shade700,
                  size: 28,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm này',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.green.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 58,
      height: 58,
      color: Colors.grey.shade200,
      child: Icon(Icons.fastfood, color: Colors.grey.shade400, size: 28),
    );
  }

  Widget _buildSubmitBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitReviews,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.rate_review_outlined),
            label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi đánh giá'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReviews() async {
    final itemsToReview = reviewController.orderReviewItems
        .where((item) => (_ratings[item.productId] ?? 0) > 0)
        .toList();

    if (itemsToReview.isEmpty) {
      Get.snackbar('Thiếu đánh giá', 'Vui lòng chọn số sao cho sản phẩm');
      return;
    }

    setState(() => _isSubmitting = true);

    var successCount = 0;
    for (final item in itemsToReview) {
      final success = await reviewController.saveOrderReview(
        orderId: widget.order.id,
        productId: item.productId,
        rating: _ratings[item.productId]!,
        comment: _commentControllers[item.productId]?.text ?? '',
      );
      if (success) successCount++;
    }

    if (mounted) setState(() => _isSubmitting = false);

    if (successCount > 0) {
      Get.back(result: true);
      Get.snackbar('Thành công', 'Đã gửi đánh giá cho $successCount sản phẩm');
    }
  }
}
