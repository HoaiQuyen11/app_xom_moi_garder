import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/review_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/model/review_model.dart';

class ProductReviewsPage extends StatefulWidget {
  final ProductModel? product;

  const ProductReviewsPage({super.key, this.product});

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  final ControllerReview reviewController = Get.find<ControllerReview>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.product == null) {
        reviewController.fetchAllReviews();
      } else {
        reviewController.fetchReviewsByProduct(widget.product!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(product == null ? 'Tất cả đánh giá' : 'Đánh giá sản phẩm'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Obx(() {
        if (reviewController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = reviewController.reviews;
        if (reviews.isEmpty) {
          return Center(
            child: Text(
              'Chưa có đánh giá nào',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildSummary(reviews),
            const SizedBox(height: 12),
            ...reviews.map(_buildReviewCard),
          ],
        );
      }),
    );
  }

  Widget _buildSummary(List<ReviewModel> reviews) {
    final avg =
        reviews.fold<double>(0, (sum, review) => sum + review.rating) /
        reviews.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            avg.toStringAsFixed(1),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < avg.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${reviews.length} đánh giá của khách hàng',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final userName = review.user?.fullName?.trim().isNotEmpty == true
        ? review.user!.fullName!.trim()
        : review.user?.email?.split('@').first ?? 'Khách hàng';
    final comment = review.comment?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green.shade50,
                child: Text(
                  userName.isEmpty ? '?' : userName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber.shade700,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review.formattedDate,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.product == null && review.product != null) ...[
            const SizedBox(height: 10),
            Text(
              review.product!.name,
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: const TextStyle(fontSize: 14, height: 1.35)),
          ],
        ],
      ),
    );
  }
}
