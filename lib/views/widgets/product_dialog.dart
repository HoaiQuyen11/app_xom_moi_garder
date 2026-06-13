// lib/widgets/admin/product_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/admin_controller.dart';
import 'package:xommoigarden/controller/category_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/views/widgets/productImage_picker.dart';

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

  final List<_EditableProductOption> _options = [];

  String? _selectedImageUrl;
  String? selectedCategoryId;
  bool isAvailable = true;
  bool _isSaving = false;
  bool _isLoadingOptions = false;
  bool _showImageRequiredError = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      nameController.text = widget.product!.name;
      priceController.text = widget.product!.price.toStringAsFixed(0);
      descriptionController.text = widget.product!.description ?? '';
      selectedCategoryId = widget.product!.categoryId;
      isAvailable = widget.product!.isAvailable;
      _selectedImageUrl = widget.product!.imageUrl;
      _loadProductOptions();
    }
  }

  Future<void> _loadProductOptions() async {
    setState(() => _isLoadingOptions = true);
    final rows = await adminController.fetchProductOptions(widget.product!.id);

    if (!mounted) return;
    setState(() {
      _options
        ..clear()
        ..addAll(rows.map(_EditableProductOption.fromJson));
      _isLoadingOptions = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập giá';
                    }
                    if (_parsePrice(value) == null) {
                      return 'Giá không hợp lệ';
                    }
                    return null;
                  },
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
                ProductImagePicker(
                  initialImageUrl: _selectedImageUrl,
                  onImageUploaded: (url) {
                    setState(() {
                      _selectedImageUrl = url.isEmpty ? null : url;
                      _showImageRequiredError = false;
                    });
                  },
                ),
                if (_showImageRequiredError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      'Vui lòng tải ảnh lên',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng chọn danh mục';
                    }
                    return null;
                  },
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
                SwitchListTile(
                  title: const Text('Còn hàng'),
                  value: isAvailable,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() => isAvailable = value);
                  },
                  activeThumbColor: Colors.green,
                ),
                const SizedBox(height: 12),
                _buildOptionsSection(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Get.back(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving || _isLoadingOptions
                          ? null
                          : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Lưu'),
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

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tùy chọn sản phẩm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _isLoadingOptions ? null : _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Thêm option'),
            ),
          ],
        ),
        if (_isLoadingOptions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_options.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Chưa có option. Ví dụ: Size, Topping, Độ ngọt...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ..._options.asMap().entries.map(
            (entry) => _buildOptionCard(entry.key, entry.value),
          ),
      ],
    );
  }

  Widget _buildOptionCard(int optionIndex, _EditableProductOption option) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: option.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên option',
                    hintText: 'Size, Topping...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (text) {
                    if (_isOptionNameRequired(option) &&
                        (text == null || text.trim().isEmpty)) {
                      return 'Vui lòng nhập tên option';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeOption(optionIndex),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Xóa option',
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Bắt buộc chọn'),
            value: option.isRequired,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: Colors.green,
            onChanged: (value) {
              setState(() => option.isRequired = value);
            },
          ),
          ...option.values.asMap().entries.map(
            (entry) => _buildOptionValueRow(option, entry.key, entry.value),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => option.values.add(_EditableOptionValue()));
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm giá trị'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionValueRow(
    _EditableProductOption option,
    int valueIndex,
    _EditableOptionValue value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: value.labelController,
              decoration: const InputDecoration(
                labelText: 'Giá trị',
                hintText: 'Nhỏ, Vừa, Lớn...',
                border: OutlineInputBorder(),
              ),
              validator: (text) {
                if (_isOptionValueRequired(option, value) &&
                    (text == null || text.trim().isEmpty)) {
                  return 'Vui lòng nhập giá trị của option';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: value.priceController,
              decoration: const InputDecoration(
                labelText: 'Giá cộng',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (text) {
                if (text != null &&
                    text.trim().isNotEmpty &&
                    _parsePrice(text) == null) {
                  return 'Giá cộng không hợp lệ';
                }
                return null;
              },
            ),
          ),
          IconButton(
            onPressed: option.values.length == 1
                ? null
                : () {
                    setState(() {
                      final removed = option.values.removeAt(valueIndex);
                      removed.dispose();
                    });
                  },
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.red,
            tooltip: 'Xóa giá trị',
          ),
        ],
      ),
    );
  }

  void _addOption() {
    setState(() {
      _options.add(_EditableProductOption());
    });
  }

  void _removeOption(int index) {
    setState(() {
      final removed = _options.removeAt(index);
      removed.dispose();
    });
  }

  double? _parsePrice(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  bool _isOptionNameRequired(_EditableProductOption option) {
    return _options.contains(option);
  }

  bool _isOptionValueRequired(
    _EditableProductOption option,
    _EditableOptionValue value,
  ) {
    return option.values.contains(value);
  }

  List<Map<String, dynamic>>? _buildOptionsPayload() {
    final payload = <Map<String, dynamic>>[];

    for (final option in _options) {
      final optionName = option.nameController.text.trim();
      final values = <Map<String, dynamic>>[];

      for (final value in option.values) {
        final label = value.labelController.text.trim();
        final priceText = value.priceController.text.trim();

        if (label.isEmpty && priceText.isEmpty) continue;

        final price = priceText.isEmpty ? 0.0 : _parsePrice(priceText);
        if (label.isEmpty || price == null) {
          return null;
        }

        values.add({'label': label, 'price': price});
      }

      if (optionName.isEmpty && values.isEmpty) continue;
      if (optionName.isEmpty || values.isEmpty) {
        return null;
      }

      payload.add({
        'name': optionName,
        'values': values,
        'is_required': option.isRequired,
      });
    }

    return payload;
  }

  void _saveProduct() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageUrl == null || _selectedImageUrl!.trim().isEmpty) {
      setState(() => _showImageRequiredError = true);
      return;
    }

    final optionsPayload = _buildOptionsPayload();
    if (optionsPayload == null) return;

    setState(() => _isSaving = true);

    final productData = {
      'name': nameController.text.trim(),
      'price': _parsePrice(priceController.text)!,
      'description': descriptionController.text.trim(),
      'image_url': _selectedImageUrl,
      'category_id': selectedCategoryId,
      'is_available': isAvailable,
    };

    final saved = await adminController.saveProductWithOptions(
      productId: widget.product?.id,
      productData: productData,
      optionsData: optionsPayload,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (saved) {
      widget.onSuccess();
      Navigator.of(context).pop();
    }
  }
}

