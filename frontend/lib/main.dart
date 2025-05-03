import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/my_products_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
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
