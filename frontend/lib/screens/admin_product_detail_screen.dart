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
  late Map<String, dynamic> _previous;
  final List<String> _statusOptions = ['pending', 'active', 'inactive'];

  @override
  void initState() {
    super.initState();
    _status = widget.product['status'] ?? 'pending';

    try {
      _previous = jsonDecode(widget.product['previous_data'] ?? '{}');
    } catch (_) {
      _previous = {};
    }
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Статус оновлено')));
      Navigator.pop(context, true); // ✅ Повертаємось до попереднього екрану
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка: ${response.body}')));
    }
  }

  Widget _buildField(String label, dynamic current, dynamic previous) {
    final hasChanged =
        previous != null && previous.toString() != current.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (hasChanged) ...[
          Text('Було: $previous', style: const TextStyle(color: Colors.red)),
          Text('Стало: $current', style: const TextStyle(color: Colors.green)),
        ] else
          Text(
            current?.toString() ?? '',
            style: const TextStyle(color: Colors.green),
          ),
        const SizedBox(height: 12),
      ],
    );
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
            _buildField('Назва', product['name'], _previous['name']),
            _buildField(
              'Опис',
              product['description'],
              _previous['description'],
            ),
            _buildField('Ціна (грн)', product['price'], _previous['price']),
            _buildField(
              'Кількість',
              product['stock_quantity'],
              _previous['stock_quantity'],
            ),
            _buildField('Локація', product['location'], _previous['location']),
            _buildField(
              'Категорія ID',
              product['category_id'],
              _previous['category_id'],
            ),
            _buildField('Автор ID', product['owner_id'], _previous['owner_id']),
            const SizedBox(height: 12),
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