class _EditableProductOption {
  final TextEditingController nameController;
  final List<_EditableOptionValue> values;
  bool isRequired;

  _EditableProductOption({
    String name = '',
    this.isRequired = false,
    List<_EditableOptionValue>? values,
  }) : nameController = TextEditingController(text: name),
       values = values ?? [_EditableOptionValue()];

  factory _EditableProductOption.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as List? ?? [];
    return _EditableProductOption(
      name: json['name'] as String? ?? '',
      isRequired: json['is_required'] as bool? ?? false,
      values: rawValues.isEmpty
          ? [_EditableOptionValue()]
          : rawValues
                .map(
                  (value) => _EditableOptionValue.fromJson(
                    Map<String, dynamic>.from(value as Map),
                  ),
                )
                .toList(),
    );
  }

  void dispose() {
    nameController.dispose();
    for (final value in values) {
      value.dispose();
    }
  }
}

class _EditableOptionValue {
  final TextEditingController labelController;
  final TextEditingController priceController;

  _EditableOptionValue({String label = '', double price = 0})
    : labelController = TextEditingController(text: label),
      priceController = TextEditingController(
        text: price == 0 ? '0' : price.toStringAsFixed(0),
      );

  factory _EditableOptionValue.fromJson(Map<String, dynamic> json) {
    return _EditableOptionValue(
      label: json['label'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  void dispose() {
    labelController.dispose();
    priceController.dispose();
  }
}
