import 'package:flutter/material.dart';
import 'send_tab.dart';
import 'receive_tab.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [SendTab(), ReceiveTab()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Логістика')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Відправка'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Доставка',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
