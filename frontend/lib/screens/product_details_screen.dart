import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  Future<void> _orderProduct(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final currentUserId = product['owner_id'];
    final userId = await _getCurrentUserId(token);
    if (userId == currentUserId) {
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
        'shipping_address': 'вулиця Прикладна, 1',
        'items': [
          {'product_id': product['id'], 'quantity': 1},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Деталі товару')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${product['price']} грн', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(product['description'] ?? ''),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _orderProduct(context),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Замовити'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
