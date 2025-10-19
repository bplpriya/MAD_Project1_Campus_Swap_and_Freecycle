import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;

  Item({
    this.id = '',
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
  });

  // Method to serialize the object to a Map for Firestore upload
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory constructor to create an object from a Firestore DocumentSnapshot
  factory Item.fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    // Safety check for null data
    if (data == null) {
      throw Exception("Document data is null");
    }

    return Item(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}