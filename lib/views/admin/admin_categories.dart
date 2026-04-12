// lib/views/admin/admin_categories.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/category_controller.dart';
import 'package:xommoigarden/model/category_model.dart';

class AdminCategories extends StatefulWidget {
  const AdminCategories({super.key});

  @override
  State<AdminCategories> createState() => _AdminCategoriesState();
}

class _AdminCategoriesState extends State<AdminCategories> {
  final CategoryController categoryController = Get.find();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm danh mục', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              color: Colors.white,
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
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm danh mục...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.category, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${categoryController.categories.length} danh mục',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                )),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => categoryController.fetchCategories(),
                  icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                  tooltip: 'Tải lại',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (categoryController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var filtered = categoryController.categories.toList();
              if (searchQuery.isNotEmpty) {
                filtered = filtered
                    .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isNotEmpty ? 'Không tìm thấy danh mục' : 'Chưa có danh mục nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      if (searchQuery.isEmpty) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showCategoryDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm danh mục đầu tiên'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              // Stats row
              final totalProducts = filtered.fold<int>(0, (sum, c) => sum + c.productCount);

              return Column(
                children: [
                  // Summary stats
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.category,
                          label: '${filtered.length} danh mục',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.inventory_2,
                          label: '$totalProducts sản phẩm',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),

                  // Category grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth > 1200) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth > 800) {
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildCategoryCard(filtered[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${category.productCount} sản phẩm',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tạo: ${_formatDate(category.createdAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  color: Colors.blue,
                  tooltip: 'Sửa',
                  onPressed: () => _showCategoryDialog(category: category),
                ),
                const SizedBox(height: 4),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  tooltip: 'Xóa',
                  onPressed: () => _showDeleteDialog(category),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  void _showCategoryDialog({CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final isEdit = category != null;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit : Icons.add_circle_outline,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 8),
            Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục'),
          ],
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Tên danh mục',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade700, width: 1.5),
            ),
          ),
          autofocus: true,
          onSubmitted: (_) {
            if (nameController.text.trim().isNotEmpty) {
              _saveCategory(nameController.text.trim(), category);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _saveCategory(nameController.text.trim(), category);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isEdit ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  void _saveCategory(String name, CategoryModel? existing) {
    Get.back();
    if (existing != null) {
      categoryController.updateCategory(existing.id, name);
    } else {
      categoryController.addCategory(name);
    }
  }

  void _showDeleteDialog(CategoryModel category) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Xóa danh mục'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn xóa danh mục "${category.name}"?'),
            if (category.productCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Danh mục này đang có ${category.productCount} sản phẩm.',
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              categoryController.deleteCategory(category.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
