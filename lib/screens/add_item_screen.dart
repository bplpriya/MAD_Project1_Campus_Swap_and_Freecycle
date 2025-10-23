// lib/screens/add_item_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/item_model.dart';

// Cloudinary config
const String CLOUDINARY_CLOUD_NAME = 'dvdfvxphf';
const String CLOUDINARY_UPLOAD_PRESET = 'flutter_upload';
final String CLOUDINARY_URL =
    'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _tokenCostController = TextEditingController();

  File? _imageFile;
  Uint8List? _webImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _webImage = bytes);
    } else {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(CLOUDINARY_URL));
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;

      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _webImage!,
            filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else if (!kIsWeb && _imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));
      } else {
        return null;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['secure_url'];
      } else {
        print('Cloudinary Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = await _uploadImageToCloudinary();
      final tokenCost = int.tryParse(_tokenCostController.text) ?? 0;

      final newItem = Item(
        name: _nameController.text,
        description: _descController.text,
        tokenCost: tokenCost,
        imageUrl: imageUrl,
        sellerId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      await FirebaseFirestore.instance.collection('items').add(newItem.toMap());

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${newItem.name} added successfully!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tokenCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
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
                validator: (value) => value!.isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tokenCostController,
                decoration: const InputDecoration(labelText: 'Token Cost'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter token cost';
                  if (int.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    _imageFile == null && _webImage == null
                        ? const Text('No image selected.')
                        : kIsWeb
                            ? Image.memory(_webImage!, height: 150, fit: BoxFit.cover)
                            : Image.file(_imageFile!, height: 150, fit: BoxFit.cover),
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
                  onPressed: _isLoading ? null : _saveItem,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
