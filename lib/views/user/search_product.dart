// lib/views/user/search_product.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
  final ControllerCart cartController = Get.find<ControllerCart>();
  final box = GetStorage();

  final TextEditingController searchCtrl = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  List<String> searchHistory = [];
  List<ProductModel> searchResults = [];
  bool isSearching = false;
  bool showAllHistory = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  // ==================== LOGIC ====================

  void _loadSearchHistory() {
    final saved = box.read<List>('search_history');
    if (saved != null) {
      searchHistory = saved.cast<String>();
    }
  }

  void _saveHistory() {
    box.write('search_history', searchHistory);
  }

  void _addToHistory(String keyword) {
    if (keyword.trim().isEmpty) return;
    searchHistory.remove(keyword);
    searchHistory.insert(0, keyword);
    if (searchHistory.length > 15) searchHistory.removeLast();
    _saveHistory();
    setState(() {});
  }

  void _removeFromHistory(String keyword) {
    searchHistory.remove(keyword);
    _saveHistory();
    setState(() {});
  }

  void _clearHistory() {
    searchHistory.clear();
    _saveHistory();
    setState(() {});
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        isSearching = false;
        searchResults.clear();
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value);
    });
  }

  void _performSearch(String keyword) {
    final query = keyword.toLowerCase();
    final results = productController.products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    setState(() {
      isSearching = true;
      searchResults = results;
    });
  }

  void _submitSearch(String keyword) {
    if (keyword.trim().isEmpty) return;
    _addToHistory(keyword);
    _performSearch(keyword);
    searchFocus.unfocus();
  }

  void _tapHistoryItem(String keyword) {
    searchCtrl.text = keyword;
    searchCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _submitSearch(keyword);
  }

  // Top 4 sản phẩm được mua nhiều nhất (theo totalReviews)
  List<ProductModel> get topProducts {
    final sorted = productController.products.toList()
      ..sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
    return sorted.take(4).toList();
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: isSearching ? _buildSearchContent() : _buildDefaultContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: const BackButton(color: Colors.black),
      titleSpacing: 0,
      title: Container(
        height: 42,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
        ),
        child: TextField(
          controller: searchCtrl,
          focusNode: searchFocus,
          autofocus: true,
          onChanged: _onSearchChanged,
          onSubmitted: _submitSearch,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 22),
            suffixIcon: searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      searchCtrl.clear();
                      _onSearchChanged('');
                      searchFocus.requestFocus();
                    },
                    child: Icon(Icons.close, size: 20, color: Colors.grey.shade500),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _submitSearch(searchCtrl.text),
          child: Text(
            'Tìm',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== DEFAULT (CHƯA TÌM) ====================

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchHistory.isNotEmpty) _buildHistorySection(),
          _buildSuggestionGrid(),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    final visible = showAllHistory ? searchHistory : searchHistory.take(5).toList();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Row(
              children: [
                const Text(
                  'Lịch sử tìm kiếm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearHistory,
                  child: Text('Xóa tất cả', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ),
              ],
            ),
          ),
          ...visible.map((keyword) => _buildHistoryItem(keyword)),
          if (searchHistory.length > 5)
            InkWell(
              onTap: () => setState(() => showAllHistory = !showAllHistory),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      showAllHistory ? 'Thu gọn' : 'Xem thêm (${searchHistory.length - 5})',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                    Icon(
                      showAllHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String keyword) {
    return InkWell(
      onTap: () => _tapHistoryItem(keyword),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(Icons.history, size: 20, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(keyword, style: const TextStyle(fontSize: 15)),
            ),
            GestureDetector(
              onTap: () => _removeFromHistory(keyword),
              child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== GỢI Ý (GRID 2x2) ====================

  Widget _buildSuggestionGrid() {
    final items = topProducts;
    if (items.isEmpty) return const SizedBox();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý tìm kiếm',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildSuggestionCard(items[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        _addToHistory(product.name);
        _showProductDetail(product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh chiếm phần lớn
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade100,
                          child: Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey.shade300)),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Center(child: Icon(Icons.fastfood, size: 40, color: Colors.grey.shade300)),
                      ),
              ),
            ),
            // Tên sản phẩm
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== KẾT QUẢ TÌM KIẾM ====================

  Widget _buildSearchContent() {
    return Column(
      children: [
        // Số kết quả
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Text(
            'Tìm thấy ${searchResults.length} sản phẩm',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),

        // Danh sách kết quả
        Expanded(
          child: searchResults.isEmpty
              ? _buildEmptyResult()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: searchResults.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _buildResultCard(searchResults[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildResultCard(ProductModel product) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _addToHistory(product.name);
          _showProductDetail(product);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ảnh
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.totalReviews > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            '${product.ratingDisplay} (${product.totalReviews})',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      product.formattedPrice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Add to cart
              GestureDetector(
                onTap: () => cartController.addToCart(product, 1),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.add_shopping_cart, size: 22, color: Colors.green.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyResult() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy sản phẩm',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            'Thử tìm với từ khóa khác',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.fastfood, size: 30, color: Colors.grey.shade400),
    );
  }

  void _showProductDetail(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
