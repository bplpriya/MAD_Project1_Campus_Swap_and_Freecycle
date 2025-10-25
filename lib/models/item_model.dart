// lib/models/item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final int tokenCost;
  final String? imageUrl;
  final String condition;
  final String sellerId;
  final String location;
  final double latitude;
  final double longitude;
  final int flagCount;
  final String status; // NEW: Available/Sold

  Item({
    this.id = '',
    required this.name,
    required this.description,
    required this.tokenCost,
    this.imageUrl,
    this.condition = 'New',
    this.sellerId = '',
    this.location = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.flagCount = 0,
    this.status = 'Available', // default status
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'tokenCost': tokenCost,
      'imageUrl': imageUrl,
      'condition': condition,
      'sellerId': sellerId,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'flagCount': flagCount,
      'status': status, // added to map
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Item.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Document data is null");

    return Item(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      tokenCost: (data['tokenCost'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
      condition: data['condition'] ?? 'New',
      sellerId: data['sellerId'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      flagCount: (data['flagCount'] as int?) ?? 0,
      status: data['status'] ?? 'Available', // retrieve status
    );
  }
}
