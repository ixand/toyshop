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
    return ListTile(
        leading: const Icon(Icons.receipt),
        title: Text('Замовлення #${order['id']}'),
        subtitle: Text('Статус: ${order['status']}'),
        trailing: order['status'] != 'скасований'
      ? IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red),
          onPressed: () => _cancelOrder(order['id']),
        )
      : null, // ховає кнопку
        );
      },
    ),
   );
  }
}
