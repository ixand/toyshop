import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthorProfileScreen extends StatefulWidget {
  final int ownerId;

  const AuthorProfileScreen({super.key, required this.ownerId});

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen> {
  Map<String, dynamic>? _author;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchAuthor();
    _fetchReviews();
  }

  Future<void> _fetchAuthor() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/users'));
    if (response.statusCode == 200) {
      final users = jsonDecode(response.body) as List;
      final author = users.firstWhere(
        (u) => u['id'] == widget.ownerId,
        orElse: () => null,
      );
      if (author != null) {
        setState(() => _author = author);
      }
    }
  }

  Future<void> _fetchReviews() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/reviews/author/${widget.ownerId}'),
    );
    if (response.statusCode == 200) {
      setState(() => _reviews = jsonDecode(response.body));
    }
  }

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<int>(
      0,
      (sum, r) => sum + ((r['rating'] ?? 0) as int),
    );
    return total / _reviews.length;
  }

  String getBadge() {
    if (averageRating >= 4.5 && _reviews.length > 5)
      return '🥇 Продавець тижня';
    if (averageRating >= 4.0) return '🥈 Надійний продавець';
    return '🔰 Новачок';
  }

  List<Widget> buildStars(double rating) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return List.generate(5, (i) {
      if (i < full) {
        return const Icon(Icons.star, color: Colors.amber, size: 20);
      } else if (i == full && half) {
        return const Icon(Icons.star_half, color: Colors.amber, size: 20);
      }
      return const Icon(Icons.star_border, color: Colors.grey, size: 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _author?['name'] ?? 'Завантаження...';
    final created = _author?['created_at']?.substring(0, 10) ?? 'невідомо';

    return Scaffold(
      appBar: AppBar(title: const Text('Профіль продавця')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 12),
            Text('Ім’я: $name', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: buildStars(averageRating),
            ),
            const SizedBox(height: 6),
            Text('Бейджі: ${getBadge()}'),
            const SizedBox(height: 6),
            Text('На платформі з: $created'),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Відгуки:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  _reviews.isEmpty
                      ? const Center(child: Text('Відгуків ще немає'))
                      : ListView.builder(
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final r = _reviews[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.comment),
                              title: Text(r['comment'] ?? ''),
                              subtitle: Text(
                                'Користувач #${r['user_id']}, ${r['created_at']?.substring(0, 10) ?? ''}',
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
