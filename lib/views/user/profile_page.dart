// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/controller/order_controller.dart';
import 'package:xommoigarden/controller/profile_controller.dart';
import 'package:xommoigarden/model/user_model.dart';
import 'package:xommoigarden/views/user/edit_profile_page.dart';
import 'package:xommoigarden/views/user/order_history_page.dart';


class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final ControllerAuth authController = Get.find();
  final ControllerProfile profileController = Get.find();
  final ControllerOrder orderController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      body: Obx(() {
        final user = authController.currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Header với avatar
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade400, Colors.green.shade700],
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: user.avatarUrl != null
                            ? Image.network(
                          user.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarPlaceholder(user);
                          },
                        )
                            : _buildAvatarPlaceholder(user),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName ?? 'Người dùng',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role == 'admin'
                            ? 'Quản trị viên'
                            : user.role == 'shipper'
                            ? 'Shipper'
                            : 'Khách hàng',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (user.role == 'shipper') ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            user.shipperRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${user.totalDeliveries} đơn',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Thông tin chi tiết
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Thông tin cơ bản
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email ?? 'Chưa cập nhật',
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.phone_outlined,
                            label: 'Số điện thoại',
                            value: user.phone ?? 'Chưa cập nhật',
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.stars_outlined,
                            label: 'Điểm tích lũy',
                            value: '${user.loyaltyPoints} điểm',
                            isPoints: true,
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Tham gia ngày',
                            value: _formatDate(user.createdAt),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Menu chức năng
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.history,
                            label: 'Lịch sử đơn hàng',
                            onTap: () {
                              Get.to(() =>  OrderHistoryPage());
                            },
                          ),
                          _buildDivider(),
                          _buildMenuTile(
                            icon: Icons.edit_outlined,
                            label: 'Chỉnh sửa thông tin',
                            onTap: () {
                              Get.to(() => EditProfilePage());
                            },
                          ),
                          if (user.role == 'shipper') ...[
                            _buildDivider(),
                            _buildMenuTile(
                              icon: Icons.delivery_dining,
                              label: 'Quản lý đơn giao',
                              onTap: () {
                                // Đi tới trang quản lý đơn của shipper
                              },
                            ),
                            _buildDivider(),
                            _buildSwitchTile(
                              icon: Icons.toggle_on_outlined,
                              label: 'Sẵn sàng nhận đơn',
                              value: user.isAvailable,
                              onChanged: (value) {
                                profileController.updateShipperStatus(value);
                              },
                            ),
                          ],
                          if (user.role == 'admin') ...[
                            _buildDivider(),
                            _buildMenuTile(
                              icon: Icons.dashboard,
                              label: 'Quản trị',
                              onTap: () {
                                // Đi tới trang admin dashboard
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAvatarPlaceholder(UserModel user) {
    return Container(
      color: Colors.green.shade100,
      child: Center(
        child: Text(
          user.fullName?[0]?.toUpperCase() ?? 'U',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isPoints = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isPoints ? Colors.orange : Colors.black,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.green),
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              authController.logout();
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}