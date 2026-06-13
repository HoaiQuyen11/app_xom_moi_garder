import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xommoigarden/controller/auth_controller.dart';
import 'package:xommoigarden/model/product_model.dart';

class AiFoodAssistantController extends GetxController {
  final supabase = Supabase.instance.client;
  final ControllerAuth authController = Get.find<ControllerAuth>();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  final messages = <AiFoodMessage>[].obs;
  final isLoading = false.obs;
  final availableProducts = <AiFoodProduct>[].obs;
  final recentOrders = <AiOrderContext>[].obs;
  final lastRecommendations = <AiFoodRecommendation>[].obs;

  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  Future<void> refreshMenuContext() async {
    try {
      final response = await supabase
          .from('products')
          .select('*, categories(name)')
          .eq('is_available', true)
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      final products = (response as List).map((raw) {
        final json = Map<String, dynamic>.from(raw as Map);
        final category = json['categories'] as Map<String, dynamic>?;
        return AiFoodProduct(
          product: ProductModel.fromJson(json),
          categoryName: category?['name']?.toString() ?? 'Chưa phân loại',
        );
      }).toList();

      final optionsResponse = await supabase
          .from('product_options')
          .select('product_id, name, values');
      final optionMap = <String, List<String>>{};

      for (final raw in optionsResponse as List) {
        final option = Map<String, dynamic>.from(raw as Map);
        final productId = option['product_id']?.toString();
        if (productId == null) continue;

        final optionName = option['name']?.toString() ?? 'Tùy chọn';
        final values = option['values'] as List? ?? [];
        final valueText = values
            .map((item) {
              if (item is! Map) return null;
              final value = Map<String, dynamic>.from(item);
              final label = value['label']?.toString();
              final price = (value['price'] as num?)?.toDouble() ?? 0;
              if (label == null || label.isEmpty) return null;
              if (price == 0) return label;
              return '$label +${price.toStringAsFixed(0)}đ';
            })
            .whereType<String>()
            .join(', ');

        optionMap.putIfAbsent(productId, () => []);
        optionMap[productId]!.add('$optionName: $valueText');
      }

      availableProducts.value = products
          .map(
            (item) => item.copyWith(options: optionMap[item.product.id] ?? []),
          )
          .toList();

      await _refreshOrderContext();
    } catch (e) {
      debugPrint('Error loading AI menu context: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải dữ liệu món ăn cho trợ lý AI',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _refreshOrderContext() async {
    recentOrders.clear();
    if (!authController.isLoggedIn) return;

    final userId = authController.currentUser.value!.id;
    final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(5);

    recentOrders.value = (response as List).map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      return AiOrderContext.fromJson(json);
    }).toList();
  }

  Future<void> ask(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || isLoading.value) return;

    messages.add(AiFoodMessage(role: AiFoodMessageRole.user, text: trimmed));
    isLoading.value = true;

    try {
      if (availableProducts.isEmpty) {
        await refreshMenuContext();
      }

      if (availableProducts.isEmpty && recentOrders.isEmpty) {
        _addAssistantMessage(
          'Hiện mình chưa tải được thực đơn hoặc đơn hàng để hỗ trợ. Bạn thử tải lại sau nhé.',
        );
        return;
      }

      if (!hasApiKey) {
        if (_isOrderQuestion(trimmed)) {
          _addAssistantMessage(_buildLocalOrderAnswer(trimmed));
          return;
        }

        final fallback = _buildLocalSuggestion(trimmed);
        _addAssistantMessage(
          'Chưa cấu hình GEMINI_API_KEY nên mình đang gợi ý tạm theo dữ liệu món ăn trong Supabase. Để bật AI thật, chạy app với --dart-define=GEMINI_API_KEY=khóa_api_của_bạn.',
          recommendations: fallback,
        );
        return;
      }

      final response = await _callGemini(trimmed);
      _addAssistantMessage(
        response.answer,
        recommendations: response.recommendations,
      );
    } catch (e) {
      debugPrint('Error asking AI food assistant: $e');
      final fallback = _buildLocalSuggestion(trimmed);
      _addAssistantMessage(
        'Mình chưa gọi được AI lúc này, nên gợi ý nhanh theo thực đơn hiện có trước nhé.',
        recommendations: fallback,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<_AiResponse> _callGemini(String question) async {
    final menuText = availableProducts
        .take(80)
        .map((item) => item.promptLine)
        .join('\n');
    final orderText = recentOrders.isEmpty
        ? 'Không có đơn hàng gần đây hoặc khách chưa đăng nhập.'
        : recentOrders.map((item) => item.promptLine).join('\n');
    final recentChat = messages
        .take(8)
        .map((item) => '${item.role.name}: ${item.text}')
        .join('\n');

    final request = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Bạn là trợ lý AI của Xóm Mới Garden tại Nha Trang. Shop mở cửa 06:30 và đóng cửa 21:20 hằng ngày. Bạn có 2 nhiệm vụ: tư vấn món ăn và trả lời trạng thái đơn hàng. Chỉ gợi ý món có trong danh sách thực đơn được cung cấp. Khi khách hỏi về đơn hàng, chỉ dùng dữ liệu đơn hàng gần đây được cung cấp, không bịa trạng thái, không bịa mã đơn. Nếu không có đơn phù hợp, hãy nói khách mở lịch sử đơn hàng để kiểm tra thêm. Trả lời bằng tiếng Việt, thân thiện, ngắn gọn.\n\nLịch sử chat gần đây:\n$recentChat\n\nThực đơn đang bán từ Supabase:\n$menuText\n\nĐơn hàng gần đây của khách từ Supabase:\n$orderText\n\nCâu hỏi khách: $question',
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseJsonSchema': {
          'type': 'object',
          'properties': {
            'answer': {'type': 'string'},
            'recommendations': {
              'type': 'array',
              'maxItems': 4,
              'items': {
                'type': 'object',
                'properties': {
                  'product_id': {'type': 'string'},
                  'reason': {'type': 'string'},
                },
                'required': ['product_id', 'reason'],
              },
            },
          },
          'required': ['answer', 'recommendations'],
        },
      },
    };

    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
      ),
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey},
      body: jsonEncode(request),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini error ${response.statusCode}: ${response.body}');
    }

    final payload = jsonDecode(utf8.decode(response.bodyBytes));
    final outputText = _extractGeminiText(payload as Map<String, dynamic>);
    final parsed = jsonDecode(outputText) as Map<String, dynamic>;
    final recommendations = (parsed['recommendations'] as List)
        .map((item) {
          final json = Map<String, dynamic>.from(item as Map);
          final productId = json['product_id']?.toString() ?? '';
          final product = availableProducts.firstWhereOrNull(
            (item) => item.product.id == productId,
          );
          if (product == null) return null;
          return AiFoodRecommendation(
            product: product,
            reason: json['reason']?.toString() ?? '',
          );
        })
        .whereType<AiFoodRecommendation>()
        .toList();

    return _AiResponse(
      answer:
          parsed['answer']?.toString() ?? 'Mình đã tìm được vài món phù hợp.',
      recommendations: recommendations,
    );
  }

  String _extractGeminiText(Map<String, dynamic> payload) {
    final candidates = payload['candidates'] as List? ?? [];
    for (final candidate in candidates) {
      if (candidate is! Map) continue;
      final content = candidate['content'] as Map?;
      final parts = content?['parts'] as List? ?? [];
      for (final part in parts) {
        if (part is! Map) continue;
        final text = part['text']?.toString();
        if (text != null && text.trim().isNotEmpty) return text;
      }
    }
    throw Exception('Gemini response has no text');
  }

  List<AiFoodRecommendation> _buildLocalSuggestion(String question) {
    final normalized = question.toLowerCase();
    final maxPrice = _extractBudget(normalized);

    var candidates = availableProducts.where((item) {
      if (maxPrice != null && item.product.price > maxPrice) return false;
      final haystack =
          '${item.product.name} ${item.product.description ?? ''} ${item.categoryName} ${item.options.join(' ')}'
              .toLowerCase();
      final words = normalized
          .split(RegExp(r'\s+'))
          .where((word) => word.length >= 3)
          .toList();
      if (words.isEmpty) return true;
      return words.any(haystack.contains);
    }).toList();

    if (candidates.isEmpty) {
      candidates = availableProducts.toList();
    }

    candidates.sort((a, b) {
      final ratingCompare = b.product.ratingAvg.compareTo(a.product.ratingAvg);
      if (ratingCompare != 0) return ratingCompare;
      return a.product.price.compareTo(b.product.price);
    });

    return candidates.take(4).map((item) {
      return AiFoodRecommendation(
        product: item,
        reason: maxPrice == null
            ? 'Phù hợp với yêu cầu và đang có trong thực đơn.'
            : 'Giá nằm trong ngân sách khoảng ${maxPrice.toStringAsFixed(0)}đ.',
      );
    }).toList();
  }

  bool _isOrderQuestion(String question) {
    final normalized = question.toLowerCase();
    return normalized.contains('đơn') ||
        normalized.contains('don') ||
        normalized.contains('trạng thái') ||
        normalized.contains('trang thai') ||
        normalized.contains('giao') ||
        normalized.contains('hủy') ||
        normalized.contains('huy');
  }

  String _buildLocalOrderAnswer(String question) {
    if (!authController.isLoggedIn) {
      return 'Bạn cần đăng nhập để mình kiểm tra trạng thái đơn hàng nhé.';
    }

    if (recentOrders.isEmpty) {
      return 'Mình chưa thấy đơn hàng gần đây của bạn. Bạn có thể mở mục lịch sử đơn hàng để kiểm tra thêm.';
    }

    final normalized = question.toLowerCase();
    final matchedOrder = recentOrders.firstWhereOrNull((order) {
      final code = order.displayCode.toLowerCase();
      return normalized.contains(code);
    });
    final order = matchedOrder ?? recentOrders.first;
    final itemText = order.items.isEmpty
        ? ''
        : ' gồm ${order.items.map((item) => '${item.quantity}x ${item.name}').join(', ')}';

    return 'Đơn #${order.displayCode}$itemText hiện đang ở trạng thái "${order.statusDisplay}". Tổng tiền ${order.totalAmount.toStringAsFixed(0)}đ.';
  }

  double? _extractBudget(String text) {
    final match = RegExp(r'(\d+)\s*(k|nghìn|ngàn|000)?').firstMatch(text);
    if (match == null) return null;

    final value = double.tryParse(match.group(1) ?? '');
    if (value == null) return null;

    final unit = match.group(2);
    if (unit == null) return value >= 1000 ? value : value * 1000;
    return value * 1000;
  }

  void _addAssistantMessage(
    String text, {
    List<AiFoodRecommendation> recommendations = const [],
  }) {
    lastRecommendations.value = recommendations;
    messages.add(
      AiFoodMessage(
        role: AiFoodMessageRole.assistant,
        text: text,
        recommendations: recommendations,
      ),
    );
  }
}

