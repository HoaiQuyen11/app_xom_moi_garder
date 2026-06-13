import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/voucher_controller.dart';
import 'package:xommoigarden/model/voucher_model.dart';

class VoucherPage extends StatefulWidget {
  final double subtotal;

  const VoucherPage({super.key, required this.subtotal});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  final ControllerVoucher voucherController = Get.find<ControllerVoucher>();
  final TextEditingController codeController = TextEditingController();
  VoucherModel? selectedVoucher;

  @override
  void initState() {
    super.initState();
    selectedVoucher = voucherController.appliedVoucher.value?.voucher;
    voucherController.fetchAvailableVouchers();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> _applyCode() async {
    final success = await voucherController.applyVoucherCode(
      codeController.text,
      widget.subtotal,
    );
    if (success) {
      setState(() {
        selectedVoucher = voucherController.appliedVoucher.value?.voucher;
      });
    }
  }

  Future<void> _applySelectedVoucher(VoucherModel voucher) async {
    final success = await voucherController.applyVoucher(
      voucher,
      widget.subtotal,
    );
    if (success) {
      Get.back(result: voucher);
      if (DateTime.now().microsecondsSinceEpoch >= 0) return;
      Get.snackbar(
        'Thành công',
        'Đã áp dụng mã ${voucher.code}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back();
    }
  }

  void _selectVoucher(VoucherModel voucher) {
    setState(() => selectedVoucher = voucher);
  }

  Future<void> _confirmSelection() async {
    if (selectedVoucher == null) {
      Get.back();
      return;
    }

    await _applySelectedVoucher(selectedVoucher!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Voucher',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildCodeInput(),
          Expanded(
            child: Obx(() {
              if (voucherController.isLoading.value &&
                  voucherController.availableVouchers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final vouchers = _buildVoucherList();
              if (vouchers.isEmpty) {
                return _buildEmptyState();
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Mã có thể chọn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...vouchers.map(_buildVoucherCard),
                ],
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _confirmSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đồng ý',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Nhập mã voucher',
                prefixIcon: Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.green.shade700,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => ElevatedButton(
              onPressed: voucherController.isApplying.value ? null : _applyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(86, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: voucherController.isApplying.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher) {
    final isSelected = selectedVoucher?.id == voucher.id;
    final validationMessage = voucherController.validateVoucher(
      voucher,
      widget.subtotal,
    );
    final canUse = validationMessage == null;
    final discount = canUse
        ? voucherController.calculateDiscount(voucher, widget.subtotal)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey.shade200,
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: canUse ? () => _selectVoucher(voucher) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: canUse ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer_outlined,
                  color: canUse ? Colors.green.shade700 : Colors.grey,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.code,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: canUse ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _voucherTitle(voucher),
                      style: TextStyle(
                        fontSize: 13,
                        color: canUse ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canUse
                          ? 'Giảm ${discount.toStringAsFixed(0)}đ cho đơn này'
                          : validationMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: canUse
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.green : Colors.grey.shade400,
              ),
            ],
          ),
        ),
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
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có voucher khả dụng',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  List<VoucherModel> _buildVoucherList() {
    final byId = <String, VoucherModel>{};

    for (final voucher in voucherController.availableVouchers) {
      byId.putIfAbsent(voucher.id, () => voucher);
    }

    return byId.values.toList();
  }

  String _voucherTitle(VoucherModel voucher) {
    if (voucher.description != null && voucher.description!.isNotEmpty) {
      return voucher.description!;
    }

    if (voucher.discountType == DiscountType.percent) {
      final maxDiscount = voucher.maxDiscount == null
          ? ''
          : ', tối đa ${voucher.maxDiscount!.toStringAsFixed(0)}đ';
      return 'Giảm ${voucher.discountValue.toStringAsFixed(0)}%$maxDiscount';
    }

    return 'Giảm ${voucher.discountValue.toStringAsFixed(0)}đ';
  }
}
