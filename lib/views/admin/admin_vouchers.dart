import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/voucher_controller.dart';
import 'package:xommoigarden/model/voucher_model.dart';

class AdminVouchers extends StatefulWidget {
  const AdminVouchers({super.key});

  @override
  State<AdminVouchers> createState() => _AdminVouchersState();
}

class _AdminVouchersState extends State<AdminVouchers> {
  final ControllerVoucher voucherController = Get.find<ControllerVoucher>();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    voucherController.fetchAdminVouchers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVoucherDialog(),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm voucher',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() {
              if (voucherController.isLoading.value &&
                  voucherController.adminVouchers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final vouchers = _filteredVouchers();
              if (vouchers.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: voucherController.fetchAdminVouchers,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  itemCount: vouchers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildVoucherTile(vouchers[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                hintText: 'Tìm voucher theo mã hoặc mô tả...',
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
                  borderSide: BorderSide(
                    color: Colors.green.shade700,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => _buildCountChip(
              '${voucherController.adminVouchers.length} voucher',
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: voucherController.fetchAdminVouchers,
            icon: Icon(Icons.refresh, color: Colors.grey.shade600),
            tooltip: 'Tải lại',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.confirmation_number,
            size: 18,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'Chưa có voucher nào'
                : 'Không tìm thấy voucher',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          if (searchQuery.isEmpty) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showVoucherDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm voucher đầu tiên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<VoucherModel> _filteredVouchers() {
    var vouchers = voucherController.adminVouchers.toList();
    if (searchQuery.trim().isEmpty) return vouchers;

    final query = searchQuery.toLowerCase();
    return vouchers
        .where(
          (voucher) =>
              voucher.code.toLowerCase().contains(query) ||
              (voucher.description?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Widget _buildVoucherTile(VoucherModel voucher) {
    final canUseColor = voucher.canUse ? Colors.green : Colors.grey;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showVoucherDialog(voucher: voucher),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: canUseColor.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: canUseColor.shade200),
                ),
                child: Icon(
                  voucher.discountType == DiscountType.percent
                      ? Icons.percent
                      : Icons.payments_outlined,
                  color: canUseColor.shade700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          voucher.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(voucher),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _voucherDescription(voucher),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _metaText('Tối thiểu', _money(voucher.minOrderAmount)),
                        if (voucher.maxDiscount != null)
                          _metaText('Tối đa', _money(voucher.maxDiscount!)),
                        _metaText(
                          'Lượt dùng',
                          voucher.usageLimit == null
                              ? '${voucher.usedCount}/Không giới hạn'
                              : '${voucher.usedCount}/${voucher.usageLimit}',
                        ),
                        _metaText(
                          'Hết hạn',
                          voucher.expiresAt == null
                              ? 'Không có'
                              : _formatDate(voucher.expiresAt!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Sửa',
                onPressed: () => _showVoucherDialog(voucher: voucher),
                icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
              ),
              IconButton(
                tooltip: 'Xóa',
                onPressed: () => _confirmDelete(voucher),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(VoucherModel voucher) {
    final label = !voucher.isActive
        ? 'Tắt'
        : voucher.isExpired
        ? 'Hết hạn'
        : voucher.isUsageLimitReached
        ? 'Hết lượt'
        : 'Đang hoạt động';
    final color = voucher.canUse ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _metaText(String label, String value) {
    return Text(
      '$label: $value',
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    );
  }

  String _voucherDescription(VoucherModel voucher) {
    if (voucher.description != null && voucher.description!.trim().isNotEmpty) {
      return voucher.description!;
    }
    if (voucher.discountType == DiscountType.percent) {
      return 'Giảm ${voucher.discountValue.toStringAsFixed(0)}%';
    }
    return 'Giảm ${_money(voucher.discountValue)}';
  }

  Future<void> _showVoucherDialog({VoucherModel? voucher}) async {
    final saved = await Get.dialog<bool>(
      _VoucherDialog(voucher: voucher),
      barrierDismissible: false,
    );
    if (saved == true) {
      await voucherController.fetchAdminVouchers();
    }
  }

  Future<void> _confirmDelete(VoucherModel voucher) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xóa voucher?'),
        content: Text(
          'Bạn có chắc muốn xóa voucher "${voucher.code}"? Voucher đã dùng trong đơn hàng sẽ được tắt hoạt động thay vì xóa cứng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await voucherController.deleteVoucher(voucher.id);
    }
  }

  String _money(double value) => '${value.toStringAsFixed(0)}đ';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _VoucherDialog extends StatefulWidget {
  final VoucherModel? voucher;

  const _VoucherDialog({this.voucher});

  @override
  State<_VoucherDialog> createState() => _VoucherDialogState();
}

class _VoucherDialogState extends State<_VoucherDialog> {
  final ControllerVoucher voucherController = Get.find<ControllerVoucher>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final TextEditingController codeController;
  late final TextEditingController descriptionController;
  late final TextEditingController discountValueController;
  late final TextEditingController minOrderController;
  late final TextEditingController maxDiscountController;
  late final TextEditingController usageLimitController;

  DiscountType discountType = DiscountType.fixed;
  bool isActive = true;
  DateTime? expiresAt;

  @override
  void initState() {
    super.initState();
    final voucher = widget.voucher;
    discountType = voucher?.discountType ?? DiscountType.fixed;
    isActive = voucher?.isActive ?? true;
    expiresAt = voucher?.expiresAt;

    codeController = TextEditingController(text: voucher?.code ?? '');
    descriptionController = TextEditingController(
      text: voucher?.description ?? '',
    );
    discountValueController = TextEditingController(
      text: voucher == null ? '' : voucher.discountValue.toStringAsFixed(0),
    );
    minOrderController = TextEditingController(
      text: voucher == null ? '0' : voucher.minOrderAmount.toStringAsFixed(0),
    );
    maxDiscountController = TextEditingController(
      text: voucher?.maxDiscount?.toStringAsFixed(0) ?? '',
    );
    usageLimitController = TextEditingController(
      text: voucher?.usageLimit?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    descriptionController.dispose();
    discountValueController.dispose();
    minOrderController.dispose();
    maxDiscountController.dispose();
    usageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.voucher != null;

    return AlertDialog(
      title: Text(isEdit ? 'Sửa voucher' : 'Thêm voucher'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã voucher',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mã voucher';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DiscountType>(
                  initialValue: discountType,
                  decoration: const InputDecoration(
                    labelText: 'Loại giảm giá',
                    prefixIcon: Icon(Icons.discount_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: DiscountType.fixed,
                      child: Text('Giảm số tiền cố định'),
                    ),
                    DropdownMenuItem(
                      value: DiscountType.percent,
                      child: Text('Giảm theo phần trăm'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => discountType = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: discountValueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: discountType == DiscountType.percent
                              ? 'Phần trăm giảm'
                              : 'Số tiền giảm',
                          prefixIcon: const Icon(Icons.payments_outlined),
                        ),
                        validator: _positiveNumberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: minOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Đơn tối thiểu',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: _nonNegativeNumberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: maxDiscountController,
                        keyboardType: TextInputType.number,
                        enabled: discountType == DiscountType.percent,
                        decoration: const InputDecoration(
                          labelText: 'Giảm tối đa',
                          prefixIcon: Icon(Icons.price_check_outlined),
                        ),
                        validator: (value) {
                          if (discountType == DiscountType.fixed ||
                              value == null ||
                              value.trim().isEmpty) {
                            return null;
                          }
                          return _positiveNumberValidator(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: usageLimitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số lượt dùng',
                          prefixIcon: Icon(Icons.repeat_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Nhập số nguyên dương';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickExpiryDate,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          expiresAt == null
                              ? 'Không giới hạn hạn dùng'
                              : 'Hết hạn: ${_formatDate(expiresAt!)}',
                        ),
                      ),
                    ),
                    if (expiresAt != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Bỏ hạn dùng',
                        onPressed: () => setState(() => expiresAt = null),
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                  title: const Text('Voucher đang hoạt động'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
        Obx(
          () => ElevatedButton(
            onPressed: voucherController.isLoading.value ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: voucherController.isLoading.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Lưu' : 'Tạo'),
          ),
        ),
      ],
    );
  }

  String? _positiveNumberValidator(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return 'Nhập số lớn hơn 0';
    }
    if (discountType == DiscountType.percent && parsed > 100) {
      return 'Phần trăm không quá 100';
    }
    return null;
  }

  String? _nonNegativeNumberValidator(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0) {
      return 'Nhập số từ 0 trở lên';
    }
    return null;
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: expiresAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    });
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    final maxDiscountText = maxDiscountController.text.trim();
    final usageLimitText = usageLimitController.text.trim();
    final data = <String, dynamic>{
      'code': codeController.text.trim().toUpperCase(),
      'description': descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      'discount_type': discountType.value,
      'discount_value': double.parse(discountValueController.text.trim()),
      'min_order_amount': double.parse(minOrderController.text.trim()),
      'max_discount':
          discountType == DiscountType.percent && maxDiscountText.isNotEmpty
          ? double.parse(maxDiscountText)
          : null,
      'usage_limit': usageLimitText.isEmpty ? null : int.parse(usageLimitText),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };

    final voucher = widget.voucher;
    final success = voucher == null
        ? await voucherController.createVoucher(data)
        : await voucherController.updateVoucher(voucher.id, data);

    if (success) {
      Get.back(result: true);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