enum AiFoodMessageRole { user, assistant }

class AiFoodMessage {
  final AiFoodMessageRole role;
  final String text;
  final List<AiFoodRecommendation> recommendations;

  const AiFoodMessage({
    required this.role,
    required this.text,
    this.recommendations = const [],
  });
}

class AiFoodProduct {
  final ProductModel product;
  final String categoryName;
  final List<String> options;

  const AiFoodProduct({
    required this.product,
    required this.categoryName,
    this.options = const [],
  });

  AiFoodProduct copyWith({List<String>? options}) {
    return AiFoodProduct(
      product: product,
      categoryName: categoryName,
      options: options ?? this.options,
    );
  }

  String get formattedPrice => '${product.price.toStringAsFixed(0)}đ';

  String get promptLine {
    final description = product.description?.trim();
    final optionText = options.isEmpty
        ? 'Không có tùy chọn'
        : options.join('; ');
    return '- id: ${product.id} | tên: ${product.name} | giá: $formattedPrice | danh mục: $categoryName | đánh giá: ${product.ratingAvg.toStringAsFixed(1)}/5 | mô tả: ${description == null || description.isEmpty ? 'Không có mô tả' : description} | tùy chọn: $optionText';
  }
}

class AiFoodRecommendation {
  final AiFoodProduct product;
  final String reason;

