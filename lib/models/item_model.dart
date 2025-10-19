// lib/models/item_model.dart

import 'dart:io';

class Item {
  final String name;
  final String description;
  final double price;
  final File? image;

  Item({
    required this.name,
    required this.description,
    required this.price,
    this.image,
  });

  @override
  String toString() {
    return 'Item(name: $name, price: $price)';
  }
}