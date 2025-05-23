import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class IncomingOrdersTab extends StatefulWidget {
  const IncomingOrdersTab({super.key});

  @override
  State<IncomingOrdersTab> createState() => _IncomingOrdersTabState();
}

class _IncomingOrdersTabState extends State<IncomingOrdersTab> {
  List<dynamic> incomingOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchIncomingOrders();
  }

  Future<void> _fetchIncomingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/my-incoming-orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => incomingOrders = data);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Підтвердження'),
            content: Text(
              'Ви впевнені, що хочете змінити статус на "$status"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Скасувати'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Підтвердити'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8080/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Статус оновлено')));

        // Якщо статус — "прийнято", одразу створюємо ТТН
        if (status == 'прийнято') {
          await createTTN(orderId);
        }

        await _fetchIncomingOrders();
        setState(() {}); // це забезпечує повний перерендер
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка: ${response.body}')));
      }
    }
  }

  String _translateStatus(String rawStatus) {
    switch (rawStatus) {
      case 'в обробці':
        return 'очікує підтвердження';
      case 'прийнято':
        return 'прийнято';
      case 'відхилено':
        return 'відхилено';
      case 'скасований':
        return 'скасовано';
      default:
        return rawStatus;
    }
  }

  Future<void> createTTN(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/create-ttn'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'order_id': orderId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final ttn = data['ttn'];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ТТН створено: $ttn')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка: ${response.body}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Замовлення на мої товари')),
      body:
          incomingOrders.isEmpty
              ? const Center(child: Text('Немає замовлень на ваші товари.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: incomingOrders.length,
                itemBuilder: (context, index) {
                  final order = incomingOrders[index];
                  final item = order['items'][0];
                  final product = item['product'];
                  final user = order['user'];

                  final status = _translateStatus(order['status']);
                  final createdAt =
                      order['created_at']?.substring(0, 10) ?? '—';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Замовлення #${order['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (user != null && user['name'] != null)
                            Text('Замовник: ${user['name']}'),
                          Text('Товар: ${product['name']}'),
                          Text('Кількість: ${item['quantity']}'),
                          Text('Сума: ₴${order['total_price']}'),
                          Text('Тип оплати: ${order['payment_type']}'),
                          Text('Оплата: ${order['payment_status']}'),
                          Text('Статус: $status'),
                          Text('Адреса: ${order['shipping_address']}'),
                          Text('Дата: $createdAt'),
                          const SizedBox(height: 12),
                          if (order['status'] == 'в обробці' ||
                              order['status'] == 'прийнято')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (order['status'] == 'в обробці')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed:
                                        () => _updateOrderStatus(
                                          order['id'],
                                          'прийнято',
                                        ),
                                    child: const Text('Підтвердити'),
                                  ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed:
                                      () => _updateOrderStatus(
                                        order['id'],
                                        'відхилено',
                                      ),
                                  child: const Text('Відхилити'),
                                ),
                              ],
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
