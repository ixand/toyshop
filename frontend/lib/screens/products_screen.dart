import 'package:flutter/material.dart';
import 'package:toyshop/services/api_service.dart';
import 'package:toyshop/screens/create_product_screen.dart';
import 'package:toyshop/screens/product_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  List<String> _selectedFilters = []; // обрані категорії
  List<Map<String, dynamic>> _allCategories = [];
  List<dynamic> _products = [];
  String _searchTerm = '';
  String _sortOption = 'name';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
  }

  Future<void> _loadProducts() async {
    final products = await ApiService.fetchProducts();
    setState(() {
      _allProducts = products;
      _applyFilters();
    });
  }

  Future<void> _fetchCategories() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/categories'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _allCategories =
            data.map((e) => {'id': e['id'], 'name': e['name']}).toList();
      });
    }
  }

  Future<void> _fetchProducts() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/products/active'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _allProducts = data;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    List<dynamic> results = _allProducts;

    // Пошук
    if (_searchTerm.isNotEmpty) {
      results =
          results
              .where(
                (p) => (p['name'] ?? '').toLowerCase().contains(
                  _searchTerm.toLowerCase(),
                ),
              )
              .toList();
    }

    // Фільтрація за категоріями
    if (_selectedFilters.isNotEmpty) {
      // знайти category_id для кожної назви
      final filteredCategoryIds =
          _allCategories
              .where((cat) => _selectedFilters.contains(cat['name']))
              .map((cat) => cat['id'])
              .toList();

      results =
          results
              .where((p) => filteredCategoryIds.contains(p['category_id']))
              .toList();
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
      builder: (_) {
        // копія обраних фільтрів для тимчасового вибору
        final selectedCategories = Set<String>.from(_selectedFilters);

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Фільтрувати за категоріями'),
                content: SingleChildScrollView(
                  child: Column(
                    children:
                        _allCategories.map((category) {
                          final name = category['name'];
                          return CheckboxListTile(
                            value: selectedCategories.contains(name),
                            title: Text(name),
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  selectedCategories.add(name);
                                } else {
                                  selectedCategories.remove(name);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilters.clear(); // очищаємо обрані фільтри
                      });
                      Navigator.pop(context);
                      _applyFilters(); // оновлюємо список після скидання
                    },
                    child: const Text('Скинути'),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilters = selectedCategories.toList();
                      });
                      Navigator.pop(context);
                      _applyFilters(); // оновити список товарів
                    },
                    child: const Text('Застосувати'),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Товари')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductScreen()),
          );

          if (result == true) {
            await _loadProducts();
          }
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
            child:
                _filteredProducts.isEmpty
                    ? const Center(child: Text('Немає товарів'))
                    : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  // Картинка
                                  product['image_url'] != null &&
                                          product['image_url']
                                              .toString()
                                              .isNotEmpty
                                      ? Image.network(
                                        product['image_url'],
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Image.asset(
                                            'assets/images/placeholder.png',
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                      : Image.asset(
                                        'assets/images/placeholder.png',
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                                  const SizedBox(width: 12),
                                  // Інформація
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? 'Без назви',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${product['price']} грн',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        if (product['owner_name'] != null)
                                          Text(
                                            'Автор: ${product['owner_name']}',
                                          ),
                                        if (product['created_at'] != null)
                                          Text(
                                            'Додано: ${product['created_at'].substring(0, 10)}',
                                          ),
                                        if (product['location'] != null)
                                          Text(
                                            'Локація: ${product['location']}',
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