  const AiFoodRecommendation({required this.product, required this.reason});
}

class AiOrderContext {
  final String id;
  final String? orderCode;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final DateTime createdAt;
  final List<AiOrderItemContext> items;

  const AiOrderContext({
    required this.id,
    this.orderCode,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory AiOrderContext.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List? ?? [];
    return AiOrderContext(
      id: json['id'] as String,
      orderCode: json['order_code'] as String?,
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: rawItems
          .map(
            (item) => AiOrderItemContext.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  String get displayCode => orderCode ?? id.substring(0, 8).toUpperCase();

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'delivering':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String get promptLine {
    final itemText = items.isEmpty
        ? 'Không có chi tiết món'
        : items.map((item) => '${item.quantity}x ${item.name}').join(', ');
    return '- mã đơn: #$displayCode | trạng thái: $statusDisplay | thanh toán: $paymentStatus | tổng tiền: ${totalAmount.toStringAsFixed(0)}đ | ngày đặt: ${createdAt.day}/${createdAt.month}/${createdAt.year} | món: $itemText';
  }
}

class AiOrderItemContext {
  final String name;
  final int quantity;

  const AiOrderItemContext({required this.name, required this.quantity});

  factory AiOrderItemContext.fromJson(Map<String, dynamic> json) {
    return AiOrderItemContext(
      name: json['product_name']?.toString() ?? 'Sản phẩm',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class _AiResponse {
  final String answer;
  final List<AiFoodRecommendation> recommendations;

  const _AiResponse({required this.answer, required this.recommendations});
}
