import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/shared_prefs.dart';
import 'admin_product_detail_screen.dart';

class AdminProductModerationScreen extends StatefulWidget {
  const AdminProductModerationScreen({super.key});

  @override
  State<AdminProductModerationScreen> createState() =>
      _AdminProductModerationScreenState();
}

class _AdminProductModerationScreenState
    extends State<AdminProductModerationScreen> {
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final token = await SharedPrefs.getToken();
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/admin/products'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _products = jsonDecode(response.body);
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Модерація товарів')),
      body:
          _products.isEmpty
              ? const Center(child: Text('Немає товарів для модерації'))
              : ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AdminProductDetailScreen(product: product),
                        ),
                      ).then(
                        (_) => _loadProducts(),
                      ); // оновити після повернення
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: ListTile(
                        leading:
                            product['image_url'] != null &&
                                    product['image_url'].toString().isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product['image_url'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Icon(Icons.image_not_supported),
                        title: Text(product['name'] ?? 'Без назви'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ціна: ${product['price']} грн'),
                            Text(
                              'Статус: ${_mapStatusToUkr(product['status'] ?? '')}',
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
