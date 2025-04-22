import 'package:flutter/material.dart';
import 'package:toyshop/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> user = {
    'name': '',
    'email': '',
    'registered': '',
    'avatar': null,
  };

  String formattedDate = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);    
      print('Отримані дані: $data');
      final reg = data['created_at']?.substring(0, 10) ?? '';

      setState(() {
        user['name'] = data['name'] ?? '';
        user['email'] = data['email'] ?? '';
        user['registered'] = reg;
        formattedDate = reg;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профіль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user['avatar'] != null
                        ? NetworkImage(user['avatar']!)
                        : const AssetImage('assets/user_default.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () {
                          // Додати зміну аватарки
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileField('Імʼя', user['name'] ?? ''),
            const SizedBox(height: 12),
            _buildProfileField('Email', user['email'] ?? ''),
            const SizedBox(height: 12),
            _buildProfileField('Дата реєстрації', formattedDate),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Бейджі та досягнення', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 8),
                Text('Перший вхід у додаток')
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
             onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Вийти з акаунту'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
                ),
            ),
          ],
        ),
      ),
      
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
    void _logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
    }

  
}
