// lib/views/user/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/cart_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/model/product_option_model.dart';
import 'package:xommoigarden/views/user/product_reviews_page.dart';

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

  List<ProductOption> productOptions = [];
  // optionId → selected OptionValue
  Map<String, OptionValue?> selectedValues = {};

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final supabase = Supabase.instance.client;
    try {
      final res = await supabase
          .from('product_options')
          .select()
          .eq('product_id', widget.product.id)
          .order('created_at');

      productOptions = res
          .map<ProductOption>((m) => ProductOption.fromJson(m))
          .toList();

      for (var opt in productOptions) {
        if (opt.values.isNotEmpty) {
          selectedValues[opt.id] = opt.values.first;
        }
      }

      setState(() {});
    } catch (e) {
      print('Error loading options: $e');
    }
  }

  double _calcTotal() {
    double extra = 0;
    for (var val in selectedValues.values) {
      if (val != null) extra += val.price;
    }
    return (widget.product.price + extra) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh sản phẩm
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.fastfood,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
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

                  // Tên sản phẩm
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rating + reviews
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          Get.to(() => ProductReviewsPage(product: product)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.ratingDisplay,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 20),
                            const Icon(
                              Icons.rate_review_outlined,
                              color: Colors.blueGrey,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product.totalReviews}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade500,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mô tả
                  if (product.description != null &&
                      product.description!.isNotEmpty)
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

                  // Options (product_options JSONB)
                  if (productOptions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: productOptions.map((opt) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Text(
                                '${opt.name}${opt.isRequired ? ' *' : ''}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...opt.values.map((val) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: RadioListTile<String>(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    value: val.label,
                                    groupValue: selectedValues[opt.id]?.label,
                                    title: Text(
                                      val.label,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    secondary: Text(
                                      val.formattedPrice,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onChanged: (_) => setState(
                                      () => selectedValues[opt.id] = val,
                                    ),
                                    activeColor: Colors.green,
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),

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
              // Số lượng
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
                        if (quantity > 1) setState(() => quantity--);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => setState(() => quantity++),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
              ),

              // Nút thêm giỏ
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
                      // Gom options đã chọn thành JSONB format
                      final List<Map<String, dynamic>> selectedOptions = [];
                      for (var opt in productOptions) {
                        final val = selectedValues[opt.id];
                        if (val != null) {
                          selectedOptions.add({
                            'name': opt.name,
                            'value': val.label,
                            'price': val.price,
                          });
                        }
                      }

                      await cartController.addToCart(
                        widget.product,
                        quantity,
                        selectedOptions: selectedOptions,
                      );

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
                          'Thêm vào giỏ • ${_calcTotal().toStringAsFixed(0)}đ',
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
