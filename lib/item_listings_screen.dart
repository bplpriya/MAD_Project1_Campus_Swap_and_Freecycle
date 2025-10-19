import 'package:flutter/material.dart';
import 'add_item_screen.dart'; // navigate to add item screen

class ItemListingsScreen extends StatelessWidget {
  const ItemListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> items = ['Item 1', 'Item 2', 'Item 3'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(items[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ✅ Navigate to AddItemScreen when + is pressed
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Item',
      ),
    );
  }
}
