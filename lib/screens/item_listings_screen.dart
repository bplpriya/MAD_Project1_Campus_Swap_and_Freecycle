import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';
import 'filter_search_screen.dart';
import 'wishlist_screen.dart'; // NEW: Import the wishlist screen
import '../models/item_model.dart';

class ItemListingsScreen extends StatelessWidget {
  const ItemListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
        actions: [
          // NEW: Wishlist Icon
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistScreen()),
              );
            },
          ),
          // Search/Filter Icon
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FilterSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('items')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items listed yet!'));
          }

          final items = snapshot.data!.docs.map((doc) {
            final item = Item.fromMap(doc);
            // Ensure the item ID is included for the wishlist logic
            final sellerId = (doc.data() as Map<String, dynamic>)['sellerId'] ?? '';
            return {'item': item, 'sellerId': sellerId};
          }).toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index]['item'] as Item;
              final sellerId = items[index]['sellerId'] as String;

              return ListTile(
                leading: SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2));
                          },
                        )
                      : const Icon(Icons.inventory, size: 40),
                ),
                title: Text(item.name),
                subtitle: Text('Cost: ${item.tokenCost} Tokens'),
                onTap: () async {
                  String sellerName = 'Unknown';
                  if (sellerId.isNotEmpty) {
                    final sellerDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(sellerId)
                        .get();
                    sellerName = sellerDoc.data()?['name'] ?? 'Unknown';
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailsScreen(
                        item: item,
                        sellerName: sellerName,
                        sellerId: sellerId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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