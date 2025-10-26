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
import 'package:geolocator/geolocator.dart'; 
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
  final _locationController = TextEditingController(); 

  File? _imageFile;
  Uint8List? _webImage;
  bool _isLoading = false;
  bool _isLocating = false; 
  
  double _currentLatitude = 0.0; 
  double _currentLongitude = 0.0; 

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
  
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable them.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _locationController.text = 'Lat: ${_currentLatitude.toStringAsFixed(4)}, Long: ${_currentLongitude.toStringAsFixed(4)}';
      });

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      
      setState(() {
        _currentLatitude = 0.0;
        _currentLongitude = 0.0;
      });

    } finally {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _saveItem() async {
    if (_currentLatitude == 0.0 && _currentLongitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap "Get Location" first to set the item pickup spot.')),
      );
      return;
    }

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
        location: _locationController.text,
        latitude: _currentLatitude, 
        longitude: _currentLongitude, 
      );

      final docRef = await FirebaseFirestore.instance.collection('items').add(newItem.toMap());

      await FirebaseFirestore.instance.collection('notifications').add({
        'message': 'New item uploaded: ${newItem.name}',
        'itemId': docRef.id,
        'timestamp': FieldValue.serverTimestamp(),
      });

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
    _locationController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)), 
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      labelStyle: TextStyle(color: Colors.black54),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Text('Item Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(labelText: 'Item Name'),
                validator: (value) => value!.isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                decoration: inputDecoration.copyWith(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _tokenCostController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Token Cost',
                  prefixIcon: const Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter token cost';
                  if (int.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              
              const SizedBox(height: 30),
              const Divider(color: Colors.black12),
              const SizedBox(height: 20),

              Text('Location Tagging', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Pick-up Location Name',
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a location name' : null,
                      readOnly: _isLocating,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isLocating ? null : _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLocating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location), 
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              const Divider(color: Colors.black12),
              const SizedBox(height: 20),

              Text('Item Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              const SizedBox(height: 15),
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: _imageFile == null && _webImage == null
                          ? const Center(child: Text('No image selected.', style: TextStyle(color: Colors.grey)))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.memory(_webImage!, fit: BoxFit.cover)
                                  : Image.file(_imageFile!, fit: BoxFit.cover),
                            ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Upload Image'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isLoading || _isLocating ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.green.shade600, // Use a clear success color
                  foregroundColor: Colors.white, 
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Save Item',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}