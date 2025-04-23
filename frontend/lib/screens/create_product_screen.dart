import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toyshop/utils/shared_prefs.dart';
import 'dart:convert';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/categories'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      setState(() {
  _categories = data.map((e) => {
    'id': e['id'],
    'name': e['name'],
  }).toList();

  if (_categories.isNotEmpty) {
    _selectedCategory = _categories.first['id'].toString();
      }
  });


    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

Future<void> _submitProduct() async {
  if (_nameController.text.trim().isEmpty ||
    _descController.text.trim().isEmpty ||
    double.tryParse(_priceController.text) == null ||
    double.parse(_priceController.text) <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Заповніть всі поля та вкажіть коректну ціну')),
  );
  return;
}

  final token = await SharedPrefs.getToken(); // ✅ токен збережено при логіні
  if (token == null) {
    print('🔴 Токен відсутній');
    return;
  }

  final Map<String, dynamic> body = {
  'name': _nameController.text,
  'description': _descController.text,
  'price': double.tryParse(_priceController.text) ?? 0.0, // ← це надсилає як число
  'category_id': int.tryParse(_selectedCategory ?? '') ?? 0,
  'image_url': _imageFile?.path ?? '',
  };

  print('🟢 Дані для надсилання: ${jsonEncode(body)}');
  print('🔐 Токен: $token');

  final response = await http.post(
    Uri.parse('http://10.0.2.2:8080/products'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode == 201) {
    Navigator.pop(context);
  } else {
    print('🔴 Помилка: ${response.statusCode}');
    print('🔴 Відповідь: ${response.body}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Помилка при створенні товару')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новий товар')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Назва'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Опис'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ціна (грн)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                         value: _selectedCategory,
                         items: _categories
                             .map((cat) => DropdownMenuItem(
                                   value: cat['id'].toString(),
                                   child: Text(cat['name']),
                                 ))
                             .toList(),
                         onChanged: (val) => setState(() => _selectedCategory = val),
                         decoration: const InputDecoration(labelText: 'Категорія'),
                          ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Завантажити фото'),
            ),
            if (_imageFile != null) Image.file(_imageFile!, height: 150),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitProduct,
              child: const Text('Створити товар'),
            ),
          ],
        ),
      ),
    );
  }
}