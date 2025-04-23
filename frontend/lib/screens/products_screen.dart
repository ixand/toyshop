import 'package:flutter/material.dart';
import 'package:toyshop/services/api_service.dart';
import 'package:toyshop/screens/create_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  String _searchTerm = '';
  String _sortOption = 'name';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await ApiService.fetchProducts();
    setState(() {
      _allProducts = products;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<dynamic> results = _allProducts;

    // Пошук
    if (_searchTerm.isNotEmpty) {
      results = results.where((p) =>
          (p['name'] ?? '').toLowerCase().contains(_searchTerm.toLowerCase())).toList();
    }

    // Сортування
    if (_sortOption == 'name') {
      results.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_sortOption == 'price') {
      results.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
    }

    setState(() {
      _filteredProducts = results;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Фільтри'),
        content: const Text('(приклад) Тут буде фільтр за категоріями'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрити'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Товари')),
              floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateProductScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                  _applyFilters();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Пошук товару...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _sortOption,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('За назвою')),
                    DropdownMenuItem(value: 'price', child: Text('За ціною')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOption = value;
                        _applyFilters();
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('Немає товарів'))
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ListTile(
                        leading: const Icon(Icons.toys),
                        title: Text(product['name'] ?? 'Без назви'),
                        subtitle: Text('${product['price']} грн'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}