// lib/screens/add_item_screen.dart

import 'dart:io';
import 'dart:convert'; // Although not used in the final version, kept for general utility
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:http/http.dart' as http; // Required for network uploads
import '../models/item_model.dart';

// ⭐️ USE YOUR CONFIRMED CLOUD NAME HERE
const String CLOUDINARY_CLOUD_NAME = 'dvdfvxphf'; 
const String CLOUDINARY_UPLOAD_PRESET = 'flutter_upload'; 
final String CLOUDINARY_URL = 'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload';

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
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // ⭐️ CRITICAL FIX: Uses MultipartRequest (Form-Data) matching the Postman test
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    if (CLOUDINARY_CLOUD_NAME == 'YOUR_CLOUDINARY_CLOUD_NAME') {
      print("ERROR: Cloudinary Cloud Name is not configured.");
      return null;
    }
    
    try {
      // 1. Create a Multipart Request
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse(CLOUDINARY_URL),
      );

      // 2. Attach the required upload_preset text field
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;
      
      // 3. Attach the file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // The field name must be 'file'
          imageFile.path,
        ),
      );

      // 4. Send the request and wait for the response stream
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 5. Check response status
      if (response.statusCode == 200) {
        print('Cloudinary: Multipart Upload successful!');
        final data = jsonDecode(response.body);
        return data['secure_url']; // Return the CDN link
      } else {
        // Log the full error response for diagnostics
        print('Cloudinary Error Status: ${response.statusCode}');
        print('Cloudinary Error Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('HTTP Upload Catch Error: $e');
      return null;
    }
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; 
    });

    String? imageUrl;
    
    try {
      if (_image != null) {
        imageUrl = await _uploadImageToCloudinary(_image!);
        
        if (imageUrl == null) {
          // Re-throw the custom exception for the user
          throw Exception("Image upload failed. See logs for API response.");
        }
      }

      final tokenCost = int.tryParse(_tokenCostController.text) ?? 0; 

      final newItem = Item(
        name: _nameController.text,
        description: _descController.text,
        tokenCost: tokenCost,
        imageUrl: imageUrl, 
      );

      // Save item details to Firestore
      await FirebaseFirestore.instance.collection('items').add(newItem.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newItem.name} added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save item: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                controller: _tokenCostController,
                decoration: const InputDecoration(labelText: 'Token Cost (in tokens)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter token cost';
                  if (int.tryParse(value) == null) return 'Please enter a whole number';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              
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
