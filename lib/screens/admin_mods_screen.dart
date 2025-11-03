import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mod_item.dart';
import '../services/db_service.dart';

class AdminModsScreen extends StatefulWidget {
  const AdminModsScreen({super.key});

  @override
  _AdminModsScreenState createState() => _AdminModsScreenState();
}

class _AdminModsScreenState extends State<AdminModsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _aboutController = TextEditingController();
  final _screenshotUrlController = TextEditingController();
  final _downloadUrlController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  String? _selectedCategory;
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture =
        Provider.of<DBService>(context, listen: false).listCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Add Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _aboutController,
                decoration: const InputDecoration(labelText: 'About'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _screenshotUrlController,
                decoration: const InputDecoration(labelText: 'Screenshot URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a screenshot URL';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _downloadUrlController,
                decoration: const InputDecoration(labelText: 'Download URL'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a download URL';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (coins)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      int.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              FutureBuilder<List<String>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final categories = snapshot.data!;
                  if (categories.isEmpty) {
                    return const Text('Please add categories first.');
                  }
                  if (_selectedCategory == null && categories.isNotEmpty) {
                    _selectedCategory = categories.first;
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories
                        .map((label) => DropdownMenuItem(
                              child: Text(label),
                              value: label,
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveItem,
                child: const Text('Save Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem() {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final db = Provider.of<DBService>(context, listen: false);
      final newItem = ModItem(
        title: _titleController.text,
        about: _aboutController.text,
        category: _selectedCategory!,
        screenshots: [_screenshotUrlController.text],
        fileUrl: _downloadUrlController.text,
        price: int.parse(_priceController.text),
      );
      db.createMod(newItem).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully')),
        );
        _formKey.currentState!.reset();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save item: $error')),
        );
      });
    }
  }
}
