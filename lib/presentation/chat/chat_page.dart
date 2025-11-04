import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/constant.dart';
import 'package:pharmacy_app/configs/gap.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> messages = [
    {
      'isUser': false,
      'message': 'Xin chào! Tôi là Dược sĩ Minh. Tôi có thể giúp gì cho bạn?',
      'time': '10:00',
    },
    {
      'isUser': true,
      'message': 'Chào Dược sĩ, em bị đau đầu và sốt nhẹ. Nên dùng thuốc gì ạ?',
      'time': '10:02',
    },
    {
      'isUser': false,
      'message':
          'Bạn có thể sử dụng Paracetamol 500mg để giảm đau và hạ sốt.\nUống 1-2 viên mỗi lần, cách 4-6 giờ. Nhớ uống sau bữa ăn nhé!',
      'time': '10:03',
    },
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      messages.add({
        'isUser': true,
        'message': _controller.text.trim(),
        'time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Gap.mdWidth,
            const CircleAvatar(
              backgroundImage: NetworkImage(
                'https://picsum.photos/id/1005/100/100',
              ),
            ),
            Gap.sMWidth,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Dược sĩ Minh',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Đang hoạt động',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['isUser'] as bool;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          const CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(
                              'https://picsum.photos/id/1005/100/100',
                            ),
                          ),
                        if (!isUser) const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? primaryColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isUser
                                    ? const Radius.circular(12)
                                    : const Radius.circular(0),
                                bottomRight: isUser
                                    ? const Radius.circular(0)
                                    : const Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              msg['message'],
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 6),
                        if (isUser)
                          const CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(
                              'https://picsum.photos/id/1011/100/100',
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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
}
