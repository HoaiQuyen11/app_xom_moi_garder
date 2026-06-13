// lib/controller/controller_product.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/category_model.dart';
import 'package:xommoigarden/model/product_model.dart';

class ControllerProduct extends GetxController {
  final supabase = Supabase.instance.client;

  // Observable variables
  var products = <ProductModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var filteredProducts = <ProductModel>[].obs;
  var isLoading = false.obs;
  var selectedCategoryId = Rx<String?>(null);
  var searchQuery = ''.obs;
  Function(ProductModel, GlobalKey)? animateAddToCart;
  RealtimeChannel? _productsChannel;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchProducts();
    _listenToProductChanges();
  }

  @override
  void onClose() {
    final channel = _productsChannel;
    if (channel != null) {
      supabase.removeChannel(channel);
    }
    super.onClose();
  }

  void _listenToProductChanges() {
    _productsChannel = supabase
        .channel('public:products:user-list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (_) => fetchProducts(showLoading: false),
        )
        .subscribe();
  }

  // Lấy danh sách sản phẩm
  Future<void> fetchProducts({bool showLoading = true}) async {
    try {
      if (showLoading) isLoading.value = true;

      final response = await supabase
          .from('products')
          .select('*, categories(*)')
          .eq('is_available', true)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      products.value = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      applyFilters();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách sản phẩm',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  // Lấy danh sách danh mục
  Future<void> fetchCategories() async {
    try {
      final response = await supabase.from('categories').select().order('name');

      categories.value = (response as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  // Lọc sản phẩm theo category và search
  void applyFilters() {
    var result = products.toList();

    // Lọc theo category
    if (selectedCategoryId.value != null &&
        selectedCategoryId.value!.isNotEmpty) {
      result = result
          .where((p) => p.categoryId == selectedCategoryId.value)
          .toList();
    }

    // Lọc theo search
    if (searchQuery.value.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                (p.description?.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    filteredProducts.value = result;
  }

  // Chọn category
  void selectCategory(String? categoryId) {
    selectedCategoryId.value = categoryId;
    applyFilters();
  }

  // Tìm kiếm
  void searchProducts(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  // Lấy sản phẩm theo ID
  ProductModel? getProductById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh dữ liệu
  Future<void> refreshProducts() async {
    await fetchProducts();
  }

  // Thêm method để kích hoạt animation từ bên ngoài
  void triggerAddToCartAnimation(ProductModel product, GlobalKey key) {
    if (animateAddToCart != null) {
      animateAddToCart!(product, key);
    }
  }
}
