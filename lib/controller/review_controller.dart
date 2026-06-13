// lib/controller/review_controller.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/order_item_model.dart';
import 'package:xommoigarden/model/review_model.dart';

class ControllerReview extends GetxController {
  final supabase = Supabase.instance.client;

  var reviews = <ReviewModel>[].obs;
  var orderReviewItems = <OrderItemModel>[].obs;
  var orderReviews = <String, ReviewModel>{}.obs;
  var isLoading = false.obs;

  Future<void> fetchAllReviews() async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('reviews')
          .select('*, users(*), products(*)')
          .order('created_at', ascending: false);

      reviews.value = (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all reviews: $e');
      Get.snackbar('Lỗi', 'Không thể tải danh sách đánh giá');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchReviewsByProduct(String productId) async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('reviews')
          .select('*, users(*)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      reviews.value = (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchOrderReviewData(String orderId) async {
    try {
      isLoading.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final itemsResponse = await supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId);

      orderReviewItems.value = (itemsResponse as List)
          .map((json) => OrderItemModel.fromJson(json))
          .toList();

      final reviewsResponse = await supabase
          .from('reviews')
          .select()
          .eq('order_id', orderId)
          .eq('user_id', userId);

      final reviewList = (reviewsResponse as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();

      orderReviews.value = {
        for (final review in reviewList) review.productId: review,
      };
    } catch (e) {
      print('Error fetching order review data: $e');
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu đánh giá');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveOrderReview({
    required String orderId,
    required String productId,
    required int rating,
    required String comment,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final reviewData = {
        'rating': rating,
        'comment': comment.trim().isEmpty ? null : comment.trim(),
      };
      final existingReview = orderReviews[productId];

      if (existingReview != null) {
        await supabase
            .from('reviews')
            .update(reviewData)
            .eq('id', existingReview.id)
            .eq('user_id', userId);
      } else {
        await supabase.from('reviews').insert({
          'user_id': userId,
          'product_id': productId,
          'order_id': orderId,
          ...reviewData,
        });
      }

      await fetchReviewsByProduct(productId);
      await fetchOrderReviewData(orderId);
      return true;
    } catch (e) {
      print('Error saving order review: $e');
      Get.snackbar('Lỗi', 'Không thể gửi đánh giá');
      return false;
    }
  }

  Future<void> addReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('reviews').insert({
        'user_id': userId,
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      });

      await fetchReviewsByProduct(productId);
      Get.snackbar('Thành công', 'Cảm ơn bạn đã đánh giá');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể gửi đánh giá');
    }
  }
}
