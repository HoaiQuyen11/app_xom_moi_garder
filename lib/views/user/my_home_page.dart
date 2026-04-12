// lib/views/user/my_home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/controller/cart_controller.dart';
import 'package:xommoigarden/controller/product_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/views/pages/login_page.dart';
import 'package:xommoigarden/views/user/search_product.dart';
import 'package:xommoigarden/views/widgets/product_quantity_control.dart';

import 'product_detail_page.dart';

import 'cart_page.dart';
import 'profile_page.dart';
import 'order_history_page.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int index = 0;
  double _opacity = 0.0;

  late ControllerAuth authController;
  late ControllerCart cartController;
  late ControllerProduct productController;


  final ScrollController _scrollController = ScrollController();

  final GlobalKey _cartIconKey = GlobalKey();
  final GlobalKey _foodKey = GlobalKey();
  final GlobalKey _drinkKey = GlobalKey();
  final GlobalKey _householdKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    productController = Get.find<ControllerProduct>();
    cartController = Get.find<ControllerCart>();
    authController = Get.find<ControllerAuth>();

    productController.animateAddToCart = _runAddToCartAnimation;

    _scrollController.addListener(() {
      if (_scrollController.offset > 25) {
        double opacityValue = _scrollController.offset / 70;
        opacityValue = opacityValue.clamp(0, 1);
        setState(() => _opacity = opacityValue);
      } else {
        setState(() => _opacity = 0);
      }
    });
  }

  Widget _buildStoreInfo() {
    final user = authController.currentUser.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  image: const DecorationImage(
                    image: AssetImage("assets/images/logoapp.png"),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Tên quán
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Xóm Mới Garden (Nha Trang)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        const Text("4.8", style: TextStyle(fontSize: 14, color: Colors.black)),
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite, color: Colors.pink, size: 16),
                        const SizedBox(width: 4),
                        const Text("1.2k", style: TextStyle(fontSize: 14, color: Colors.black)),
                        const SizedBox(width: 8),
                        const Icon(Icons.shopping_bag, color: Colors.brown, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "${cartController.totalQuantity}",
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Icon Info
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.grey),
                onPressed: () {
                  _showStoreInfoDialog();
                },
              ),
            ],
          ),
          const Divider(height: 20),
          // Row 2: Chi tiết dịch vụ
          _buildDetailRow(
            'Thời gian giao hàng',
            '06:30 ~ 21:20 (hàng ngày)',
          ),
          _buildDetailRow(
            'Đơn hàng tối thiểu',
            '0đ',
          ),
          _buildDetailRow(
            'Phương thức thanh toán',
            'Tiền mặt, Chuyển khoản',
          ),
          _buildDetailRow(
            'Phí giao hàng',
            'Miễn phí cho đơn 300k trong 10km',
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return Stack(
      children: [
        // Ảnh banner
        Container(
          height: 230,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/banner.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 180,
          color: Colors.black.withOpacity(0.15),
        ),
        Positioned(
          top: 40,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (ctx) {
                  return _buildCircleIcon(
                    icon: Icons.menu,
                    onTap: () {
                      Scaffold.of(ctx).openDrawer();
                    },
                  );
                },
              ),
              Row(
                children: [
                  _buildCircleIcon(
                    icon: Icons.call,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildCircleIcon(
                    icon: Icons.chat_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildCircleIcon(
                    icon: Icons.favorite_border,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _buildCircleIcon(
                    icon: Icons.search,
                    onTap: () {
                      Get.to(() => const SearchProductPage());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 25),
      ),
    );
  }

  Widget _buildCoverWithStoreInfo() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCover(),
        Positioned(
          left: 12,
          right: 12,
          bottom: -150,
          child: _buildStoreInfo(),
        ),
      ],
    );
  }

  Widget _buildFloatingHeader() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _opacity,
      child: Container(
        height: 90,
        padding: const EdgeInsets.only(top: 40, left: 12, right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Get.to(() => const SearchProductPage());
                },
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Text("Tìm kiếm sản phẩm"),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.idle &&
                  _opacity > 0.1 &&
                  _scrollController.offset < 80) {
                _scrollController.animateTo(
                  80,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildCoverWithStoreInfo(),
                  const SizedBox(height: 150),
                  _buildFeaturedSection(),
                  _buildCategoryTabBar(),
                  _buildProductSections(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          if (_opacity > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFloatingHeader(),
            ),
        ],
      ),
      bottomNavigationBar: _buildFloatingCartBar(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.green.shade200,
          child: Obx(() {
            final isLoggedIn = authController.currentUser.value != null;
          return ListView(
          children: [
            Obx(() => UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade800, Colors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(
                authController.isLoggedIn
                    ? "Xin chào ${authController.currentUser.value?.fullName ?? 'bạn'} 👋"
                    : "Xin chào 👋",
              ),
              accountEmail: Text(
                authController.isLoggedIn
                    ? authController.currentUser.value?.email ?? "Chưa có email"
                    : "Vui lòng đăng nhập",
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, color: Colors.green, size: 40),
              ),
            )),
            if (authController.isLoggedIn)
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text("Hồ sơ"),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => ProfilePage());
                },
              ),
            if (authController.isLoggedIn)
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Đơn hàng của tôi"),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => OrderHistoryPage());
                },
              ),
            if (authController.isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Đăng xuất"),
                onTap: () async {
                  await authController.logout();
                  Navigator.pop(context);
                },
              ),
            if (!authController.isLoggedIn)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text("Đăng nhập"),
                onTap: () {
                  Navigator.pop(context);
                  Get.to(() => const LoginPage());
                },
              ),
            const Divider(),
          ],
        );
          }),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Obx(() {
      final featuredProducts = productController.products
          .where((p) => p.isAvailable)
          .take(5)
          .toList();

      if (featuredProducts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Nhất định phải thử",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredProducts.length,
                itemBuilder: (_, i) =>
                    _buildProductHorizontalItem(featuredProducts[i]),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryTabBar() {
    return Obx(() {
      final categories = productController.categories;
      if (categories.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          children: [
            for (var category in categories)
              _buildScrollChip(category.name, _getCategoryKey(category.name)),
          ],
        ),
      );
    });
  }

  GlobalKey _getCategoryKey(String categoryName) {
    if (categoryName.contains('Bánh căn') || categoryName.contains('Món ăn')) {
      return _foodKey;
    } else if (categoryName.contains('Bánh xèo')) {
      return _drinkKey;
    } else if (categoryName.contains('Nước giải khát')) {
      return _householdKey;
    }
    return GlobalKey();
  }

  Widget _buildProductSections() {
    return Obx(() {
      final allProducts = productController.products;

      // Phân loại sản phẩm theo category
      final foodProducts = allProducts.where((p) =>
      p.categoryId != null &&
          productController.categories.firstWhereOrNull((c) => c.id == p.categoryId)?.name.contains('Bánh căn') == true
      ).toList();

      final drinkProducts = allProducts.where((p) =>
      p.categoryId != null &&
          productController.categories.firstWhereOrNull((c) => c.id == p.categoryId)?.name.contains('Bánh xèo') == true
      ).toList();

      final householdProducts = allProducts.where((p) =>
      p.categoryId != null &&
          productController.categories.firstWhereOrNull((c) => c.id == p.categoryId)?.name.contains('Nước giải khát') == true
      ).toList();

      return Column(
        children: [
          if (foodProducts.isNotEmpty)
            _buildSection('Bánh căn', _foodKey, foodProducts),
          if (drinkProducts.isNotEmpty)
            _buildSection('Bánh xèo', _drinkKey, drinkProducts),
          if (householdProducts.isNotEmpty)
            _buildSection('Nước giải khát', _householdKey, householdProducts),
        ],
      );
    });
  }

  Widget _buildSection(
      String title,
      GlobalKey key,
      List<ProductModel> products,
      ) {
    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: buildSectionHeader(
            key: key,
            title: title,
            subtitle: 'Hình ảnh sản phẩm hiển thị có thể khác với thực tế.\n'
                'Thời gian mở bán từ 10:00 ~ 21:30',
          ),
        ),
        ...products.map(_buildProductGridItem),
      ],
    );
  }

  Widget buildSectionHeader({
    required String title,
    String? subtitle,
    GlobalKey? key,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      color: Colors.black.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScrollChip(String label, GlobalKey key) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: () {
          final context = key.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  // Widget Item Sản phẩm cho ListView ngang (Nhất định phải thử)
  Widget _buildProductHorizontalItem(ProductModel product) {
    final gia = product.price;
    final itemInCart = cartController.cartItems
        .firstWhereOrNull((e) => e.productId == product.id);

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showProductDetail(product);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: product.imageUrl != null
                          ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood, size: 40),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood, size: 40),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: ProductQuantityControl(
                        product: product,
                        isHorizontal: true,
                        addBtnKey: GlobalKey(), // Tạo key riêng cho từng sản phẩm
                      )
                    ),
                  ],
                ),
              ),
            ),
            // Tên + giá
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${gia.toStringAsFixed(0)} đ",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Item Sản phẩm cho GridView dọc
  Widget _buildProductGridItem(ProductModel product) {
    final gia = product.price;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 7, bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () {
          _showProductDetail(product);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ẢNH
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: product.imageUrl != null
                  ? Image.network(
                product.imageUrl!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, size: 40),
                  );
                },
              )
                  : Container(
                width: 120,
                height: 120,
                color: Colors.grey.shade200,
                child: const Icon(Icons.fastfood, size: 40),
              ),
            ),
            const SizedBox(width: 15),
            // THÔNG TIN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // GIÁ + NÚT
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "${gia.toStringAsFixed(0)} đ",
                          style: const TextStyle(
                            color: Color(0xFF3A5A00),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      ProductQuantityControl(
                        product: product,
                        isHorizontal: true,
                        addBtnKey: GlobalKey(), // Tạo key riêng cho từng sản phẩm
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // FAVORITE
                  Row(
                    children: const [
                      Icon(Icons.favorite_border, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        "0",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  void _runAddToCartAnimation(ProductModel product, GlobalKey fromKey) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final fromBox = fromKey.currentContext?.findRenderObject() as RenderBox?;
    final toBox = _cartIconKey.currentContext?.findRenderObject() as RenderBox?;

    if (fromBox == null || toBox == null) return;

    final fromPos = fromBox.localToGlobal(Offset.zero);
    final toPos = toBox.localToGlobal(Offset.zero);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) {
        return TweenAnimationBuilder<Offset>(
          tween: Tween(begin: fromPos, end: toPos),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          builder: (_, value, child) {
            return Positioned(
              left: value.dx,
              top: value.dy,
              child: child!,
            );
          },
          onEnd: () => entry.remove(),
          child: Material(
            color: Colors.transparent,
            child: ClipOval(
              child: product.imageUrl != null
                  ? Image.network(
                product.imageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 40,
                height: 40,
                color: Colors.green,
                child: const Icon(Icons.fastfood, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
  }

  Widget _buildFloatingCartBar() {
    return Obx(() {
      if (cartController.totalQuantity == 0) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Icon giỏ + badge
                Stack(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      key: _cartIconKey,
                      color: Colors.white,
                      size: 26,
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cartController.totalQuantity}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Tổng tiền
                Text(
                  cartController.formattedTotal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Nút Thanh toán
                InkWell(
                  onTap: () async {
                    if (!authController.isLoggedIn) {
                      Get.to(() => LoginPage());
                      return;
                    }
                    Get.to(() => CartPage());
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Thanh toán",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(color: Colors.white24, height: 10),
            // DÒNG DƯỚI
            const Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: Colors.white70, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Miễn phí vận chuyển cho đơn hàng 300k, trong phạm vi 10km",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _showStoreInfoDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Thông tin cửa hàng'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Địa chỉ: 123 Nguyễn Thị Minh Khai, Nha Trang'),
            SizedBox(height: 8),
            Text('📞 Hotline: 1900 1234'),
            SizedBox(height: 8),
            Text('⏰ Giờ mở cửa: 06:30 - 21:30'),
            SizedBox(height: 8),
            Text('🚚 Phí ship: 15.000đ / đơn'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

