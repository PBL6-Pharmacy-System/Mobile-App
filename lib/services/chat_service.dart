import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Model cho sản phẩm từ AI chat
class ChatProduct {
  final int id;
  final String name;
  final String price;
  final String? imageUrl;
  final String? description;
  final String? unit;

  ChatProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
    this.unit,
  });

  factory ChatProduct.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing product: $json');
    return ChatProduct(
      id: json['id'] ?? json['product_id'] ?? 0,
      name: json['name'] ?? json['product_name'] ?? '',
      price: json['price']?.toString() ?? json['base_price']?.toString() ?? '0',
      imageUrl:
          json['image_url'] ??
          json['imageUrl'] ??
          json['image'] ??
          json['thumbnail'],
      description: json['description'] ?? json['short_description'],
      unit: json['unit'] ?? json['unittype']?['name'] ?? json['unit_type'],
    );
  }
}

/// Response từ AI chat có thể chứa text và products
class ChatResponse {
  final String text;
  final List<ChatProduct> products;
  final bool isComplete;

  ChatResponse({
    required this.text,
    this.products = const [],
    this.isComplete = false,
  });
}

class ChatService {
  // URL AI Server
  static const String aiBaseUrl =
      'https://unendowed-placably-aviana.ngrok-free.dev';

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration responseTimeout = Duration(seconds: 120);

  // Storage for getting auth token
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Get access token from storage
  Future<String?> _getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// Gửi tin nhắn và nhận response theo stream
  /// API: /api/auth-chat/stream
  Future<void> sendMessageStream({
    required String message,
    required Function(String chunk) onData,
    required Function(List<ChatProduct> products) onProducts,
    required Function() onDone,
    required Function(String error) onError,
    String? conversationId,
  }) async {
    final client = http.Client();

    try {
      final uri = Uri.parse('$aiBaseUrl/api/auth-chat/stream');

      // Get auth token
      final token = await _getAccessToken();
      if (token == null || token.isEmpty) {
        onError('Vui lòng đăng nhập để sử dụng tính năng chat');
        return;
      }

      print('🔵 Sending message to AI: $message');
      print('🔑 Using token: ${token.substring(0, 20)}...');

      final request = http.Request('POST', uri);
      request.headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      });

      request.body = jsonEncode({
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
      });

      final streamedResponse = await client
          .send(request)
          .timeout(
            connectTimeout,
            onTimeout: () {
              throw TimeoutException('Kết nối quá lâu. Vui lòng thử lại.');
            },
          );

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        print('🔴 Error: $body');
        onError('Lỗi server: ${streamedResponse.statusCode}');
        return;
      }

      final StringBuffer buffer = StringBuffer();

      await for (final chunk
          in streamedResponse.stream
              .timeout(responseTimeout)
              .transform(utf8.decoder)) {
        buffer.write(chunk);
        final lines = buffer.toString().split('\n');

        buffer.clear();
        if (!chunk.endsWith('\n') && lines.isNotEmpty) {
          buffer.write(lines.removeLast());
        }

        for (final line in lines) {
          if (line.isEmpty) continue;

          if (line.startsWith('data: ')) {
            final data = line.substring(6);

            if (data == '[DONE]') {
              onDone();
              return;
            }

            try {
              final json = jsonDecode(data);
              print('📦 Received JSON: $json');

              if (json is Map) {
                // Check for type: "products" format
                if (json['type'] == 'products' && json['data'] != null) {
                  print('🛒 Found products type with data');
                  final productsData = json['data'];
                  if (productsData is List) {
                    final products = productsData
                        .map(
                          (p) =>
                              ChatProduct.fromJson(p as Map<String, dynamic>),
                        )
                        .toList();
                    if (products.isNotEmpty) {
                      print('🛒 Parsed ${products.length} products');
                      onProducts(products);
                    }
                  }
                  continue; // Don't process as text
                }

                // Check for type: "text" format
                if (json['type'] == 'text' && json['data'] != null) {
                  final textData = json['data'];
                  if (textData is String && textData.isNotEmpty) {
                    onData(textData);
                  }
                  continue;
                }

                // Text content (fallback)
                final content =
                    json['content'] ??
                    json['text'] ??
                    json['chunk'] ??
                    json['message'] ??
                    json['delta']?['content'] ??
                    '';
                if (content.isNotEmpty && content is String) {
                  onData(content);
                }

                // Products array (direct format)
                if (json['products'] != null && json['products'] is List) {
                  final products = (json['products'] as List)
                      .map(
                        (p) => ChatProduct.fromJson(p as Map<String, dynamic>),
                      )
                      .toList();
                  if (products.isNotEmpty) {
                    print(
                      '🛒 Found ${products.length} products in products array',
                    );
                    onProducts(products);
                  }
                }

                // Single product
                if (json['product'] != null && json['product'] is Map) {
                  final product = ChatProduct.fromJson(
                    json['product'] as Map<String, dynamic>,
                  );
                  onProducts([product]);
                }
              } else if (json is String) {
                onData(json);
              }
            } catch (e) {
              print('⚠️ Parse error: $e, data: $data');
              if (data.isNotEmpty) {
                onData(data);
              }
            }
          }
        }
      }

      if (buffer.isNotEmpty) {
        final remaining = buffer.toString();
        if (remaining.startsWith('data: ')) {
          final data = remaining.substring(6);
          if (data != '[DONE]' && data.isNotEmpty) {
            try {
              final json = jsonDecode(data);
              final content =
                  json['content'] ?? json['text'] ?? json['chunk'] ?? '';
              if (content.isNotEmpty) onData(content);
            } catch (e) {
              onData(data);
            }
          }
        }
      }

      print('🟢 Stream completed');
      onDone();
    } on TimeoutException catch (e) {
      print('🔴 Timeout: ${e.message}');
      onError(e.message ?? 'Kết nối quá lâu');
    } catch (e) {
      print('🔴 Error: $e');
      onError('Không thể kết nối đến AI server');
    } finally {
      client.close();
    }
  }

  /// Non-streaming fallback
  Future<ChatResponse> sendMessage({
    required String message,
    String? conversationId,
  }) async {
    try {
      // Get auth token
      final token = await _getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui lòng đăng nhập để sử dụng tính năng chat');
      }

      final response = await http
          .post(
            Uri.parse('$aiBaseUrl/api/auth-chat'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'ngrok-skip-browser-warning': 'true',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'message': message,
              if (conversationId != null) 'conversation_id': conversationId,
            }),
          )
          .timeout(responseTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['response'] ?? data['message'] ?? data['content'] ?? '';

        List<ChatProduct> products = [];
        if (data['products'] != null && data['products'] is List) {
          products = (data['products'] as List)
              .map((p) => ChatProduct.fromJson(p as Map<String, dynamic>))
              .toList();
        }

        return ChatResponse(text: text, products: products, isComplete: true);
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('AI không phản hồi. Vui lòng thử lại.');
    } catch (e) {
      throw Exception('Không thể kết nối đến AI server: $e');
    }
  }
}
