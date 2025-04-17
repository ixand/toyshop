import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  static Future<bool> login(String email, String password) async {
  print('📡 Надсилаємо POST /login');

  final url = Uri.parse('$baseUrl/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('📥 Отримано статус: ${response.statusCode}');
    print('📥 Тіло відповіді: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      print('🔐 Токен збережено');
      return true;
    } else {
      print('⚠️ Сервер повернув помилку: ${response.body}');
      return false;
    }
  } catch (e) {
    print('💥 Помилка запиту: $e');
    return false;
  }
  }
}