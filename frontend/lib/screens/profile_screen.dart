import 'package:flutter/material.dart';
import 'package:toyshop/screens/login_screen.dart';
import 'package:toyshop/screens/top_up_screen.dart';
import 'package:toyshop/screens/settings_screen.dart';
import 'package:toyshop/screens/delivery_screen.dart';
import '../services/stripe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    'balance': 0.0,
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
      final reg = data['created_at']?.substring(0, 10) ?? '';

      setState(() {
        user['name'] = data['name'] ?? '';
        user['email'] = data['email'] ?? '';
        user['registered'] = reg;
        user['balance'] = data['balance'] ?? 0.0;
        formattedDate = reg;
      });
    }
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

  Widget _buildProfileField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
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
                          // логіка зміни аватарки
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileField('Імʼя', user['name']),
            const SizedBox(height: 12),
            _buildProfileField('Email', user['email']),
            const SizedBox(height: 12),
            _buildProfileField('Дата реєстрації', formattedDate),
            const SizedBox(height: 12),
            _buildProfileField('Баланс', '${user['balance'].toStringAsFixed(2)} ₴'),

            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Бейджі та досягнення',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Досягнення'),
                      content: const Text('Цей бейдж ви отримали за перший вхід у додаток.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Закрити'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events, color: Colors.amber),
                ),
              ),
            ),




            const SizedBox(height: 32),

            /// 2x2 кнопки у Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionButton(
                  icon: Icons.list,
                  label: 'Мої оголошення',
                  color: Colors.deepPurple,
                  onTap: () => Navigator.pushNamed(context, '/my-products'),
                ),
               _buildActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Поповнити',
                color: Colors.purple,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TopUpScreen()),
                  );

                  if (result == true) {
                    _fetchUserProfile(); // оновлення балансу після повернення
                    }
                  },
                ),

                _buildActionButton(
                icon: Icons.local_shipping,
                label: 'Логістика',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeliveryScreen()),
                  );
                },
              ),

                _buildActionButton(
                icon: Icons.settings,
                label: 'Налаштування',
                color: Colors.grey.shade800,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
