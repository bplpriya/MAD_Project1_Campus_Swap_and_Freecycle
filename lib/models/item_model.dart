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

  Item({
    this.id = '',
    required this.name,
    required this.description,
    required this.tokenCost,
    this.imageUrl,
    this.condition = 'New',
    this.sellerId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'tokenCost': tokenCost,
      'imageUrl': imageUrl,
      'condition': condition,
      'sellerId': sellerId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

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
      condition: data['condition'] ?? 'New',
      sellerId: data['sellerId'] ?? '',
    );
  }
}
