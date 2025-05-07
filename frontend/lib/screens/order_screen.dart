import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:toyshop/utils/shared_prefs.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final token = await SharedPrefs.getToken();

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/my-orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(jsonEncode(data));
      setState(() => _orders = data);
    } else {
      setState(() => _orders = []);
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final token = await SharedPrefs.getToken();
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8080/orders/$orderId/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        final index = _orders.indexWhere((o) => o['id'] == orderId);
        if (index != -1) {
          _orders[index]['status'] = 'скасовано';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Замовлення скасовано')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Помилка при скасуванні')),
      );
    }
  }

  void _showOrderDetails(dynamic order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Деталі замовлення'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...order['items'].map<Widget>((item) {
                final product = item['product'];
                return ListTile(
                  leading: product['image_url'] != null
                      ? Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                  title: Text(product['name'] ?? 'Без назви'),
                  subtitle: Text('Кількість: ${item['quantity']}'),
                  trailing: Text('${item['unit_price']} грн'),
                );
              }).toList(),
              const SizedBox(height: 12),
              Text('Адреса доставки: ${order['shipping_address']}'),
              Text('Оплата: ${order['payment_status']}'),
              Text('Статус: ${order['status']}'),
              Text('Сума: ${order['total_price']} грн'),
              if (order['created_at'] != null)
                Text('Дата: ${order['created_at'].substring(0, 16)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрити'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мої замовлення')),
      body: _orders.isEmpty
          ? const Center(child: Text('Немає замовлень'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final firstItem = order['items'].isNotEmpty ? order['items'][0] : null;
                final product = firstItem != null ? firstItem['product'] : null;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: product != null && product['image_url'] != null
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
                    title: Text(
                      product != null ? product['name'] ?? 'Товар' : 'Товар',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Сума: ${order['total_price']} грн'),
                        Text('Статус: ${order['status']}'),
                      ],
                    ),
                    trailing: order['status'] != 'скасовано'
                        ? TextButton(
                            onPressed: () => _cancelOrder(order['id']),
                            child: const Text('Скасувати', style: TextStyle(color: Colors.red)),
                          )
                        : null,
                    onTap: () => _showOrderDetails(order),
                  ),
                );
              },
            ),
    );
  }
}
