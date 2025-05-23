import 'package:flutter/material.dart';
import 'package:toyshop/screens/location_picker_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderConfirmScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const OrderConfirmScreen({super.key, required this.product});

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen> {
  int _quantity = 1;
  String _selectedPayment = 'Онлайн';
  final _addressController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final stock = widget.product['stock_quantity'] ?? 1;
    final price = widget.product['price'] ?? 0;
    final total = _quantity * price;

    return Scaffold(
      appBar: AppBar(title: const Text('Підтвердження замовлення')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                if (widget.product['image_url'] != null &&
                    widget.product['image_url'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.product['image_url'],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${price.toStringAsFixed(2)} грн / од.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(_firstNameController, 'Імʼя'),
            const SizedBox(height: 10),
            _buildTextField(_lastNameController, 'Прізвище'),
            const SizedBox(height: 10),
            _buildTextField(_middleNameController, 'По батькові'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Кількість:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _quantity,
                  onChanged: (val) => setState(() => _quantity = val!),
                  items: List.generate(
                    stock,
                    (i) =>
                        DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              readOnly: true,
              onTap: _selectAddress,
              decoration: const InputDecoration(
                labelText: 'Адреса доставки',
                suffixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPayment,
              decoration: const InputDecoration(
                labelText: 'Тип оплати',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Онлайн', child: Text('Онлайн')),
                DropdownMenuItem(
                  value: 'Післяплата',
                  child: Text('Післяплата'),
                ),
              ],
              onChanged: (val) => setState(() => _selectedPayment = val!),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'До сплати: $total грн',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: _confirmOrder,
                  child: const Text('Підтвердити'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null && result['address'] != null) {
      setState(() {
        _addressController.text = result['address'];
      });
    }
  }

  Future<void> _confirmOrder() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _middleNameController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, заповніть усі поля')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Користувач не авторизований')),
      );
      return;
    }

    final body = {
      'shipping_address': _addressController.text,
      'payment_type': _selectedPayment,
      'items': [
        {'product_id': widget.product['id'], 'quantity': _quantity},
      ],
      'recipient_first_name': _firstNameController.text,
      'recipient_last_name': _lastNameController.text,
      'recipient_middle_name': _middleNameController.text,
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Замовлення створено')));
      Navigator.pop(context);
    } else {
      final error = jsonDecode(response.body)['error'] ?? 'Помилка';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не вдалося створити замовлення: $error')),
      );
    }
  }
}
