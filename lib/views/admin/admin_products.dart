// lib/views/admin/admin_products.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/admin_controller.dart';
import 'package:xommoigarden/controller/category_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/views/widgets/product_dialog.dart';

class AdminProducts extends StatefulWidget {
  const AdminProducts({super.key});

  @override
  State<AdminProducts> createState() => _AdminProductsState();
}

class _AdminProductsState extends State<AdminProducts> {
  final AdminController adminController = Get.find();
  final CategoryController categoryController = Get.put(CategoryController());
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    categoryController.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sản phẩm', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Header: search + count
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm...',
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
                          Icon(Icons.inventory_2, size: 18, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            '${adminController.products.length} sản phẩm',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => adminController.fetchProducts(),
                      icon: Icon(Icons.refresh, color: Colors.grey.shade600),
                      tooltip: 'Tải lại',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child: Obx(() {
              if (adminController.isLoadingProducts.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var filteredProducts = adminController.products.toList();
              if (searchQuery.isNotEmpty) {
                filteredProducts = filteredProducts
                    .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();
              }

              if (filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isNotEmpty
                            ? 'Không tìm thấy sản phẩm'
                            : 'Chưa có sản phẩm nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      if (searchQuery.isEmpty) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showProductDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm sản phẩm đầu tiên'),
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 5;
                  } else if (constraints.maxWidth > 900) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 3;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(filteredProducts[index]);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + badges
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
                // Availability badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.isAvailable ? Colors.green.shade600 : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.isAvailable ? 'Còn hàng' : 'Hết hàng',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // Rating badge
                if (product.totalReviews > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            product.ratingDisplay,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  // Actions
                  Row(
                    children: [
                      Text(
                        '${product.totalReviews} đánh giá',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      const Spacer(),
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        color: Colors.blue,
                        tooltip: 'Sửa',
                        onPressed: () => _showProductDialog(product: product),
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        tooltip: 'Xóa',
                        onPressed: () => _showDeleteDialog(product),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade300),
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

  void _showProductDialog({ProductModel? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductDialog(
        product: product,
        onSuccess: () {
          adminController.fetchProducts();
        },
      ),
    );
  }

  void _showDeleteDialog(ProductModel product) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Xóa sản phẩm'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await adminController.deleteProduct(product.id);
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
}
