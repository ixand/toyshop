import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toyshop/utils/shared_prefs.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  File? _imageFile;
  String? _initialImageUrl;
  int? _productId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _productId = args['id'];
    _nameController.text = args['name'];
    _descController.text = args['description'] ?? '';
    _priceController.text = args['price'].toString();
    _locationController.text = args['location'] ?? '';
    _selectedCategory = args['category_id'].toString();
    _initialImageUrl = args['image_url'];
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

  Future<void> _submitUpdate() async {
    if (_nameController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        double.tryParse(_priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, заповніть всі поля')),
      );
      return;
    }

    final token = await SharedPrefs.getToken();
    if (token == null || _productId == null) return;

    String imageUrl = _initialImageUrl ?? '';
    if (_imageFile != null) {
      imageUrl = await uploadImage(_imageFile!);
    }

    final Map<String, dynamic> body = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'location': _locationController.text,
      'category_id': int.tryParse(_selectedCategory ?? '') ?? 0,
      'image_url': imageUrl,
    };

    final response = await http.put(
      Uri.parse('http://10.0.2.2:8080/products/$_productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося оновити товар')),
      );
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imagesRef = storageRef.child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final uploadTask = imagesRef.putFile(imageFile, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редагування товару')),
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
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Локація'),
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
              label: const Text('Оновити фото'),
            ),
            if (_imageFile != null)
              Image.file(_imageFile!, height: 150)
            else if (_initialImageUrl != null)
              Image.network(_initialImageUrl!, height: 150),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitUpdate,
              child: const Text('Зберегти зміни'),
            ),
          ],
        ),
      ),
    );
  }
}
