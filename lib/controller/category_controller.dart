// lib/controller/category_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/category_model.dart';

class CategoryController extends GetxController {
  final supabase = Supabase.instance.client;

  var categories = <CategoryModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  // Lấy danh sách danh mục
  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('categories')
          .select('*, products(count)')
          .order('name');

      categories.value = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Thêm danh mục mới (cho admin)
  Future<void> addCategory(String name) async {
    try {
      await supabase.from('categories').insert({
        'name': name,
      });

      await fetchCategories();

      Get.snackbar(
        'Thành công',
        'Đã thêm danh mục',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error adding category: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể thêm danh mục',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Cập nhật danh mục
  Future<void> updateCategory(String categoryId, String name) async {
    try {
      await supabase
          .from('categories')
          .update({'name': name})
          .eq('id', categoryId);

      await fetchCategories();

      Get.snackbar(
        'Thành công',
        'Đã cập nhật danh mục',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating category: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật danh mục',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Xóa danh mục
  Future<void> deleteCategory(String categoryId) async {
    try {
      await supabase
          .from('categories')
          .delete()
          .eq('id', categoryId);

      await fetchCategories();

      Get.snackbar(
        'Thành công',
        'Đã xóa danh mục',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting category: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xóa danh mục (có thể đang có sản phẩm)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Lấy tên danh mục theo ID
  String getCategoryName(String? categoryId) {
    if (categoryId == null) return 'Không có';
    final category = categories.firstWhereOrNull((c) => c.id == categoryId);
    return category?.name ?? 'Không xác định';
  }
}