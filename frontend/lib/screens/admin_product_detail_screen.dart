import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/shared_prefs.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const AdminProductDetailScreen({super.key, required this.product});

  @override
  State<AdminProductDetailScreen> createState() =>
      _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  late String _status;
  final List<String> _statusOptions = ['pending', 'active', 'inactive'];

  @override
  void initState() {
    super.initState();
    _status = widget.product['status'] ?? 'pending';
  }

  Future<void> _updateStatus(String newStatus) async {
    final token = await SharedPrefs.getToken();
    if (token == null) return;

    final response = await http.put(
      Uri.parse(
        'http://10.0.2.2:8080/admin/products/${widget.product['id']}/status',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Статус оновлено')));
      setState(() {
        _status = newStatus;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка: ${response.body}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Деталі товару')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
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
              ),
            const SizedBox(height: 16),
            Text(
              product['name'] ?? 'Без назви',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${product['price']} грн',
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 8),
            if (product['description'] != null)
              Text(
                product['description'],
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 8),
            Text('Категорія ID: ${product['category_id']}'),
            Text('Автор ID: ${product['owner_id']}'),
            const SizedBox(height: 16),
            const Text('Змінити статус:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              items:
                  _statusOptions
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_mapStatusToUkr(s)),
                        ),
                      )
                      .toList(),
              onChanged: (newStatus) {
                if (newStatus != null && newStatus != _status) {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Підтвердження'),
                          content: Text(
                            'Змінити статус на "${_mapStatusToUkr(newStatus)}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Скасувати'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _updateStatus(newStatus);
                              },
                              child: const Text('Підтвердити'),
                            ),
                          ],
                        ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _mapStatusToUkr(String status) {
    switch (status) {
      case 'active':
        return 'Активний';
      case 'inactive':
        return 'Неактивний';
      case 'pending':
      default:
        return 'Очікується';
    }
  }
}
