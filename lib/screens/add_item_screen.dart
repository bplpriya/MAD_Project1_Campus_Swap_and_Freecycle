// lib/screens/add_item_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item_model.dart'; // UPDATED PATH

class AddItemScreen extends StatefulWidget {
  // Callback function to send the new Item back to the listing screen
  final Function(Item) onSave; 
  
  const AddItemScreen({super.key, required this.onSave});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    // Note: For production-grade cross-platform apps (especially web),
    // you would need different logic, as dart:io.File is not supported
    // on all platforms.
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final description = _descController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0; 

      final newItem = Item(
        name: name,
        description: description,
        price: price,
        image: _image,
      );

      // Call the callback to pass the new item back to the ItemListingsScreen
      widget.onSave(newItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newItem.name} added successfully!')),
      );
      Navigator.pop(context); // Go back to item list
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter price';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    _image == null
                        ? const Text('No image selected.')
                        : Image.file(
                            _image!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _saveItem,
                  child: const Text('Save Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}