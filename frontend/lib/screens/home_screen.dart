import 'package:flutter/material.dart';
import 'package:toyshop/screens/profile_screen.dart';
import 'package:toyshop/screens/messages_screen.dart';
import 'package:toyshop/screens/order_screen.dart';
import 'package:toyshop/screens/products_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ProductsScreen(),
    OrderScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _items = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_bag_outlined),
      label: 'Товари',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.view_list_outlined),
      label: 'Замовлення',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.message_outlined),
      label: 'Повідомлення',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профіль'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: _items,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
