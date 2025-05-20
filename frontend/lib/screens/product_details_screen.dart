import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'author_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _ownerName;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOwnerName(widget.product['owner_id']);
  }

  Future<void> _fetchOwnerName(int ownerId) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/users'));
    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List;
      final owner = users.firstWhere(
        (u) => u['id'] == ownerId,
        orElse: () => null,
      );
      if (owner != null) {
        setState(() {
          _ownerName = owner['name'];
        });
      }
    }
  }

  Future<void> _sendMessageToAuthor() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'receiver_id': widget.product['owner_id'],
        'content': _messageController.text,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Повідомлення надіслано')));
      _messageController.clear();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка: ${response.body}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt =
        widget.product['created_at']?.substring(0, 10) ?? 'невідомо';
    final int stock = widget.product['stock_quantity'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Деталі товару')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🧸 Фото
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      widget.product['image_url'] != null
                          ? Image.network(
                            widget.product['image_url'],
                            height: 200,
                            fit: BoxFit.cover,
                          )
                          : Image.asset(
                            'assets/images/placeholder.png',
                            height: 200,
                          ),
                ),
                const SizedBox(height: 16),

                // 👤 Автор
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AuthorProfileScreen(
                              ownerId: widget.product['owner_id'],
                            ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Автор товару',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _ownerName ?? 'завантаження...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),

                // 🏷️ Назва та ціна
                Text(
                  widget.product['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.product['price']} грн',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),

                const SizedBox(height: 16),
                const Divider(),

                // 📄 Опис
                if (widget.product['description'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Опис',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.product['description']),
                    ],
                  ),

                const SizedBox(height: 16),
                const Divider(),

                // 📦 Кількість
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 20),
                    const SizedBox(width: 8),
                    Text('В наявності: $stock шт'),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),

                // 📅 Дата створення
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text('Створено: $createdAt'),
                  ],
                ),
              ],
            ),
          ),

          // 💬 Поле для повідомлення
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Введіть повідомлення...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _sendMessageToAuthor,
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
