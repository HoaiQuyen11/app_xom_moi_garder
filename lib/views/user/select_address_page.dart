// lib/views/user/select_address_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/address_controller.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/address_model.dart';
import 'add_address_page.dart';

class SelectAddressPage extends StatefulWidget {
  final AddressModel? currentSelected;

  const SelectAddressPage({super.key, this.currentSelected});

  @override
  State<SelectAddressPage> createState() => _SelectAddressPageState();
}

class _SelectAddressPageState extends State<SelectAddressPage> {
  final ControllerAddress addressController = Get.find();
  final ControllerAuth authController = Get.find();
  final TextEditingController searchCtrl = TextEditingController();

  AddressModel? selected;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selected = widget.currentSelected;
    addressController.fetchAddresses();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chọn địa chỉ nhận hàng',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.red.shade600),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Địa chỉ',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
          ),

          // Address list
          Expanded(
            child: Obx(() {
              if (addressController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var filtered = addressController.addresses.toList();
              if (searchQuery.isNotEmpty) {
                final query = searchQuery.toLowerCase();
                filtered = filtered.where((a) => a.fullAddress.toLowerCase().contains(query)).toList();
              }

              if (filtered.isEmpty) {
                return _buildEmpty();
              }

              return ListView.separated(
                padding: const EdgeInsets.only(top: 8),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) => _buildAddressItem(filtered[index]),
              );
            }),
          ),

          // Add new button
          SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade600),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  await Get.to(() => const AddAddressPage());
                  addressController.fetchAddresses();
                },
                icon: Icon(Icons.add, color: Colors.red.shade600),
                label: Text(
                  'Thêm Địa Chỉ Mới',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem(AddressModel address) {
    final user = authController.currentUser.value;
    final isSelected = selected?.id == address.id;

    return InkWell(
      onTap: () async {
        setState(() => selected = address);
        await addressController.setDefaultAddress(address.id);
        if (mounted) Get.back(result: address);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.red.shade600 : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade600,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + phone
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(
                          text: user?.fullName ?? 'Khách hàng',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: '  |  (${user?.phone ?? '---'})',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Full address
                  Text(
                    address.fullAddress,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Get.snackbar('Sắp ra mắt', 'Chức năng sửa địa chỉ');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Sửa',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmDelete(address),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Xóa',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AddressModel address) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Xóa địa chỉ'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa địa chỉ này?\n\n${address.fullAddress}',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final ok = await addressController.deleteAddress(address.id);
              if (ok && selected?.id == address.id) {
                setState(() => selected = null);
              }
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            searchQuery.isNotEmpty ? 'Không tìm thấy địa chỉ' : 'Chưa có địa chỉ nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Thêm địa chỉ để bắt đầu đặt hàng',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
