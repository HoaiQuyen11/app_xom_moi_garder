// lib/controller/controller_review.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/review_model.dart';

class ControllerReview extends GetxController {
  final supabase = Supabase.instance.client;

  var reviews = <ReviewModel>[].obs;
  var isLoading = false.obs;

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

  Future<void> addReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
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