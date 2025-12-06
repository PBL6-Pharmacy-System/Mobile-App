import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/gap.dart';
import 'package:pharmacy_app/services/chat_service.dart';
import 'package:pharmacy_app/models/product_model.dart';
import 'package:pharmacy_app/presentation/detail_product/product_detail_page.dart';
import 'package:pharmacy_app/services/product_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ProductService _productService = ProductService();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;

  // Animation controller cho typing indicator
  late AnimationController _typingAnimationController;

  final List<Map<String, dynamic>> messages = [
    {
      'id': 'welcome',
      'isUser': false,
      'message':
          'Xin chào! Tôi là trợ lý AI của nhà thuốc. Tôi có thể giúp gì cho bạn về thuốc và sức khỏe?',
      'time': _formatTime(DateTime.now()),
      'products': <ChatProduct>[],
    },
  ];

  static String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final aiMessageId = '${userMessageId}_ai';

    setState(() {
      messages.add({
        'id': userMessageId,
        'isUser': true,
        'message': text,
        'time': _formatTime(DateTime.now()),
        'products': <ChatProduct>[],
      });

      messages.add({
        'id': aiMessageId,
        'isUser': false,
        'message': '',
        'time': _formatTime(DateTime.now()),
        'isStreaming': true,
        'products': <ChatProduct>[],
      });

      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    await _chatService.sendMessageStream(
      message: text,
      onData: (chunk) {
        setState(() {
          final index = messages.indexWhere((m) => m['id'] == aiMessageId);
          if (index != -1) {
            messages[index]['message'] += chunk;
          }
        });
        _scrollToBottom();
      },
      onProducts: (products) {
        setState(() {
          final index = messages.indexWhere((m) => m['id'] == aiMessageId);
          if (index != -1) {
            messages[index]['products'] = products;
          }
        });
        _scrollToBottom();
      },
      onDone: () {
        setState(() {
          final index = messages.indexWhere((m) => m['id'] == aiMessageId);
          if (index != -1) {
            messages[index]['isStreaming'] = false;
            messages[index]['time'] = _formatTime(DateTime.now());
          }
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() {
          final index = messages.indexWhere((m) => m['id'] == aiMessageId);
          if (index != -1) {
            messages[index]['message'] = '❌ $error';
            messages[index]['isStreaming'] = false;
            messages[index]['isError'] = true;
          }
          _isLoading = false;
        });
      },
    );
  }

  /// Xem chi tiết sản phẩm
  Future<void> _viewProductDetail(ChatProduct chatProduct) async {
    try {
      // Load full product from API
      final product = await _productService.getProductById(chatProduct.id);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailPage(product)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông tin sản phẩm: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: Colors.white,
          ),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy, color: primaryColor),
            ),
            Gap.sMWidth,
            const Text(
              'Trợ lý AI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
            tooltip: 'Cuộc hội thoại mới',
            onPressed: () {
              setState(() {
                messages.clear();
                messages.add({
                  'id': 'welcome',
                  'isUser': false,
                  'message':
                      'Xin chào! Tôi là trợ lý AI của nhà thuốc. Tôi có thể giúp gì cho bạn?',
                  'time': _formatTime(DateTime.now()),
                  'products': <ChatProduct>[],
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageItem(messages[index]),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final isUser = msg['isUser'] as bool;
    final isStreaming = msg['isStreaming'] == true;
    final isError = msg['isError'] == true;
    final products = (msg['products'] as List<ChatProduct>?) ?? [];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.smart_toy, size: 18, color: primaryColor),
              ),
            if (!isUser) const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Text message
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? primaryColor
                          : isError
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isUser
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg['message'].isEmpty && isStreaming)
                          _buildTypingIndicator()
                        else
                          Text(
                            msg['message'],
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : isError
                                  ? Colors.red.shade700
                                  : Colors.grey.shade800,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        if (isStreaming && msg['message'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  primaryColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white70
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Products list
                  if (products.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildProductsList(products),
                  ],
                ],
              ),
            ),
            if (isUser) const SizedBox(width: 6),
            if (isUser)
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, size: 18, color: primaryColor),
              ),
          ],
        ),
      ),
    );
  }

  /// Widget hiển thị danh sách sản phẩm
  Widget _buildProductsList(List<ChatProduct> products) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '📦 Sản phẩm gợi ý:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ...products.map((p) => _buildProductCard(p)).toList(),
        ],
      ),
    );
  }

  /// Widget card sản phẩm
  Widget _buildProductCard(ChatProduct product) {
    return GestureDetector(
      onTap: () => _viewProductDetail(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.medication_rounded,
                          color: Colors.grey.shade400,
                          size: 28,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.medication_rounded,
                      color: Colors.grey.shade400,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 10),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(product.price),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (product.unit != null && product.unit!.isNotEmpty)
                    Text(
                      '/${product.unit}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            // View button
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatPrice(String priceString) {
    final price = double.tryParse(priceString) ?? 0;
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '${formatted}đ';
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_isLoading,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                enableIMEPersonalizedLearning: true,
                autocorrect: false,
                enableSuggestions: true,
                decoration: InputDecoration(
                  hintText: _isLoading ? 'Đang trả lời...' : 'Nhập câu hỏi...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: _isLoading ? Colors.grey.shade300 : primaryColor,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _isLoading ? null : _sendMessage,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.grey.shade500,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final double offset = index * 0.2;
            final double animValue =
                (_typingAnimationController.value + offset) % 1.0;
            double bounce = 0;
            if (animValue < 0.5) {
              bounce = animValue * 2;
            } else {
              bounce = (1 - animValue) * 2;
            }
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              child: Transform.translate(
                offset: Offset(0, -bounce * 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.4 + (bounce * 0.4)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
