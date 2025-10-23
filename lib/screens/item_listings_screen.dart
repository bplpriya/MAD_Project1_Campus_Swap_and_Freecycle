// lib/screens/item_listings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';
import 'filter_search_screen.dart';
import 'wishlist_screen.dart';
import 'notifications_screen.dart'; // <--- Import NotificationsScreen
import '../models/item_model.dart';

class ItemListingsScreen extends StatefulWidget {
  ItemListingsScreen({Key? key}) : super(key: key);

  @override
  State<ItemListingsScreen> createState() => _ItemListingsScreenState();
}

class _ItemListingsScreenState extends State<ItemListingsScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications), // <-- Notification icon added
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => WishlistScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => FilterSearchScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ProfileScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
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

          // Map Firestore docs to Item objects safely
          final items = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};

            return Item(
              id: doc.id,
              name: (data['name'] ?? 'Unknown') as String,
              description: (data['description'] ?? '') as String,
              tokenCost: (data['tokenCost'] ?? 0) as int,
              imageUrl: data['imageUrl'] as String?,
              condition: (data['condition'] ?? 'New') as String,
              sellerId: (data['sellerId'] ?? '') as String,
            );
          }).toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return ListTile(
                leading: SizedBox(
                  width: 50,
                  height: 50,
                  child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.inventory, size: 40),
                ),
                title: Text(item.name),
                subtitle: Text('Cost: ${item.tokenCost} Tokens'),
                onTap: () async {
                  String sellerName = 'Unknown';

                  if (item.sellerId.isNotEmpty) {
                    final sellerDoc =
                        await _firestore.collection('users').doc(item.sellerId).get();
                    sellerName = sellerDoc.data()?['name'] as String? ?? 'Unknown';
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailsScreen(
                        item: item,
                        sellerName: sellerName,
                        sellerId: item.sellerId,
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
              context, MaterialPageRoute(builder: (_) => AddItemScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
