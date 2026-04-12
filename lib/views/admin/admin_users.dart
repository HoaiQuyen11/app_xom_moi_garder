// lib/views/admin/admin_users.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/admin_controller.dart';
import 'package:xommoigarden/model/enums.dart';
import 'package:xommoigarden/model/user_model.dart';


class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  final AdminController adminController = Get.find();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    adminController.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người dùng...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text('Tất cả vai trò'),
                    value: selectedRole,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tất cả')),
                      ...UserRole.values.map((role) => DropdownMenuItem(
                        value: role.value,
                        child: Text(role.displayName),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Users table
        Expanded(
          child: Obx(() {
            if (adminController.isLoadingUsers.value) {
              return const Center(child: CircularProgressIndicator());
            }

            var filteredUsers = adminController.users.toList();
            if (searchQuery.isNotEmpty) {
              filteredUsers = filteredUsers.where((u) =>
              (u.fullName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                  (u.email?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                  (u.phone?.contains(searchQuery) ?? false)
              ).toList();
            }
            if (selectedRole != null) {
              filteredUsers = filteredUsers.where((u) =>
              u.role.value == selectedRole
              ).toList();
            }

            if (filteredUsers.isEmpty) {
              return const Center(child: Text('Chưa có người dùng nào'));
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Họ tên')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('SĐT')),
                  DataColumn(label: Text('Vai trò')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Điểm')),
                  DataColumn(label: Text('Thao tác')),
                ],
                rows: filteredUsers.map((user) {
                  return DataRow(cells: [
                    DataCell(Text(user.fullName ?? '---')),
                    DataCell(Text(user.email ?? '---')),
                    DataCell(Text(user.phone ?? '---')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.displayName,
                        style: TextStyle(color: _getRoleColor(user.role)),
                      ),
                    )),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.status.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.status.displayName,
                        style: TextStyle(color: user.status.color),
                      ),
                    )),
                    DataCell(Text('${user.loyaltyPoints}')),
                    DataCell(Row(
                      children: [
                        if (user.status == UserStatus.active)
                          IconButton(
                            icon: const Icon(Icons.block, color: Colors.orange),
                            onPressed: () => _updateStatus(user, UserStatus.inactive),
                            tooltip: 'Khóa tài khoản',
                          ),
                        if (user.status == UserStatus.inactive)
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _updateStatus(user, UserStatus.active),
                            tooltip: 'Mở khóa',
                          ),
                        if (user.status != UserStatus.banned)
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _updateStatus(user, UserStatus.banned),
                            tooltip: 'Cấm vĩnh viễn',
                          ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.customer:
        return Colors.blue;
      case UserRole.shipper:
        return Colors.green;
    }
  }

  void _updateStatus(UserModel user, UserStatus status) async {
    final message = status == UserStatus.active
        ? 'Mở khóa tài khoản "${user.fullName}"?'
        : status == UserStatus.inactive
        ? 'Khóa tài khoản "${user.fullName}"?'
        : 'Cấm vĩnh viễn tài khoản "${user.fullName}"?';

    Get.dialog(
      AlertDialog(
        title: Text(status == UserStatus.active ? 'Mở khóa' : 'Khóa tài khoản'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await adminController.updateUserStatus(user.id, status);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}