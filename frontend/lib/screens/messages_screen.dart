import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:toyshop/utils/shared_prefs.dart';
import 'package:toyshop/screens/chat_screen.dart'; 

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _messages = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchMessages();
  }

  Future<void> _loadCurrentUser() async {
    final token = await SharedPrefs.getToken();
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8080/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final user = jsonDecode(res.body);
      setState(() {
        _currentUserId = user['id'];
      });
    }
  }

  Future<void> _fetchMessages() async {
  final token = await SharedPrefs.getToken();
  print('Token: $token');  // Вивести токен в консолі для перевірки
  final response = await http.get(
    Uri.parse('http://10.0.2.2:8080/messages'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data != null && data is List) {
      setState(() => _messages = data);
    } else {
      // Якщо немає даних або вони не в списку, відображаємо порожнє повідомлення
      setState(() => _messages = []);
    }
  } else {
    setState(() => _messages = []);
  }
  }


  Future<void> _sendReply(int receiverId) async {
    final controller = TextEditingController();
    final token = await SharedPrefs.getToken();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Відповісти'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Повідомлення'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final response = await http.post(
                Uri.parse('http://10.0.2.2:8080/messages'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'receiver_id': receiverId,
                  'content': controller.text,
                }),
              );

              if (response.statusCode == 201) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Відповідь надіслано')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Помилка: ${response.body}')),
                );
              }
            },
            child: const Text('Надіслати'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вхідні повідомлення')),
      body: _messages.isEmpty
          ? const Center(child: Text('Немає повідомлень'))
          : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final senderId = msg['sender_id'];

                return ListTile(
                  leading: const Icon(Icons.message),
                  title: Text(msg['content']),
                  subtitle: Text('Від: ${msg['sender_name'] ?? 'Невідомо'}'),
              onTap: () {
                      if (_currentUserId != null) {
                        final threadId = msg['thread_id'];
                    
                        // 🛠️ Оголошуємо одразу
                        final isMeSender = msg['sender_id'] == _currentUserId;
                        final receiverId = isMeSender ? msg['receiver_id'] : msg['sender_id'];
                    
                        // ✅ Тепер перевірка після оголошення
                        if (receiverId == null) {
                          print('❌ receiverId is null');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Неможливо відкрити чат: невідомий користувач')),
                          );
                          return;
                        }
                    
                        final productId = msg['product_id'];
                        if (productId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Не вдалося відкрити чат: відсутній product_id')),
                          );
                          return;
                        }
                    
                        print('Thread ID: ${msg['thread_id']}');
                        print('Sender ID: ${msg['sender_id']}');
                        print('Receiver ID: ${msg['receiver_id']}');
                        print('Product ID: ${msg['product_id']}');
                    
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              receiverId: receiverId,
                              productId: productId,
                              threadId: threadId,
                            ),
                          ),
                        );
                      }
                    },


                );
              },
            ),
    );
  }
}
