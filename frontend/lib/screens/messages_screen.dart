import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:toyshop/utils/shared_prefs.dart';
import 'package:toyshop/screens/chat_screen.dart'; // ← не забудь

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
  final response = await http.get(
    Uri.parse('http://10.0.2.2:8080/messages'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Групуємо по sender_id
    final seen = <int>{};
    final uniqueMessages = <dynamic>[];

    for (final msg in data) {
      final senderId = msg['sender_id'];
      if (!seen.contains(senderId)) {
        seen.add(senderId);
        uniqueMessages.add(msg);
      }
    }

    setState(() => _messages = uniqueMessages);
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(receiverId: senderId),
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
