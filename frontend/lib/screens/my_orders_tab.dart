import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toyshop/screens/delivery_screen.dart';
import 'package:toyshop/screens/order_detail_screen.dart';
import 'dart:convert';

import 'package:toyshop/screens/top_up_screen.dart';

class MyOrdersTab extends StatefulWidget {
  const MyOrdersTab({super.key});

  @override
  State<MyOrdersTab> createState() => _MyOrdersTabState();
}

class _MyOrdersTabState extends State<MyOrdersTab> {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Замовлення скасовано')));
    }
  }

  Future<void> _payForOrder(dynamic order) async {
    final token = await _getToken();
    if (token == null) return;

    // Отримуємо баланс користувача
    final userRes = await http.get(
      Uri.parse('http://10.0.2.2:8080/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (userRes.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Помилка при перевірці балансу')),
      );
      return;
    }

    final user = jsonDecode(userRes.body);
    final double balance = user['balance']?.toDouble() ?? 0.0;
    final double total = order['total_price']?.toDouble() ?? 0.0;

    final canPay = balance >= total;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Підтвердження оплати'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сума до списання: ₴${total.toStringAsFixed(2)}'),
                Text('Ваш баланс: ₴${balance.toStringAsFixed(2)}'),
                if (!canPay)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Недостатньо коштів. Поповніть баланс.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Скасувати'),
              ),
              if (canPay)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final payRes = await http.post(
                      Uri.parse(
                        'http://10.0.2.2:8080/orders/${order['id']}/pay',
                      ),
                      headers: {'Authorization': 'Bearer $token'},
                    );

                    if (payRes.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Оплата успішна!')),
                      );
                      await _fetchOrders();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeliveryScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Не вдалося оплатити')),
                      );
                    }
                  },
                  child: const Text('Підтвердити'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TopUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Поповнити'),
                ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мої замовлення')),
      body:
          orders.isEmpty
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

    final String rawStatus = order['status'] ?? '';
    final String displayStatus =
        {
          'активно': 'прийнято',
          'неактивно': 'відхилено',
          'в обробці': 'очікує підтвердження',
        }[rawStatus] ??
        rawStatus;

    final isCanceled = rawStatus == 'скасований';
    final isAccepted = rawStatus == 'активно';
    final isPaid = order['payment_status'] == 'оплачено';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        product['image_url'] != null &&
                                product['image_url'].toString().isNotEmpty
                            ? Image.network(
                              product['image_url'],
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            )
                            : Image.asset(
                              'assets/images/placeholder.png',
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Кількість: ${item['quantity']}'),
                        Text('Сума: ₴${order['total_price']}'),
                        Text('Тип оплати: ${order['payment_type']}'),
                        Text('Оплата: ${order['payment_status']}'),
                        Text('Статус: $displayStatus'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isPaid &&
                      !isCanceled &&
                      order['payment_type'] == 'Онлайн')
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
                    onPressed:
                        (rawStatus == 'в обробці')
                            ? () {
                              showDialog(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text(
                                        'Підтвердження скасування',
                                      ),
                                      content: const Text(
                                        'Ви впевнені, що хочете скасувати це замовлення?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('Скасувати'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _cancelOrder(order['id']);
                                          },
                                          child: const Text('Підтвердити'),
                                        ),
                                      ],
                                    ),
                              );
                            }
                            : null,
                    child: Text(
                      isCanceled ? 'Скасовано' : 'Скасувати',
                      style: TextStyle(
                        color:
                            rawStatus == 'в обробці'
                                ? Colors.redAccent
                                : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
