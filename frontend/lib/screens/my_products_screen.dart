import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:toyshop/utils/shared_prefs.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List<dynamic> _products = [];

  bool _hasProducts = true;


  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

    Future<void> _loadMyProducts() async {
      final token = await SharedPrefs.getToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/my-products'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final all = jsonDecode(response.body);
        setState(() {
          _products = all;
          _hasProducts = all.isNotEmpty;
        });
      } else {
        setState(() {
          _products = [];
          _hasProducts = false;
        });
      }
    }


  void _deleteProduct(int id) async {
    final token = await SharedPrefs.getToken();
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8080/products/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      _loadMyProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Помилка при видаленні')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мої оголошення')),
      body: _products.isEmpty
        ? const Center(
            child: Text(
              'У вас ще немає оголошень',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : ListView.builder(
  itemCount: _products.length,
  itemBuilder: (context, index) {
    final product = _products[index];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: product['image_url'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['image_url'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.image, size: 48),
        title: Text(product['name']),
        subtitle: Text('${product['price']} грн'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () async {
                    final updated = await Navigator.pushNamed(
                      context,
                      '/edit-product',
                      arguments: product,
                    );
                    if (updated == true) _loadMyProducts();
                  },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProduct(product['id']),
                      ),
                    ],
                  ),
                ),
            );
          },
        ),

      );
    }
}
