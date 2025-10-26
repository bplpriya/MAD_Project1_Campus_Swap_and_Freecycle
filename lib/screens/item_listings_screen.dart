import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'filter_search_screen.dart';
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
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FilterSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
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

          final allItems =
              snapshot.data!.docs.map((doc) => Item.fromMap(doc)).toList();
          final visibleItems =
              allItems.where((item) => item.flagCount < 10).toList();

          if (visibleItems.isEmpty) {
            return const Center(child: Text('No items available!'));
          }

          return ListView.builder(
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final item = visibleItems[index];

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
                  String sellerEmail = 'Not available';

                  if (item.sellerId.isNotEmpty) {
                    final sellerDoc = await _firestore
                        .collection('users')
                        .doc(item.sellerId)
                        .get();
                    final data = sellerDoc.data();
                    if (data != null) {
                      sellerName = data['name'] as String? ?? 'Unknown';
                      sellerEmail = data['email'] as String? ?? 'Not available';
                    }
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailsScreen(
                        item: item,
                        sellerName: sellerName,
                        sellerEmail: sellerEmail,
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
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
