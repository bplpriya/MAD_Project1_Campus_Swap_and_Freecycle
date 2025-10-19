// lib/screens/item_listings_screen.dart
import 'package:flutter/material.dart';
import 'add_item_screen.dart'; // UPDATED PATH (relative)
import '../models/item_model.dart'; // UPDATED PATH (step up to lib, then down to models)

class ItemListingsScreen extends StatefulWidget {
  const ItemListingsScreen({super.key});

  @override
  State<ItemListingsScreen> createState() => _ItemListingsScreenState();
}

class _ItemListingsScreenState extends State<ItemListingsScreen> {
  // In-memory list to hold items
  final List<Item> _items = [
    Item(
      name: 'Item 1',
      description: 'First hardcoded item.',
      price: 10.0,
    ),
    Item(
      name: 'Item 2',
      description: 'Second hardcoded item.',
      price: 25.50,
    ),
  ];

  // Function to add a new item and trigger a UI refresh
  void _addItem(Item newItem) {
    setState(() {
      _items.add(newItem);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No items listed yet!'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: item.image != null
                      // Only display Image.file if image is selected and file exists
                      ? Image.file(
                          item.image!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.inventory, size: 40),
                  title: Text(item.name),
                  subtitle: Text(
                      'Price: \$${item.price.toStringAsFixed(2)}\n${item.description}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Optional: Navigate to a detail screen
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Pass the _addItem function to AddItemScreen
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddItemScreen(onSave: _addItem)),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Item',
      ),
    );
  }
}