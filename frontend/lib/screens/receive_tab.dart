import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReceiveTab extends StatefulWidget {
  const ReceiveTab({super.key});

  @override
  State<ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends State<ReceiveTab> {
  List<dynamic> deliveries = [];

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/my-deliveries'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() => deliveries = jsonDecode(response.body));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка: ${response.body}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child:
          deliveries.isEmpty
              ? const Center(
                child: Text(
                  'Наразі немає активних доставок.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final delivery = deliveries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text('ТТН: ${delivery['ttn'] ?? '—'}'),
                      subtitle: Text(
                        'Статус: ${delivery['status'] ?? 'Невідомо'}',
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
