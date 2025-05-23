import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrderDetailScreen extends StatefulWidget {
  final dynamic order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _owner;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOwner(widget.order['items'][0]['product']['owner_id']);
  }

  Future<void> _fetchOwner(int ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List;
      final found = users.firstWhere(
        (u) => u['id'] == ownerId,
        orElse: () => null,
      );
      if (found != null) {
        setState(() => _owner = found);
      }
    }
  }

  Future<void> _sendMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final receiverId = widget.order['items'][0]['product']['owner_id'];

    final res = await http.post(
      Uri.parse('http://10.0.2.2:8080/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'receiver_id': receiverId,
        'product_id': widget.order['items'][0]['product']['id'],
        'content': _messageController.text,
      }),
    );

    if (res.statusCode == 201) {
      _messageController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Повідомлення надіслано')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.order['items'][0]['product'];
    final quantity = widget.order['items'][0]['quantity'];
    final total = widget.order['total_price'];

    return Scaffold(
      appBar: AppBar(title: const Text('Деталі замовлення')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (product['image_url'] != null &&
                    product['image_url'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product['image_url'],
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/placeholder.png',
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 12),
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₴${product['price']} × $quantity = ₴$total',
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(height: 12),
                Text(product['description'] ?? 'Немає опису'),
                const Divider(height: 32),
                const Text(
                  'Автор',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_owner != null) ...[
                  Text('Імʼя: ${_owner!['name']}'),
                  Text('Email: ${_owner!['email']}'),
                  if (_owner!['phone'] != null)
                    Text('Телефон: ${_owner!['phone']}'),
                ],
              ],
            ),
          ),
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
                    onPressed: _sendMessage,
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
