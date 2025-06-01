// імпорти як у тебе
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;

  // Змінні для помилок
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _termsError;

  void _register() async {
    // Очищуємо попередні помилки
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _termsError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    bool hasErrors = false;

    // Перевірка імені
    if (name.isEmpty) {
      _nameError = 'Поле не може бути пустим';
      hasErrors = true;
    }

    // Перевірка email
    if (email.isEmpty) {
      _emailError = 'Поле не може бути пустим';
      hasErrors = true;
    } else {
      final emailRegex = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w{2,}$");
      if (!emailRegex.hasMatch(email)) {
        _emailError = 'Введіть дійсну email-адресу';
        hasErrors = true;
      }
    }

    // Перевірка телефону
    if (phone.isEmpty) {
      _phoneError = 'Поле не може бути пустим';
      hasErrors = true;
    } else {
      final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
      if (!phoneRegex.hasMatch(phone)) {
        _phoneError = 'Введіть коректний номер телефону';
        hasErrors = true;
      }
    }

    // Перевірка пароля
    if (password.isEmpty) {
      _passwordError = 'Поле не може бути пустим';
      hasErrors = true;
    } else if (password.length < 6) {
      _passwordError = 'Пароль має містити мінімум 6 символів';
      hasErrors = true;
    }

    // Перевірка умов використання
    if (!_acceptTerms) {
      _termsError = 'Ви повинні прийняти умови використання';
      hasErrors = true;
    }

    if (hasErrors) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.register(name, email, password, phone);
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Реєстрація успішна!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Реєстрація не вдалася. Можливо, email або номер телефону вже використовується.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTermsOfUse() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Умови використання'),
            content: const SingleChildScrollView(
              child: Text(
                'Тут розміщені умови використання додатку Toyshop App.\n\n'
                '1. Використовуючи цей додаток, ви погоджуєтесь з усіма умовами.\n'
                '2. Ваші персональні дані будуть захищені відповідно до політики конфіденційності.\n'
                '3. Заборонено використовувати додаток для незаконних дій.\n'
                '4. Адміністрація залишає за собою право змінювати умови використання.\n'
                '5. Ми лише показуємо товари. За якість, доставку та проблеми відповідають продавці, не розробники.\n\n'
                'Для отримання повної версії умов використання, будь ласка, зверніться до служби підтримки.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрити'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.person_add_alt_1, size: 72, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text(
              'Створити акаунт',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),
            // Поле імені
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Імʼя',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _nameError != null ? Colors.red : Colors.blue,
                  ),
                ),
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            // Поле email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _emailError != null ? Colors.red : Colors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _emailError != null ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _emailError != null ? Colors.red : Colors.blue,
                  ),
                ),
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 16),
            // Поле телефону
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _phoneError != null ? Colors.red : Colors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _phoneError != null ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _phoneError != null ? Colors.red : Colors.blue,
                  ),
                ),
                errorText: _phoneError,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            // Поле пароля
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _passwordError != null ? Colors.red : Colors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _passwordError != null ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _passwordError != null ? Colors.red : Colors.blue,
                  ),
                ),
                errorText: _passwordError,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            // Галочка для прийняття умов використання
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                          if (_acceptTerms) _termsError = null;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                            if (_acceptTerms) _termsError = null;
                          });
                        },
                        child: const Text(
                          'Я приймаю умови використання',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _showTermsOfUse,
                      child: const Text(
                        'Переглянути',
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_termsError != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      _termsError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Зареєструватись'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: _register,
                ),
          ],
        ),
      ),
    );
  }
}
