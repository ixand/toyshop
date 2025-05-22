import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toyshop/utils/shared_prefs.dart';
import 'package:toyshop/screens/location_picker_screen.dart';

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
  final _quantityController = TextEditingController();

  bool _wasUpdated = false;

  String? _selectedCategory;
  String? _status;
  List<Map<String, dynamic>> _categories = [];
  File? _imageFile;
  String? _initialImageUrl;
  int? _productId;

  late Map<String, dynamic> _initialValues;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

      setState(() {
        _productId = args['id'];
        _nameController.text = args['name'];
        _descController.text = args['description'] ?? '';
        _priceController.text = args['price'].toString();
        _locationController.text = args['location'] ?? '';
        _quantityController.text = args['stock_quantity']?.toString() ?? '1';
        _selectedCategory = args['category_id'].toString();
        _status = args['status'];
        _initialImageUrl = args['image_url'];

        _initialValues = {
          'name': _nameController.text,
          'description': _descController.text,
          'price': _priceController.text,
          'location': _locationController.text,
          'stock_quantity': _quantityController.text,
          'category_id': _selectedCategory,
          'image_url': _initialImageUrl,
          'status': _status,
        };
      });

      _fetchCategories();
    });
  }

  Future<void> _fetchCategories() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/categories'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _categories =
            data.map((e) => {'id': e['id'], 'name': e['name']}).toList();
      });
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance.ref();
    final imagesRef = storageRef.child(
      'product_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final uploadTask = imagesRef.putFile(imageFile, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null && result['address'] != null) {
      _locationController.text = result['address'];
    }
  }

  Future<void> _submitUpdate() async {
    if (_nameController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        double.tryParse(_priceController.text) == null ||
        int.tryParse(_quantityController.text) == null) {
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

    final Map<String, dynamic> newValues = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': _priceController.text,
      'location': _locationController.text,
      'stock_quantity': _quantityController.text,
      'category_id': _selectedCategory,
      'image_url': imageUrl,
    };

    bool hasChanges = false;
    for (final key in newValues.keys) {
      if (newValues[key]?.toString() != _initialValues[key]?.toString()) {
        hasChanges = true;
        break;
      }
    }

    String finalStatus = _status ?? 'active';
    if (_status == 'active' && hasChanges) {
      finalStatus = 'pending';
    }

    final Map<String, dynamic> body = {
      ...newValues,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'category_id': int.tryParse(_selectedCategory ?? '') ?? 0,
      'stock_quantity': int.tryParse(_quantityController.text) ?? 0,
      'status': finalStatus,
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
      _wasUpdated = true;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не вдалося оновити товар')));
    }
  }

  Future<void> _toggleStatus() async {
    if (_status != 'active' && _status != 'inactive') return;

    final newStatus = _status == 'active' ? 'inactive' : 'pending';
    final token = await SharedPrefs.getToken();
    if (token == null || _productId == null) return;

    final response = await http.put(
      Uri.parse('http://10.0.2.2:8080/products/$_productId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _status = newStatus;
        _initialValues['status'] = newStatus;
        _wasUpdated = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус змінено на ${_mapStatusToUkr(newStatus)}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося змінити статус')),
      );
    }
  }

  String _mapStatusToUkr(String status) {
    switch (status) {
      case 'active':
        return 'Активний';
      case 'inactive':
        return 'Неактивний';
      case 'pending':
        return 'Очікується';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _wasUpdated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Редагування товару')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Кількість'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                readOnly: true,
                onTap: _selectLocation,
                decoration: const InputDecoration(
                  labelText: 'Локація (оберіть на мапі)',
                  suffixIcon: Icon(Icons.map),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items:
                    _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat['id'].toString(),
                        child: Text(cat['name']),
                      );
                    }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: const InputDecoration(labelText: 'Категорія'),
              ),
              const SizedBox(height: 12),
              if (_status == 'active' || _status == 'inactive')
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _toggleStatus,
                    icon: const Icon(Icons.toggle_on),
                    label: Text(
                      _status == 'active' ? 'Деактивувати' : 'Активувати',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _status == 'active' ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Оновити фото'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child:
                    _imageFile != null
                        ? Image.file(_imageFile!, height: 150)
                        : (_initialImageUrl != null &&
                            _initialImageUrl!.isNotEmpty)
                        ? Image.network(_initialImageUrl!, height: 150)
                        : Image.asset(
                          'assets/images/placeholder.png',
                          height: 150,
                        ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _submitUpdate,
                  child: const Text('Зберегти зміни'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
