// lib/views/user/search_product.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/cart_controller.dart';
import 'package:xommoigarden/controller/product_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'product_detail_page.dart';

class SearchProductPage extends StatefulWidget {
  const SearchProductPage({super.key});

  @override
  State<SearchProductPage> createState() => _SearchProductPageState();
}

class _SearchProductPageState extends State<SearchProductPage> {
  final ControllerProduct productController = Get.find<ControllerProduct>();

  final TextEditingController searchCtrl = TextEditingController();
  final RxList<String> searchHistory = <String>[].obs;
  final RxList<ProductModel> searchResults = <ProductModel>[].obs;
  final RxBool isSearching = false.obs;

  bool showAllHistory = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  void _loadSearchHistory() {
    // Load từ localStorage hoặc shared_preferences
    // Tạm thời dùng list mặc định
    searchHistory.value = [
      'Bánh mì',
      'Cà phê sữa',
      'Phở bò',
      'Cơm tấm'
    ];
  }

  void _saveToHistory(String keyword) {
    if (keyword.trim().isEmpty) return;

    // Xóa nếu đã tồn tại
    searchHistory.remove(keyword);
    // Thêm vào đầu
    searchHistory.insert(0, keyword);
    // Giới hạn 10 từ khóa
    if (searchHistory.length > 10) {
      searchHistory.removeLast();
    }
    // Lưu lại (có thể lưu vào shared_preferences)
  }

  void _removeFromHistory(String keyword) {
    searchHistory.remove(keyword);
  }

  void _clearHistory() {
    searchHistory.clear();
  }

  void _search(String keyword) {
    if (keyword.trim().isEmpty) {
      isSearching.value = false;
      searchResults.clear();
      return;
    }

    isSearching.value = true;

    // Tìm kiếm trong danh sách sản phẩm
    final results = productController.products.where((product) {
      return product.name.toLowerCase().contains(keyword.toLowerCase()) ||
          (product.description?.toLowerCase().contains(keyword.toLowerCase()) ?? false);
    }).toList();

    searchResults.value = results;
  }

  List<ProductModel> get suggestions {
    // Lấy 6 sản phẩm gợi ý (có thể là sản phẩm bán chạy hoặc random)
    final allProducts = productController.products;
    if (allProducts.length <= 6) return allProducts;
    return allProducts.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (isSearching.value && searchResults.isNotEmpty) {
          return _buildSearchResult();
        }

        if (isSearching.value && searchResults.isEmpty) {
          return _buildEmptyResult();
        }

        // CHƯA GÕ → HISTORY + GỢI Ý
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHistory(),
              const Divider(height: 1),
              _buildSuggestion(),
            ],
          ),
        );
      }),
    );
  }

  // ===================== APP BAR =====================
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: const BackButton(color: Colors.black),
      titleSpacing: 0,
      title: Container(
        width: 250,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 24, color: Colors.black),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: searchCtrl,
                autofocus: true,
                onChanged: (value) {
                  _search(value);
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _saveToHistory(value);
                    _search(value);
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
              ),
            ),
            Obx(() {
              if (searchCtrl.text.isEmpty) return const SizedBox();
              return GestureDetector(
                onTap: () {
                  searchCtrl.clear();
                  _search('');
                },
                child: const Icon(Icons.close, size: 18),
              );
            }),
          ],
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            if (searchCtrl.text.isNotEmpty) {
              _saveToHistory(searchCtrl.text);
              _search(searchCtrl.text);
            }
          },
          child: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'Tìm kiếm',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== HISTORY =====================
  Widget _buildHistory() {
    if (searchHistory.isEmpty) return const SizedBox();

    final visibleItems = showAllHistory
        ? searchHistory.toList()
        : searchHistory.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text(
                'Lịch sử tìm kiếm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearHistory,
                child: const Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Danh sách lịch sử
        ...visibleItems.map(
              (e) => InkWell(
            onTap: () {
              searchCtrl.text = e;
              _saveToHistory(e);
              _search(e);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 24,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeFromHistory(e),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // XEM THÊM / THU GỌN
        if (searchHistory.length > 3)
          GestureDetector(
            onTap: () {
              setState(() {
                showAllHistory = !showAllHistory;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    showAllHistory ? 'Thu gọn' : 'Xem thêm',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    showAllHistory
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ===================== GỢI Ý =====================
  Widget _buildSuggestion() {
    final items = suggestions;
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: const [
              Text(
                'Gợi ý cho bạn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Spacer(),
              Icon(Icons.refresh, size: 18, color: Colors.grey),
              SizedBox(width: 4),
              Text('Làm mới', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),

        ...items.map(
              (product) => InkWell(
            onTap: () {
              searchCtrl.text = product.name;
              _saveToHistory(product.name);
              _search(product.name);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 8,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: product.imageUrl != null
                        ? Image.network(
                      product.imageUrl!,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 45,
                          height: 45,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, size: 24),
                        );
                      },
                    )
                        : Container(
                      width: 45,
                      height: 45,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== KẾT QUẢ TÌM KIẾM =====================
  Widget _buildSearchResult() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (_, index) {
        final product = searchResults[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _saveToHistory(product.name);
              _showProductDetail(product);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Ảnh sản phẩm
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product.imageUrl != null
                        ? Image.network(
                      product.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, size: 30),
                        );
                      },
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, size: 30),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Thông tin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              product.ratingDisplay,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${product.totalReviews})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.formattedPrice,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nút thêm vào giỏ
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                      onPressed: () {
                        final cartController = Get.find<ControllerCart>();
                        cartController.addToCart(product, 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy sản phẩm',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ProductDetailPage(
                product: product,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }
}