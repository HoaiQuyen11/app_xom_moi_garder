// lib/controller/admin_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/notification_model.dart';
import 'package:xommoigarden/model/order_model.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/model/user_model.dart';

class AdminController extends GetxController {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _ordersChannel;
  Timer? _notificationPollTimer;
  final Map<String, Timer> _pendingNotificationTimers = {};

  // Dashboard stats
  var totalUsers = 0.obs;
  var totalProducts = 0.obs;
  var totalOrders = 0.obs;
  var totalRevenue = 0.obs;
  var recentOrders = <OrderModel>[].obs;
  var monthlyRevenue = <Map<String, dynamic>>[].obs;

  // Statistics
  var isLoadingStatistics = false.obs;
  var statisticsDays = DateUtils.getDaysInMonth(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;
  var statisticsLabel = 'Tháng này'.obs;
  var statisticsStartDate = Rx<DateTime?>(null);
  var statisticsEndDate = Rx<DateTime?>(null);
  var revenueToday = 0.0.obs;
  var revenueThisMonth = 0.0.obs;
  var revenueTotalAllTime = 0.0.obs;
  var statisticTotalOrders = 0.obs;
  var statisticCompletedOrders = 0.obs;
  var statisticCancelledOrders = 0.obs;
  var statisticAverageOrderValue = 0.0.obs;
  var statisticNewCustomers = 0.obs;
  var revenueByDay = <Map<String, dynamic>>[].obs;
  var topSellingProducts = <Map<String, dynamic>>[].obs;
  var productSalesStats = <Map<String, dynamic>>[].obs;
  var topSpendingCustomers = <Map<String, dynamic>>[].obs;
  var topUsedVouchers = <Map<String, dynamic>>[].obs;

  // Product management
  var products = <ProductModel>[].obs;
  var isLoadingProducts = false.obs;

  // Order management
  var orders = <OrderModel>[].obs;
  var isLoadingOrders = false.obs;

  // User management
  var users = <UserModel>[].obs;
  var isLoadingUsers = false.obs;

  // Notifications
  var notifications = <NotificationModel>[].obs;
  var unreadNotifications = 0.obs;
  var isLoadingNotifications = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStats();
    fetchStatistics();
    fetchProducts();
    fetchOrders();
    fetchUsers();
    syncReadyOrderNotifications();
    fetchNotifications();
    _listenToAdminNotifications();
    _listenToNewOrders();
    _startNotificationPolling();
  }

  @override
  void onClose() {
    final channel = _notificationsChannel;
    if (channel != null) {
      supabase.removeChannel(channel);
    }
    final ordersChannel = _ordersChannel;
    if (ordersChannel != null) {
      supabase.removeChannel(ordersChannel);
    }
    for (final timer in _pendingNotificationTimers.values) {
      timer.cancel();
    }
    _notificationPollTimer?.cancel();
    _pendingNotificationTimers.clear();
    super.onClose();
  }

