// lib/models/item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final int tokenCost;      // Field is correct
  final String? imageUrl; 

  Item({
    this.id = '',
    required this.name,
    required this.description,
    required this.tokenCost,    // ⭐️ FIX: The constructor now requires tokenCost
    this.imageUrl,
  });

  // Method to serialize the object to a Map for Firestore upload
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'tokenCost': tokenCost,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor to create an object from a Firestore DocumentSnapshot
  factory Item.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      throw Exception("Document data is null");
    }

    return Item(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      tokenCost: (data['tokenCost'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}