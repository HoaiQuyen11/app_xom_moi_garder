import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/ai_food_assistant_controller.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/product_model.dart';
import 'package:xommoigarden/views/user/product_detail_page.dart';
import 'package:xommoigarden/views/widgets/product_quantity_control.dart';

class AiFoodAssistantPage extends StatefulWidget {
  const AiFoodAssistantPage({super.key});

  @override
  State<AiFoodAssistantPage> createState() => _AiFoodAssistantPageState();
}

class _AiFoodAssistantPageState extends State<AiFoodAssistantPage> {
  final AiFoodAssistantController controller =
      Get.find<AiFoodAssistantController>();
  final ControllerAuth authController = Get.find<ControllerAuth>();
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<String> suggestedQuestions = const [
    'Tôi muốn hối giao đơn hàng?',
    'Cửa hàng mở và đóng vào thời gian nào?',
    'Có món ăn chay không?',
  ];

  @override
  void initState() {
    super.initState();
    controller.refreshMenuContext();
  }

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: _buildHeader(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessages()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.deepOrange,
      elevation: 0.5,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back, size: 30),
      ),
      title: Row(
        children: [
          const SizedBox(width: 10),
          const Text(
            'Xóm Mới Garden',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Tải lại dữ liệu',
          onPressed: controller.refreshMenuContext,
          icon: const Icon(Icons.refresh, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildIntroArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNoticeBanner(),
        const SizedBox(height: 12),
        _buildGreetingBubble(_customerName),
        const SizedBox(height: 12),
        _buildQuestionCard(),
        const SizedBox(height: 10),
      ],
    );
  }

  String get _customerName {
    final user = authController.currentUser.value;
    final fullName = user?.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return 'bạn';
  }

  Widget _buildNoticeBanner() {
    return Obx(() {
      final count = controller.availableProducts.length;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 22,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count == 0
                    ? 'Nha Trang nắng nóng, đang tải dữ liệu'
                    : 'Xóm Mới Garden sẵn sàng hỗ trợ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGreetingBubble(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Chào khách iu $userName, hôm nay bạn cần Xóm Mới Garden hỗ trợ về điều gì, hãy hỏi ngay để được giải đáp nhanh chóng nhất nha',
        style: const TextStyle(
          fontSize: 21,
          color: Colors.black87,
          height: 1.28,
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Text(
              'Bạn muốn hỏi về:',
              style: TextStyle(fontSize: 20, color: Colors.black87),
            ),
          ),
          for (final question in suggestedQuestions)
            InkWell(
              onTap: () => _send(question),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        question,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF3D8BFF),
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Obx(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        itemCount:
            1 +
            controller.messages.length +
            (controller.isLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) return _buildIntroArea();

          final messageIndex = index - 1;
          if (messageIndex >= controller.messages.length) {
            return _buildTypingBubble();
          }

          final message = controller.messages[messageIndex];
          return _buildMessageBubble(message);
        },
      );
    });
  }

  Widget _buildMessageBubble(AiFoodMessage message) {
    final isUser = message.role == AiFoodMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: isUser ? null : double.infinity,
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? Colors.green.shade700 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isUser ? null : Border.all(color: Colors.grey.shade200),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  height: 1.35,
                ),
              ),
            ),
            if (message.recommendations.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...message.recommendations.map(_buildRecommendationCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(AiFoodRecommendation recommendation) {
    final product = recommendation.product.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showProductDetail(product),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl == null
                  ? Container(
                      width: 74,
                      height: 74,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    )
                  : Image.network(
                      product.imageUrl!,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 74,
                          height: 74,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _showProductDetail(product),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)}đ',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ProductQuantityControl(product: product, addBtnKey: GlobalKey()),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 10),
            const Text('AI đang xử lý...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inputController,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: 'Nhập yêu cầu của bạn tại đây nhé',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.deepOrange.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                return IconButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => _send(inputController.text),
                  icon: const Icon(Icons.send, size: 30),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.deepOrange.shade300,
                    disabledForegroundColor: Colors.grey.shade300,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Được tạo bởi AI, áp dụng điều khoản dịch vụ.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    inputController.clear();
    controller.ask(trimmed);
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
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
          builder: (context, sheetScrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ProductDetailPage(
                product: product,
                scrollController: sheetScrollController,
              ),
            );
          },
        );
      },
    );
  }
}
