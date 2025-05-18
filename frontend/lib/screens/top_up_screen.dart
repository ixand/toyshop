import 'package:flutter/material.dart';
import '../services/stripe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController(text: '50');

  Future<void> _updateBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Оновлений баланс: ${data['balance']}");
    }
  }

  Future<void> _processPayment(int amount) async {
    if (amount < 25) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Мінімальна сума поповнення — 25 грн')),
      );
      return;
    }

    try {
      await StripeService.makeTestPayment(context, amount * 100);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Поповнення успішне")),
      );
      await _updateBalance();
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (e.toString().contains('FailureCode.Canceled')) {
        // Тихо ігноруємо вихід користувача з платіжного вікна
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Помилка: $e")),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поповнення балансу')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Введіть суму для поповнення:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Сума (мін. 25 грн)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('₴', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        final amount = int.tryParse(_amountController.text) ?? 0;
                        _processPayment(amount);
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Оплатити'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'Швидке поповнення:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.6,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [100, 200, 500, 1000].map((amount) {
              return ElevatedButton(
                onPressed: () => _processPayment(amount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text('₴$amount'),
              );
            }).toList(),
          ),

          ],
        ),
      ),
    );
  }
}
