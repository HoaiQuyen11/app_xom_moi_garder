// lib/views/user/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:xommoigarden/controller/cart_controller.dart';
import 'package:xommoigarden/model/option_group_model.dart';
import 'package:xommoigarden/model/option_item_model.dart';
import 'package:xommoigarden/model/product_model.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;
  final ScrollController? scrollController;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.scrollController,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ControllerCart cartController = Get.find<ControllerCart>();

  int quantity = 1;

  // ====== OPTION DATA ======
  List<OptionGroup> listGroup = [];
  Map<String, List<OptionItem>> listItemTheoGroup = {};
  Map<String, OptionItem?> selectedSingle = {}; // single
  Map<String, Set<OptionItem>> selectedMulti = {}; // multi

  @override
  void initState() {
    super.initState();
    loadOptions();
  }

  String getOptionText() {
    List<String> result = [];

    // single
    selectedSingle.forEach((gid, op) {
      if (op != null) result.add(op.name);
    });

    // multi
    selectedMulti.forEach((gid, ops) {
      for (var op in ops) {
        result.add(op.name);
      }
    });

    return result.join(", ");
  }

  Future<void> loadOptions() async {
    final supabase = Supabase.instance.client;

    try {
      // lấy group
      final resGroup = await supabase
          .from("option_groups")
          .select()
          .eq("product_id", widget.product.id);

      listGroup = resGroup.map<OptionGroup>((m) => OptionGroup.fromJson(m)).toList();

      // lấy item theo group
      for (var g in listGroup) {
        final resItem = await supabase
            .from("option_items")
            .select()
            .eq("group_id", g.id);

        final items = resItem.map<OptionItem>((m) => OptionItem.fromJson(m)).toList();

        listItemTheoGroup[g.id] = items;

        if (g.selectionType == "single") {
          // chọn mặc định
          final macDinh = items.firstWhere(
                (e) => e.isDefault == true,
            orElse: () => items.first,
          );
          selectedSingle[g.id] = macDinh;
        } else {
          selectedMulti[g.id] = {};
        }
      }

      setState(() {});
    } catch (e) {
      print('Error loading options: $e');
    }
  }

  double tinhGiaSauCung() {
    final double giaGoc = widget.product.price;
    double giaOption = 0;

    // single
    for (var op in selectedSingle.values) {
      if (op != null) giaOption += op.priceAdjustment;
    }

    // multi
    for (var setOp in selectedMulti.values) {
      for (var op in setOp) {
        giaOption += op.priceAdjustment;
      }
    }

    return giaGoc + giaOption;
  }

  double tinhTongTien() {
    return tinhGiaSauCung() * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          // Thanh kéo (drag handle)
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: false,
            floating: false,
            snap: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 40,
            flexibleSpace: SafeArea(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),

          // ================= NỘI DUNG =================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh sản phẩm (1 ảnh duy nhất)
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: product.imageUrl != null
                        ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.fastfood,
                            size: 80,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.fastfood,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // ================= TÊN SẢN PHẨM =================
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ================= ICON ⭐ ❤️ 🛍 =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              product.ratingDisplay,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.pink, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              "${product.totalReviews}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag, color: Colors.green, size: 18),
                            const SizedBox(width: 4),
                            const Text(
                              "0",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= MÔ TẢ =================
                  if (product.description != null && product.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mô tả sản phẩm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ================= OPTIONS =================
                  if (listGroup.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...listGroup.map((group) {
                            final items = listItemTheoGroup[group.id] ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  "${group.name} (${group.selectionType == "single" ? "Một lựa chọn" : "Nhiều lựa chọn"})",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // SINGLE OPTION
                                if (group.selectionType == "single")
                                  ...items.map((op) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: RadioListTile<String>(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                        value: op.id,
                                        groupValue: selectedSingle[group.id]?.id,
                                        title: Text(
                                          op.name,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        secondary: Text(
                                          op.priceAdjustment > 0
                                              ? "+${op.priceAdjustment.toStringAsFixed(0)}đ"
                                              : op.priceAdjustment == 0
                                              ? "Miễn phí"
                                              : "${op.priceAdjustment.toStringAsFixed(0)}đ",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onChanged: (_) {
                                          setState(() {
                                            selectedSingle[group.id!] = op;
                                          });
                                        },
                                        activeColor: Colors.green,
                                      ),
                                    );
                                  }),

                                // MULTI OPTION
                                if (group.selectionType == "multi")
                                  ...items.map((op) {
                                    bool checked = selectedMulti[group.id]!.contains(op);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: CheckboxListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                        value: checked,
                                        title: Text(
                                          op.name,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        secondary: Text(
                                          op.priceAdjustment > 0
                                              ? "+${op.priceAdjustment.toStringAsFixed(0)}đ"
                                              : op.priceAdjustment == 0
                                              ? "Miễn phí"
                                              : "${op.priceAdjustment.toStringAsFixed(0)}đ",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              selectedMulti[group.id]!.add(op);
                                            } else {
                                              selectedMulti[group.id]!.remove(op);
                                            }
                                          });
                                        },
                                        activeColor: Colors.green,
                                        checkColor: Colors.white,
                                      ),
                                    );
                                  }),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

      // ================= BOTTOM BAR =================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Điều chỉnh số lượng
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () {
                        setState(() {
                          if (quantity > 1) quantity--;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    Container(
                      width: 40,
                      child: Text(
                        "$quantity",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        setState(() {
                          quantity++;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
              ),

              // Nút Thêm vào giỏ
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      // Gom tất cả option đã chọn
                      final List<OptionItem> selectedOptions = [];
                      for (var op in selectedSingle.values) {
                        if (op != null) selectedOptions.add(op);
                      }
                      for (var setOp in selectedMulti.values) {
                        selectedOptions.addAll(setOp);
                      }

                      // Thêm vào giỏ hàng
                      await cartController.addToCart(
                        widget.product,
                        quantity,
                        selectedOptions: selectedOptions,
                      );

                      // Quay lại trang trước
                      if (widget.scrollController != null) {
                        Navigator.pop(context);
                      } else {
                        Get.back();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_shopping_cart, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Thêm vào giỏ • ${tinhTongTien().toStringAsFixed(0)}đ",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}