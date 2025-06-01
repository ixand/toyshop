import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StripeService {
  static Future<void> makeTestPayment(BuildContext context, int amount) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': amount}),
    );

    final jsonResponse = jsonDecode(response.body);
    final clientSecret = jsonResponse['clientSecret'];

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'ToyShop',
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.post(
      Uri.parse('http://10.0.2.2:8080/payment-success'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'amount': amount}),
    );
  }
}
