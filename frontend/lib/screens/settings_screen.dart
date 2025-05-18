import 'package:flutter/material.dart';
import 'package:toyshop/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkTheme = false;
  String currentLanguage = 'ua';

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Тема', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Темна тема'),
            value: isDarkTheme,
            onChanged: (value) {
              setState(() {
                isDarkTheme = value;
                // TODO: застосувати зміну теми глобально
              });
            },
          ),
          const SizedBox(height: 24),

          const Text('Мова', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('Українська'),
            leading: Radio<String>(
              value: 'ua',
              groupValue: currentLanguage,
              onChanged: (value) {
                setState(() {
                  currentLanguage = value!;
                  // TODO: застосувати локалізацію
                });
              },
            ),
          ),
          ListTile(
            title: const Text('English'),
            leading: Radio<String>(
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) {
                setState(() {
                  currentLanguage = value!;
                });
              },
            ),
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
    );
  }
}
