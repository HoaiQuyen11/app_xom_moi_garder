// lib/widgets/admin/product_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/admin_controller.dart';
import 'package:xommoigarden/controller/category_controller.dart';
import 'package:xommoigarden/model/product_model.dart';

class ProductDialog extends StatefulWidget {
  final ProductModel? product;
  final VoidCallback onSuccess;

  const ProductDialog({
    super.key,
    this.product,
    required this.onSuccess,
  });

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
  final TextEditingController imageUrlController = TextEditingController();

  String? selectedCategoryId;
  bool isAvailable = true;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      nameController.text = widget.product!.name;
      priceController.text = widget.product!.price.toString();
      descriptionController.text = widget.product!.description ?? '';
      imageUrlController.text = widget.product!.imageUrl ?? '';
      selectedCategoryId = widget.product!.categoryId;
      isAvailable = widget.product!.isAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập giá' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL hình ảnh',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Chọn danh mục')),
                  ...categoryController.categories.map((cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Còn hàng'),
                value: isAvailable,
                onChanged: (value) {
                  setState(() {
                    isAvailable = value;
                  });
                },
                activeColor: Colors.green,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Lưu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final productData = {
        'name': nameController.text,
        'price': double.parse(priceController.text),
        'description': descriptionController.text,
        'image_url': imageUrlController.text,
        'category_id': selectedCategoryId,
        'is_available': isAvailable,
      };

      if (widget.product == null) {
        await adminController.addProduct(productData);
      } else {
        await adminController.updateProduct(widget.product!.id, productData);
      }

      widget.onSuccess();
      Get.back();
    }
  }
}