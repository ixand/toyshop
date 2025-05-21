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
  Map<String, dynamic>? _owner;
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
          _owner = owner;
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
    final int stock = widget.product['stock_quantity'] as int? ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Деталі товару')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Фото
                if (widget.product['image_url'] != null &&
                    widget.product['image_url'].toString().startsWith('http'))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.product['image_url'],
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Image.asset('assets/images/placeholder.png', height: 220),

                const SizedBox(height: 16),

                // Автор
                InkWell(
                  onTap: () {
                    if (_owner != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AuthorProfileScreen(
                                ownerId: widget.product['owner_id'],
                              ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Автор товару',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _owner?['name'] ?? 'завантаження...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Назва і ціна
                Text(
                  widget.product['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.product['price']} грн',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
                const SizedBox(height: 16),

                // Опис
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Опис',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.product['description'] ?? 'Немає опису'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Кількість
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined),
                      const SizedBox(width: 8),
                      Text('В наявності: $stock шт'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Дата створення
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text('Створено: $createdAt'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ввід повідомлення
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Введіть повідомлення...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
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
