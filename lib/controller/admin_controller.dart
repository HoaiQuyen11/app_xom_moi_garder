// lib/controller/admin_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/order_model.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/model/user_model.dart';


class AdminController extends GetxController {
  final supabase = Supabase.instance.client;

  // Dashboard stats
  var totalUsers = 0.obs;
  var totalProducts = 0.obs;
  var totalOrders = 0.obs;
  var totalRevenue = 0.obs;
  var recentOrders = <OrderModel>[].obs;
  var monthlyRevenue = <Map<String, dynamic>>[].obs;

  // Product management
  var products = <ProductModel>[].obs;
  var isLoadingProducts = false.obs;

  // Order management
  var orders = <OrderModel>[].obs;
  var isLoadingOrders = false.obs;

  // User management
  var users = <UserModel>[].obs;
  var isLoadingUsers = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStats();
    fetchProducts();
    fetchOrders();
    fetchUsers();
  }

  // ==================== DASHBOARD ====================
  Future<void> fetchDashboardStats() async {
    try {
      // Tổng số users
      final usersRes = await supabase.from('users').select('id').count(CountOption.exact);
      totalUsers.value = usersRes.count;

      // Tổng số products
      final productsRes = await supabase.from('products').select('id').count(CountOption.exact);
      totalProducts.value = productsRes.count;

      // Tổng số orders
      final ordersRes = await supabase.from('orders').select('id').count(CountOption.exact);
      totalOrders.value = ordersRes.count;

      // Tổng doanh thu
      final revenueRes = await supabase
          .from('orders')
          .select('total_amount')
          .eq('status', 'completed');

      totalRevenue.value = (revenueRes as List)
          .fold<double>(0, (sum, item) => sum + (item['total_amount'] as num).toDouble())
          .toInt();

      // Đơn hàng gần đây
      final recentRes = await supabase
          .from('orders')
          .select('*, users!user_id(*)')
          .order('created_at', ascending: false)
          .limit(5);

      recentOrders.value = (recentRes as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();

      // Doanh thu theo tháng
      final monthlyRes = await supabase.rpc('get_monthly_revenue');
      monthlyRevenue.value = List<Map<String, dynamic>>.from(monthlyRes);

    } catch (e) {
      print('Error fetching dashboard stats: $e');
    }
  }

  // ==================== PRODUCT MANAGEMENT ====================
  Future<void> fetchProducts() async {
    try {
      isLoadingProducts.value = true;

      final response = await supabase
          .from('products')
          .select('*, categories(*)')
          .order('created_at', ascending: false);

      products.value = (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

    } catch (e) {
      print('Error fetching products: $e');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await supabase.from('products').insert(productData);
      await fetchProducts();
      Get.snackbar('Thành công', 'Đã thêm sản phẩm', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('Error adding product: $e');
      Get.snackbar('Lỗi', 'Không thể thêm sản phẩm', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      await supabase.from('products').update(productData).eq('id', productId);
      await fetchProducts();
      Get.snackbar('Thành công', 'Đã cập nhật sản phẩm', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('Error updating product: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật sản phẩm', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await supabase.from('products').delete().eq('id', productId);
      await fetchProducts();
      Get.snackbar('Thành công', 'Đã xóa sản phẩm', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('Error deleting product: $e');
      Get.snackbar('Lỗi', 'Không thể xóa sản phẩm', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ==================== ORDER MANAGEMENT ====================
  Future<void> fetchOrders() async {
    try {
      isLoadingOrders.value = true;

      final response = await supabase
          .from('orders')
          .select('*, users!user_id(*), addresses(*)')
          .order('created_at', ascending: false);

      orders.value = (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();

    } catch (e) {
      print('Error fetching orders: $e');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await supabase
          .from('orders')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      await fetchOrders();
      await fetchDashboardStats();

      Get.snackbar('Thành công', 'Đã cập nhật trạng thái đơn hàng', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('Error updating order status: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> assignShipper(String orderId, String shipperId) async {
    try {
      await supabase
          .from('orders')
          .update({'shipper_id': shipperId, 'status': 'delivering'})
          .eq('id', orderId);

      await fetchOrders();

      Get.snackbar('Thành công', 'Đã giao đơn cho shipper', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('Error assigning shipper: $e');
      Get.snackbar('Lỗi', 'Không thể giao đơn', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ==================== USER MANAGEMENT ====================
  Future<void> fetchUsers() async {
    try {
      isLoadingUsers.value = true;

      final response = await supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      users.value = (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();

    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<void> updateUserStatus(String userId, UserStatus status) async {
    try {
      await supabase
          .from('users')
          .update({'status': status.value})
          .eq('id', userId);

      await fetchUsers();

      Get.snackbar('Thành công', 'Đã cập nhật trạng thái người dùng', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      print('Error updating user status: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<List<UserModel>> getShippers() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('role', 'shipper')
          .eq('status', 'active');

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching shippers: $e');
      return [];
    }
  }
}