import 'package:flutter/material.dart';

class AuthorProfileScreen extends StatelessWidget {
  final int ownerId;

  const AuthorProfileScreen({super.key, required this.ownerId});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with dynamic data
    return Scaffold(
      appBar: AppBar(title: const Text('Профіль продавця')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 12),
            const Text('Ім’я: haha', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            const Text('Рейтинг: ⭐️⭐️⭐️⭐️☆'),
            const SizedBox(height: 6),
            const Text('Бейджі: 🥇 Продавець тижня'),
            const SizedBox(height: 6),
            const Text('На платформі з: 2024-11-03'),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Відгуки:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.comment),
                    title: Text('Дуже задоволений покупкою!'),
                    subtitle: Text('Іван, 2025-05-01'),
                  ),
                  ListTile(
                    leading: Icon(Icons.comment),
                    title: Text('Опис відповідає, рекомендую.'),
                    subtitle: Text('Оля, 2025-04-20'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
