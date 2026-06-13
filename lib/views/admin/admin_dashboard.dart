// lib/views/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/admin_controller.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/notification_model.dart';
import 'package:xommoigarden/views/admin/admin_categories.dart';

import 'package:xommoigarden/views/admin/admin_orders.dart';
import 'package:xommoigarden/views/admin/admin_products.dart';
import 'package:xommoigarden/views/admin/admin_statistics.dart';
import 'package:xommoigarden/views/admin/admin_users.dart';
import 'package:xommoigarden/views/admin/admin_vouchers.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminController adminController = Get.put(AdminController());
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminStatistics(),
    const AdminProducts(),
    const AdminOrders(),
    const AdminUsers(),
    AdminCategories(),
    const AdminVouchers(),
  ];

  final List<String> _titles = [
    'Tổng quan',
    'Quản lý sản phẩm',
    'Quản lý đơn hàng',
    'Quản lý người dùng',
    'Quản lý danh mục',
    'Quản lý voucher',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.query_stats_outlined),
                selectedIcon: Icon(Icons.query_stats),
                label: Text('Thống kê'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory),
                selectedIcon: Icon(Icons.inventory),
                label: Text('Sản phẩm'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Đơn hàng'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                selectedIcon: Icon(Icons.people),
                label: Text('Người dùng'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                selectedIcon: Icon(Icons.category),
                label: Text('Danh mục'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_number),
                label: Text('Voucher'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  _selectedIndex == 0 ? 'Thống kê' : _titles[_selectedIndex],
                ),
                centerTitle: false,
                elevation: 0,
                actions: [
                  Obx(
                    () => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: _showNotifications,
                        ),
                        if (adminController.unreadNotifications.value > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                adminController.unreadNotifications.value > 9
                                    ? '9+'
                                    : adminController.unreadNotifications.value
                                          .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await Get.find<ControllerAuth>().logout();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 20),
                            SizedBox(width: 10),
                            Text('Thông tin cá nhân'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              'Đăng xuất',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications() async {
    await adminController.syncReadyOrderNotifications();
    await adminController.fetchNotifications();

    Get.dialog(
      AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        title: Row(
          children: [
            const Expanded(child: Text('Thông báo')),
            TextButton(
              onPressed: () => adminController.markAllNotificationsRead(),
              child: const Text('Đã đọc hết'),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Obx(() {
            if (adminController.isLoadingNotifications.value) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (adminController.notifications.isEmpty) {
              return SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: adminController.notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = adminController.notifications[index];
                  return _buildNotificationTile(notification);
                },
              ),
            );
          }),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: notification.isRead
            ? Colors.grey.shade100
            : Colors.orange.shade50,
        child: Icon(
          Icons.receipt_long,
          color: notification.isRead
              ? Colors.grey.shade600
              : Colors.orange.shade700,
        ),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message),
          const SizedBox(height: 2),
          Text(
            _formatNotificationTime(notification.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      onTap: () async {
        await adminController.markNotificationRead(notification.id);
        if (notification.relatedOrderId != null) {
          setState(() => _selectedIndex = 2);
          Get.back();
        }
      },
    );
  }

  String _formatNotificationTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Dashboard Content
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController controller = Get.find();

    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng người dùng',
                    value: controller.totalUsers.value,
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng sản phẩm',
                    value: controller.totalProducts.value,
                    icon: Icons.inventory,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng đơn hàng',
                    value: controller.totalOrders.value,
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildStatCard(
                    title: 'Doanh thu',
                    value: '${controller.totalRevenue.value}đ',
                    icon: Icons.attach_money,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent orders
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đơn hàng gần đây',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (controller.recentOrders.isEmpty)
                      const Center(child: Text('Chưa có đơn hàng nào'))
                    else
                      SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Mã đơn')),
                            DataColumn(label: Text('Khách hàng')),
                            DataColumn(label: Text('Tổng tiền')),
                            DataColumn(label: Text('Trạng thái')),
                            DataColumn(label: Text('Ngày tạo')),
                          ],
                          rows: controller.recentOrders.map((order) {
                            return DataRow(
                              cells: [
                                DataCell(Text(order.id.substring(0, 8))),
                                DataCell(Text(order.userId.substring(0, 8))),
                                DataCell(
                                  Text(
                                    '${order.totalAmount.toStringAsFixed(0)}đ',
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        order.status,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      order.status.displayName,
                                      style: TextStyle(
                                        color: _getStatusColor(order.status),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(_formatDate(order.createdAt))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required dynamic value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.delivering:
        return Colors.cyan;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
