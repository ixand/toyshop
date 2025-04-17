import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

void _login() async {
  setState(() => _isLoading = true);

  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  print('▶️ Вхід натиснуто: $email | $password');

  final success = await ApiService.login(email, password);

  print('✅ Результат логіну: $success');

  setState(() => _isLoading = false);

  if (success) {
    print('➡️ Перехід на HomeScreen');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  } else {
    print('❌ Помилка логіну: невірні дані');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Помилка входу'),
        content: const Text('Неправильний email або пароль'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вхід')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Увійти'),
                  ),
          ],
        ),
      ),
    );
  }
}
