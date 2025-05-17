// Імпорти залишаються незмінними
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
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
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
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
        _locationController.text.trim().isEmpty ||
        double.tryParse(_priceController.text) == null ||
        int.tryParse(_quantityController.text) == null ||
        double.parse(_priceController.text) <= 0 ||
        int.parse(_quantityController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заповніть всі поля правильно')),
      );
      return;
    }

    final token = await SharedPrefs.getToken();
    if (token == null) {
      print('🔴 Токен відсутній');
      return;
    }

    String imageUrl = '';
    if (_imageFile != null) {
      imageUrl = await uploadImage(_imageFile!);
    }

    final Map<String, dynamic> body = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text),
      'stock_quantity': int.parse(_quantityController.text),
      'location': _locationController.text,
      'category_id': int.tryParse(_selectedCategory ?? '') ?? 0,
      'image_url': imageUrl,
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/products'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      print('🔴 Помилка: ${response.statusCode}');
      print('🔴 Відповідь: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Помилка при створенні товару')),
      );
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance.ref();
    final fileRef = storageRef.child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await fileRef.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
    return await fileRef.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 244, 255),
      appBar: AppBar(
        title: const Text('Новий товар'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(_nameController, 'Назва'),
            const SizedBox(height: 12),
            _buildTextField(_descController, 'Опис'),
            const SizedBox(height: 12),
            _buildTextField(_priceController, 'Ціна (грн)', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(_quantityController, 'Кількість', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(_locationController, 'Локація'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категорія',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat['id'].toString(),
                        child: Text(cat['name']),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 255, 165, 165)),
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Завантажити фото'),
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_imageFile!, height: 160, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 153, 255, 137),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Створити товар'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color.fromARGB(255, 203, 225, 252),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
