import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
      final _addressController = TextEditingController(text: 'вулиця Прикладна, 1');
      int _quantity = 1;
      String? _ownerName;
      String? _createdAt;
      final _messageController = TextEditingController();



      @override
    void initState() {
      super.initState();
      _createdAt = widget.product['created_at']?.substring(0, 10);
      _fetchOwnerName(widget.product['owner_id']);
    }



  Future<void> _fetchOwnerName(int ownerId) async {
  final response = await http.get(Uri.parse('http://10.0.2.2:8080/users'));
  print('Дата створення: ${widget.product['created_at']}');
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

      if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List;
      final owner = users.firstWhere(
        (u) => u['id'] == widget.product['owner_id'],
        orElse: () => null,
      );
      if (owner != null) {
        setState(() {
          _ownerName = owner['name'];
        });
      }
    }
  }

  Future<void> _orderProduct(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final userId = await _getCurrentUserId(token);
    if (userId == widget.product['owner_id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ви не можете замовити свій товар')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'shipping_address': _addressController.text,
        'items': [
          {'product_id': widget.product['id'], 'quantity': _quantity},
        ]
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар замовлено!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: ${response.body}')),
      );
    }
  }

  Future<int?> _getCurrentUserId(String token) async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8080/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['id'];
    }
    return null;
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Повідомлення надіслано')),
    );
    _messageController.clear();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Помилка: ${response.body}')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final createdAt = widget.product['created_at']?.substring(0, 10) ?? 'невідомо';

    return Scaffold(
      appBar: AppBar(title: const Text('Деталі товару')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(widget.product['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${widget.product['price']} грн', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (widget.product['description'] != null)
              Text(widget.product['description']),
            const SizedBox(height: 8),
            Text('Автор: ${_ownerName ?? 'завантаження...'}'),
            Text('Створено: ${_createdAt ?? 'невідомо'}'),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Адреса доставки',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Кількість:'),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() {
                    if (_quantity > 1) _quantity--;
                  }),
                ),
                Text('$_quantity'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() {
                    _quantity++;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _orderProduct(context),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Замовити'),
            ),
            const SizedBox(height: 24),
      TextField(
        controller: _messageController,
        decoration: const InputDecoration(
          labelText: 'Повідомлення автору',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: () => _sendMessageToAuthor(),
        icon: const Icon(Icons.message),
        label: const Text('Надіслати повідомлення автору'),
      ),

          ],
        ),
      ),
    );
  }
}
