import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/my_products_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toyshop App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      routes: {
            '/my-products': (context) => const MyProductsScreen(),
          },

    );
  }
}
