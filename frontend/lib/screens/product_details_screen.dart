import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'author_profile_screen.dart';
import 'order_confirm_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _owner;
  int? _currentUserId;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchOwner(widget.product['owner_id']);
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _currentUserId = data['id'];
      });
    }
  }

  Future<void> _fetchOwner(int ownerId) async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/users'));
    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List;
      final owner = users.firstWhere(
        (u) => u['id'] == ownerId,
        orElse: () => null,
      );
      if (owner != null) {
        setState(() {
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
        'product_id': widget.product['id'],
        'content': _messageController.text,
      }),
    );

    if (response.statusCode == 201) {
      _messageController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Повідомлення надіслано')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка: ${response.body}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product['image_url'];
    final createdAt = product['created_at']?.substring(0, 10) ?? 'невідомо';
    final stock = product['stock_quantity'] ?? 0;
    final isOwnProduct = _currentUserId == product['owner_id'];

    return Scaffold(
      appBar: AppBar(title: const Text('Деталі товару')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                imageUrl != null && imageUrl.toString().startsWith('http')
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    )
                    : Image.asset('assets/images/placeholder.png', height: 220),

                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    if (_owner != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AuthorProfileScreen(
                                ownerId: product['owner_id'],
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
                            const Text('Автор товару'),
                            Text(
                              _owner?['name'] ?? 'Завантаження...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${product['price']} грн',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
                const SizedBox(height: 16),
                _buildInfoCard('Опис', product['description'] ?? 'Немає опису'),
                _buildInfoCard('В наявності', '$stock шт'),
                _buildInfoCard('Створено', createdAt),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isOwnProduct)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text(
                          'Замовити',
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => OrderConfirmScreen(
                                    product: widget.product,
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(content)),
        ],
      ),
    );
  }
}
