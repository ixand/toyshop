import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:toyshop/utils/shared_prefs.dart';

class ChatScreen extends StatefulWidget {
  final int? receiverId;
  final int? productId;
  final String? threadId;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.productId,
    required this.threadId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}


class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  final _controller = TextEditingController();
  int? _currentUserId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final token = await SharedPrefs.getToken();
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8080/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final user = jsonDecode(res.body);
      _currentUserId = user['id'];
      _loadThreadMessages(); // завантажуємо після отримання currentUserId
    }
  }

  Future<void> _loadThreadMessages() async {
  final token = await SharedPrefs.getToken();
  final res = await http.get(
    Uri.parse('http://10.0.2.2:8080/messages/thread/${widget.threadId}'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    setState(() => _messages = data);
    _scrollDown();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Помилка при завантаженні чату')),
    );
  }
}

Future<void> _sendMessage() async {
  final token = await SharedPrefs.getToken();

  if (_currentUserId == widget.receiverId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ви не можете надіслати повідомлення самому собі')),
    );
    return;
  }

  final res = await http.post(
    Uri.parse('http://10.0.2.2:8080/messages'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'receiver_id': widget.receiverId,
      'content': _controller.text,
      'product_id': widget.productId, 
    }),
  );

  if (res.statusCode == 201) {
    _controller.clear();
    _loadThreadMessages();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Помилка при надсиланні повідомлення')),
    );
  }
}



  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чат')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Найновіші внизу
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                final isMine = msg['sender_id'] == _currentUserId;

                return Container(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['content'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['created_at']?.substring(0, 16) ?? '',
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Введіть повідомлення...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
