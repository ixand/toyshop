import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SendTab extends StatefulWidget {
  const SendTab({super.key});

  @override
  State<SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<SendTab> {
  List<dynamic> sentOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchSentOrders();
  }

  Future<void> _fetchSentOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/my-incoming-orders'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        sentOrders =
            data
                .where(
                  (order) =>
                      order['status'] == 'прийнято' && order['ttn'] != null,
                )
                .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sentOrders.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: const Text(
          'Немає активних відправлень з ТТН.',
          style: TextStyle(color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sentOrders.length,
      itemBuilder: (context, index) {
        final order = sentOrders[index];
        final item = order['items'][0];
        final product = item['product'];
        final ttn = order['ttn'] ?? '—';

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
                  'Товар: ${product['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Сума: ₴${order['total_price']}'),
                Text('Тип оплати: ${order['payment_type']}'),
                Text('Оплата: ${order['payment_status']}'),
                Text('Статус: ${order['status']}'),
                const SizedBox(height: 8),
                Text(
                  'Номер ТТН: $ttn',
                  style: const TextStyle(color: Colors.deepPurple),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
