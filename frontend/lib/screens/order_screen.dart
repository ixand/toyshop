
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchOrders() async {
    final token = await _getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/my-orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => orders = data);
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8080/orders/$orderId/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      _fetchOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Замовлення скасовано')),
      );
    }
  }

Future<void> _payForOrder(dynamic order) async {
  final token = await _getToken();
  final response = await http.post(
    Uri.parse('http://10.0.2.2:8080/orders/${order['id']}/pay'),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 400) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Недостатньо коштів. Поповніть баланс.')),
    );
    Navigator.pushNamed(context, '/top-up');
    return;
  }

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Оплата успішна!')),
    );

    // 🔁 Тут одразу оновлюємо UI
    await _fetchOrders(); // <<< оновлення ДО переходу

    // 🔁 Потім переходимо
    await Navigator.pushNamed(context, '/delivery');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Помилка оплати.')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мої замовлення')),
      body: orders.isEmpty
          ? const Center(child: Text('У вас ще немає замовлень.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(order);
              },
            ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final items = order['items'];
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }

    final item = items[0];
    final product = item['product'];

    final isCanceled = order['status'] == 'скасований';
    final isPaid = order['payment_status'] == 'оплачено';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Image.network(product['image_url'], width: 64, height: 64, fit: BoxFit.cover),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Кількість: ${item['quantity']}'),
                      Text('Сума: ₴${order['total_price']}'),
                      Text('Оплата: ${order['payment_status']}'),
                      Text('Статус: ${order['status']}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isPaid && !isCanceled)
                  ElevatedButton(
                    onPressed: () => _payForOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Оплатити'),
                  ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: isCanceled ? null : () => _cancelOrder(order['id']),
                  child: Text(
                    isCanceled ? 'Скасовано' : 'Скасувати',
                    style: TextStyle(
                      color: isCanceled ? Colors.grey : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}