  void _listenToAdminNotifications() {
    _notificationsChannel = supabase
        .channel('public:notifications:admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) async {
            final currentUserId = supabase.auth.currentUser?.id;
            if (payload.newRecord['user_id'] == currentUserId) {
              await fetchNotifications(showLoading: false);
              await fetchOrders();
              await fetchDashboardStats();
              await fetchStatistics(showLoading: false);
              Get.snackbar(
                payload.newRecord['title']?.toString() ?? 'Thông báo mới',
                payload.newRecord['message']?.toString() ??
                    'Bạn có thông báo mới',
                backgroundColor: Colors.orange.shade700,
                colorText: Colors.white,
              );
            }
          },
        )
        .subscribe();
  }

  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 5), (
      _,
    ) async {
      await syncReadyOrderNotifications();
      await fetchNotifications(showLoading: false);
    });
  }

  void _listenToNewOrders() {
    _ordersChannel = supabase
        .channel('public:orders:admin-new-orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            _scheduleOrderNotification(payload.newRecord);
            fetchOrders();
            fetchDashboardStats();
            fetchStatistics(showLoading: false);
          },
        )
        .subscribe();
  }

  void _scheduleOrderNotification(Map<String, dynamic> orderRecord) {
    final orderId = orderRecord['id']?.toString();
    final createdAtRaw = orderRecord['created_at']?.toString();
    if (orderId == null || createdAtRaw == null) return;

    _pendingNotificationTimers[orderId]?.cancel();

    final createdAt = DateTime.parse(createdAtRaw);
    final readyAt = createdAt.add(OrderModel.cancelWindow);
    final delay = readyAt.difference(DateTime.now());

    _pendingNotificationTimers[orderId] = Timer(
      delay.isNegative ? Duration.zero : delay,
      () async {
        _pendingNotificationTimers.remove(orderId);
        await syncReadyOrderNotifications();
        await fetchNotifications(showLoading: false);
      },
    );
  }

  // ==================== DASHBOARD ====================
  Future<void> fetchDashboardStats() async {
    try {
      final usersRes = await supabase
          .from('users')
          .select('id')
          .count(CountOption.exact);
      totalUsers.value = usersRes.count;

      final productsRes = await supabase
          .from('products')
          .select('id')
          .count(CountOption.exact);
      totalProducts.value = productsRes.count;

      final ordersRes = await supabase
          .from('orders')
          .select('id')
          .count(CountOption.exact);
      totalOrders.value = ordersRes.count;

      final revenueRes = await supabase
          .from('orders')
          .select('total_amount')
          .eq('status', 'completed');

      totalRevenue.value = (revenueRes as List)
          .fold<double>(
            0,
            (sum, item) => sum + (item['total_amount'] as num).toDouble(),
          )
          .toInt();

      final recentRes = await supabase
          .from('orders')
          .select('*, customer:users!user_id(*)')
          .order('created_at', ascending: false)
          .limit(5);

      recentOrders.value = (recentRes as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();

      try {
        final monthlyRes = await supabase.rpc('get_monthly_revenue');
        monthlyRevenue.value = List<Map<String, dynamic>>.from(monthlyRes);
      } catch (_) {}
    } catch (e) {
      print('Error fetching dashboard stats: $e');
    }
  }

  Future<void> fetchStatistics({
    int? days,
    DateTime? startDate,
    DateTime? endDate,
    String? label,
    bool showLoading = true,
  }) async {
    try {
      if (label != null) statisticsLabel.value = label;
      if (showLoading) isLoadingStatistics.value = true;

      final now = DateTime.now();
      final resolvedRange = _resolveStatisticsRange(
        now: now,
        days: days,
        startDate: startDate,
        endDate: endDate,
      );
      final periodStart = resolvedRange.$1;
      final periodEndExclusive = resolvedRange.$2;
      statisticsStartDate.value = periodStart;
      statisticsEndDate.value = periodEndExclusive.subtract(
        const Duration(days: 1),
      );
      statisticsDays.value = periodEndExclusive.difference(periodStart).inDays;

      final todayStart = DateTime(now.year, now.month, now.day);
      final tomorrowStart = todayStart.add(const Duration(days: 1));
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonthStart = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);

      final ordersResponse = await supabase
          .from('orders')
          .select('*, customer:users!user_id(*)')
          .order('created_at', ascending: false);
      final allOrders = (ordersResponse as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();

      final completedOrders = allOrders
          .where((order) => order.status == OrderStatus.completed)
          .toList();
      revenueToday.value = completedOrders
          .where(
            (order) =>
                !order.createdAt.isBefore(todayStart) &&
                order.createdAt.isBefore(tomorrowStart),
          )
          .fold<double>(0, (sum, order) => sum + order.totalAmount);
      revenueThisMonth.value = completedOrders
          .where(
            (order) =>
                !order.createdAt.isBefore(monthStart) &&
                order.createdAt.isBefore(nextMonthStart),
          )
          .fold<double>(0, (sum, order) => sum + order.totalAmount);

      final periodOrders = allOrders
          .where(
            (order) =>
                !order.createdAt.isBefore(periodStart) &&
                order.createdAt.isBefore(periodEndExclusive),
          )
          .toList();
      final periodCompleted = periodOrders
          .where((order) => order.status == OrderStatus.completed)
          .toList();
      final periodCancelled = periodOrders
          .where((order) => order.status == OrderStatus.cancelled)
          .toList();

      revenueTotalAllTime.value = periodCompleted.fold<double>(
        0,
        (sum, order) => sum + order.totalAmount,
      );
      statisticTotalOrders.value = periodOrders.length;
      statisticCompletedOrders.value = periodCompleted.length;
      statisticCancelledOrders.value = periodCancelled.length;
      statisticAverageOrderValue.value = periodCompleted.isEmpty
          ? 0
          : periodCompleted.fold<double>(
                  0,
                  (sum, order) => sum + order.totalAmount,
                ) /
                periodCompleted.length;

      final usersResponse = await supabase.from('users').select();
      final allUsers = (usersResponse as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
      statisticNewCustomers.value = allUsers
          .where(
            (user) =>
                !user.createdAt.isBefore(periodStart) &&
                user.createdAt.isBefore(periodEndExclusive),
          )
          .length;

      revenueByDay.value = _buildRevenueSeries(
        periodCompleted,
        periodStart,
        periodEndExclusive,
      );

      await _fetchTopProducts(periodCompleted.map((order) => order.id).toSet());
      _buildTopCustomers(periodCompleted);
      await _fetchTopVouchers(periodOrders);
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
    } finally {
      if (showLoading) isLoadingStatistics.value = false;
    }
  }

  (DateTime, DateTime) _resolveStatisticsRange({
    required DateTime now,
    int? days,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate != null && endDate != null) {
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));
      return (start, end);
    }

    final today = DateTime(now.year, now.month, now.day);
    if (days != null) {
      return (
        today.subtract(Duration(days: days - 1)),
        today.add(const Duration(days: 1)),
      );
    }

    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);
    return (startOfThisMonth, startOfNextMonth);
  }

  Future<void> fetchStatisticsForPreset(String preset) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekdayOffset = today.weekday - DateTime.monday;
    final startOfThisWeek = today.subtract(Duration(days: weekdayOffset));

    switch (preset) {
      case 'this_week':
        await fetchStatistics(
          startDate: startOfThisWeek,
          endDate: startOfThisWeek.add(const Duration(days: 6)),
          label: 'Tuần này',
        );
        break;
      case 'last_week':
        final start = startOfThisWeek.subtract(const Duration(days: 7));
        await fetchStatistics(
          startDate: start,
          endDate: start.add(const Duration(days: 6)),
          label: 'Tuần trước',
        );
        break;
      case 'this_month':
        final start = DateTime(now.year, now.month, 1);
        final end = now.month == 12
            ? DateTime(now.year + 1, 1, 1).subtract(const Duration(days: 1))
            : DateTime(
                now.year,
                now.month + 1,
                1,
              ).subtract(const Duration(days: 1));
        await fetchStatistics(
          startDate: start,
          endDate: end,
          label: 'Tháng này',
        );
        break;
      case 'last_month':
        final start = now.month == 1
            ? DateTime(now.year - 1, 12, 1)
            : DateTime(now.year, now.month - 1, 1);
        final end = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(days: 1));
        await fetchStatistics(
          startDate: start,
          endDate: end,
          label: 'Tháng trước',
        );
        break;
      case 'one_year':
        await fetchStatistics(
          startDate: DateTime(now.year, 1, 1),
          endDate: DateTime(now.year, 12, 31),
          label: '1 năm',
        );
        break;
    }
  }

  List<Map<String, dynamic>> _buildRevenueSeries(
    List<OrderModel> completedOrders,
    DateTime start,
    DateTime endExclusive,
  ) {
    final days = endExclusive.difference(start).inDays;
    if (days > 62) {
      final items = <Map<String, dynamic>>[];
      var cursor = DateTime(start.year, start.month, 1);
      while (cursor.isBefore(endExclusive)) {
        final next = cursor.month == 12
            ? DateTime(cursor.year + 1, 1, 1)
            : DateTime(cursor.year, cursor.month + 1, 1);
        final monthEnd = next.isBefore(endExclusive) ? next : endExclusive;
        final orders = completedOrders
            .where(
              (order) =>
                  !order.createdAt.isBefore(cursor) &&
                  order.createdAt.isBefore(monthEnd),
            )
            .toList();
        items.add({
          'label': '${cursor.month}/${cursor.year.toString().substring(2)}',
          'revenue': orders.fold<double>(
            0,
            (sum, order) => sum + order.totalAmount,
          ),
          'orders': orders.length,
        });
        cursor = next;
      }
      return items;
    }

    return List.generate(days, (index) {
      final day = start.add(Duration(days: index));
      final nextDay = day.add(const Duration(days: 1));
      final dayOrders = completedOrders
          .where(
            (order) =>
                !order.createdAt.isBefore(day) &&
                order.createdAt.isBefore(nextDay),
          )
          .toList();
      return {
        'label': '${day.day}/${day.month}',
        'revenue': dayOrders.fold<double>(
          0,
          (sum, order) => sum + order.totalAmount,
        ),
        'orders': dayOrders.length,
      };
    });
  }

  Future<void> _fetchTopProducts(Set<String> completedOrderIds) async {
    if (completedOrderIds.isEmpty) {
      topSellingProducts.clear();
      productSalesStats.clear();
      return;
    }

    final itemsResponse = await supabase
        .from('order_items')
        .select('*, products(*)');
    final productStats = <String, Map<String, dynamic>>{};

    for (final raw in itemsResponse as List) {
      final item = Map<String, dynamic>.from(raw as Map);
      final orderId = item['order_id']?.toString();
      if (orderId == null || !completedOrderIds.contains(orderId)) continue;

      final productId = item['product_id']?.toString() ?? '';
      final product = item['products'] as Map<String, dynamic>?;
      final name =
          item['product_name']?.toString() ??
          product?['name']?.toString() ??
          'Sản phẩm';
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      final price = (item['price'] as num?)?.toDouble() ?? 0;
      final options = item['options'];
      double extra = 0;
      if (options is List) {
        extra = options.fold<double>(
          0,
          (sum, option) =>
              sum + (((option as Map?)?['price'] as num?)?.toDouble() ?? 0),
        );
      }
      final revenue = (price + extra) * quantity;

      final current = productStats.putIfAbsent(productId, () {
        return {'name': name, 'quantity': 0, 'revenue': 0.0};
      });
      current['quantity'] = (current['quantity'] as int) + quantity;
      current['revenue'] = (current['revenue'] as double) + revenue;
    }

    final sorted = productStats.values.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    productSalesStats.value = sorted;
    topSellingProducts.value = sorted.take(5).toList();
  }

  void _buildTopCustomers(List<OrderModel> completedOrders) {
    final customerStats = <String, Map<String, dynamic>>{};

    for (final order in completedOrders) {
      final current = customerStats.putIfAbsent(order.userId, () {
        return {
          'name': order.customer?.fullName ?? 'Khách hàng',
          'phone': order.customer?.phone ?? '',
          'orders': 0,
          'spent': 0.0,
        };
      });
      current['orders'] = (current['orders'] as int) + 1;
      current['spent'] = (current['spent'] as double) + order.totalAmount;
    }

    final sorted = customerStats.values.toList()
      ..sort((a, b) => (b['spent'] as double).compareTo(a['spent'] as double));
    topSpendingCustomers.value = sorted.take(5).toList();
  }

  Future<void> _fetchTopVouchers(List<OrderModel> periodOrders) async {
    final voucherOrderStats = <String, Map<String, dynamic>>{};
    for (final order in periodOrders) {
      final voucherId = order.voucherId;
      if (voucherId == null || voucherId.isEmpty) continue;

      final current = voucherOrderStats.putIfAbsent(voucherId, () {
        return {
          'id': voucherId,
          'code': voucherId.substring(
            0,
            voucherId.length > 8 ? 8 : voucherId.length,
          ),
          'orders': 0,
          'discount': 0.0,
        };
      });
      current['orders'] = (current['orders'] as int) + 1;
      current['discount'] =
          (current['discount'] as double) + order.discountAmount;
    }

    if (voucherOrderStats.isNotEmpty) {
      final vouchersResponse = await supabase.from('vouchers').select();
      for (final raw in vouchersResponse as List) {
        final voucher = Map<String, dynamic>.from(raw as Map);
        final id = voucher['id']?.toString();
        if (id != null && voucherOrderStats.containsKey(id)) {
          voucherOrderStats[id]!['code'] = voucher['code']?.toString() ?? id;
        }
      }
    }

    final sorted = voucherOrderStats.values.toList()
      ..sort((a, b) => (b['orders'] as int).compareTo(a['orders'] as int));
    topUsedVouchers.value = sorted.take(5).toList();
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

  Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      await supabase.from('products').insert(productData);
      await fetchProducts();
      Get.snackbar(
        'Thành công',
        'Đã thêm sản phẩm',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      print('Error adding product: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể thêm sản phẩm',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductOptions(
    String productId,
  ) async {
    try {
      final response = await supabase
          .from('product_options')
          .select()
          .eq('product_id', productId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error fetching product options: $e');
      return [];
    }
  }

  Future<bool> saveProductWithOptions({
    required Map<String, dynamic> productData,
    required List<Map<String, dynamic>> optionsData,
    String? productId,
  }) async {
    try {
      final String savedProductId;

      if (productId == null) {
        final response = await supabase
            .from('products')
            .insert(productData)
            .select('id')
            .single();
        savedProductId = response['id'] as String;
      } else {
        await supabase.from('products').update(productData).eq('id', productId);
        savedProductId = productId;
      }

      await supabase
          .from('product_options')
          .delete()
          .eq('product_id', savedProductId);

      if (optionsData.isNotEmpty) {
        final records = optionsData
            .map((option) => {...option, 'product_id': savedProductId})
            .toList();
        await supabase.from('product_options').insert(records);
      }

      await fetchProducts();
      Get.snackbar(
        'Thành công',
        productId == null ? 'Đã thêm sản phẩm' : 'Đã cập nhật sản phẩm',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error saving product with options: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể lưu sản phẩm và tùy chọn',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    try {
      await supabase.from('products').update(productData).eq('id', productId);
      await fetchProducts();
      Get.snackbar(
        'Thành công',
        'Đã cập nhật sản phẩm',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      print('Error updating product: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật sản phẩm',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await supabase.from('products').delete().eq('id', productId);
      await fetchProducts();
      Get.snackbar(
        'Thành công',
        'Đã xóa sản phẩm',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting product: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xóa sản phẩm',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ==================== ORDER MANAGEMENT ====================
  Future<void> fetchOrders() async {
    try {
      isLoadingOrders.value = true;

      final response = await supabase
          .from('orders')
          .select('*, customer:users!user_id(*), addresses(*)')
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

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? cancelReason,
  }) async {
    try {
      final currentOrder = orders.firstWhereOrNull(
        (order) => order.id == orderId,
      );

      final updateData = <String, dynamic>{'status': status};
      if (status == OrderStatus.cancelled.value &&
          cancelReason != null &&
          cancelReason.trim().isNotEmpty) {
        updateData['cancel_reason'] = cancelReason.trim();
      }

      await supabase.from('orders').update(updateData).eq('id', orderId);

      if (status == OrderStatus.completed.value && currentOrder != null) {
        await _awardLoyaltyPoints(currentOrder);
      }

      await fetchOrders();
      await fetchDashboardStats();
      await fetchStatistics(showLoading: false);
      await fetchUsers();

      Get.snackbar(
        'Thành công',
        'Đã cập nhật trạng thái đơn hàng',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating order status: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật trạng thái',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _awardLoyaltyPoints(OrderModel order) async {
    try {
      final existing = await supabase
          .from('loyalty_transactions')
          .select('id')
          .eq('order_id', order.id)
          .gt('points', 0)
          .maybeSingle();

      if (existing != null) return;

      final settings = await supabase
          .from('shop_settings')
          .select('loyalty_rate')
          .eq('id', 1)
          .maybeSingle();
      final loyaltyRate =
          ((settings?['loyalty_rate'] as num?)?.toDouble() ?? 1.0);
      final points = (order.totalAmount * loyaltyRate / 100).floor();

      if (points <= 0) return;

      await supabase.from('loyalty_transactions').insert({
        'user_id': order.userId,
        'order_id': order.id,
        'points': points,
        'reason': 'Tích điểm từ đơn hàng #${order.displayCode}',
      });
    } catch (e) {
      debugPrint('Error awarding loyalty points: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================
  Future<void> syncReadyOrderNotifications() async {
    try {
      await supabase.rpc('create_admin_notifications_for_ready_orders');
    } catch (e) {
      print('Error syncing ready order notifications: $e');
    }
  }

  Future<void> fetchNotifications({bool showLoading = true}) async {
    try {
      if (showLoading) isLoadingNotifications.value = true;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('notifications')
          .select('*, orders(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);

      notifications.value = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      unreadNotifications.value = notifications
          .where((notification) => !notification.isRead)
          .length;
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      if (showLoading) isLoadingNotifications.value = false;
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      await fetchNotifications(showLoading: false);
    } catch (e) {
      print('Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      await fetchNotifications(showLoading: false);
    } catch (e) {
      print('Error marking all notifications read: $e');
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

      Get.snackbar(
        'Thành công',
        'Đã cập nhật trạng thái người dùng',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating user status: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật trạng thái',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
