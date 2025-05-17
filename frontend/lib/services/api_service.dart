import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080'; 

  // у api_service.dart
  static Future<Map<String, dynamic>?> login(String email, String password) async {
  final url = Uri.parse('$baseUrl/login');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    // 🔴 Лог помилки
    print('🔴 Login error: ${response.statusCode} - ${response.body}');
    return null;
  }
}



  static Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('🔴 Реєстрація не вдалася: ${response.body}');
      return false;
    }
  }

  static Future<List<dynamic>> fetchProducts() async {
  final url = Uri.parse('$baseUrl/products');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Не вдалося завантажити товари');
  }
}

}
