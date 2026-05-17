// lib/widgets/admin/product_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/admin_controller.dart';
import 'package:xommoigarden/controller/category_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/views/widgets/productImage_picker.dart';

// ✅ Import widget tải ảnh mới (thay thế cho ô nhập URL)

class ProductDialog extends StatefulWidget {
  final ProductModel? product;
  final VoidCallback onSuccess;

  const ProductDialog({super.key, this.product, required this.onSuccess});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final AdminController adminController = Get.find();
  final CategoryController categoryController = Get.find();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // ✅ Bỏ imageUrlController — thay bằng biến String lưu URL ảnh sau khi tải lên
  String? _selectedImageUrl;

  String? selectedCategoryId;
  bool isAvailable = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      // Điền thông tin sản phẩm cũ vào form khi đang chỉnh sửa
      nameController.text = widget.product!.name;
      priceController.text = widget.product!.price.toString();
      descriptionController.text = widget.product!.description ?? '';
      selectedCategoryId = widget.product!.categoryId;
      isAvailable = widget.product!.isAvailable;

      // ✅ Lấy URL ảnh cũ làm giá trị ban đầu cho widget tải ảnh
      _selectedImageUrl = widget.product!.imageUrl;
    }
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ các controller khi dialog đóng
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        // ✅ Thêm constraints để dialog không bị tràn màn hình khi có ảnh preview
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          // ✅ Bọc trong SingleChildScrollView để scroll được khi nội dung dài
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiêu đề dialog: "Thêm sản phẩm" hoặc "Sửa sản phẩm"
                Text(
                  widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Ô nhập tên sản phẩm
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 16),

                // Ô nhập giá sản phẩm (chỉ nhận số)
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Vui lòng nhập giá' : null,
                ),
                const SizedBox(height: 16),

                // Ô nhập mô tả sản phẩm (nhiều dòng)
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // ✅ Widget tải ảnh lên Supabase (thay thế ô nhập URL cũ)
                // Khi tải ảnh thành công → _selectedImageUrl được cập nhật tự động
                ProductImagePicker(
                  initialImageUrl: _selectedImageUrl,
                  onImageUploaded: (url) {
                    setState(() {
                      _selectedImageUrl = url.isEmpty ? null : url;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Dropdown chọn danh mục sản phẩm
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Chọn danh mục'),
                    ),
                    ...categoryController.categories.map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => selectedCategoryId = value);
                  },
                ),
                const SizedBox(height: 16),

                // Toggle bật/tắt trạng thái còn hàng
                SwitchListTile(
                  title: const Text('Còn hàng'),
                  value: isAvailable,
                  onChanged: (value) {
                    setState(() => isAvailable = value);
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(height: 24),

                // Hàng nút Hủy / Lưu
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lưu sản phẩm: gọi API thêm mới hoặc cập nhật tuỳ trường hợp
  void _saveProduct() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final productData = {
        'name': nameController.text,
        'price': double.parse(priceController.text),
        'description': descriptionController.text,

        // ✅ Dùng _selectedImageUrl thay vì imageUrlController.text
        // Đây là URL công khai từ Supabase Storage sau khi tải ảnh lên
        'image_url': _selectedImageUrl,

        'category_id': selectedCategoryId,
        'is_available': isAvailable,
      };

      final bool saved;
      if (widget.product == null) {
        // Thêm sản phẩm mới vào database
        saved = await adminController.addProduct(productData);
      } else {
        // Cập nhật sản phẩm đã có trong database
        saved = await adminController.updateProduct(
          widget.product!.id,
          productData,
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (saved) {
        widget.onSuccess();
        Navigator.of(context).pop();
      }
    }
  }
}
