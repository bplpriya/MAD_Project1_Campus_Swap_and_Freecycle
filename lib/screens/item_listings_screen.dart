// lib/screens/item_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'filter_search_screen.dart';
import 'wishlist_screen.dart'; 
import '../models/item_model.dart';

class ItemListingsScreen extends StatefulWidget {
  ItemListingsScreen({Key? key}) : super(key: key);

  @override
  State<ItemListingsScreen> createState() => _ItemListingsScreenState();
}

class _ItemListingsScreenState extends State<ItemListingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _toggleWishlist(Item item, bool isWishlisted) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final wishlistRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(item.id);

    try {
      if (isWishlisted) {
        await wishlistRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.name} removed from wishlist.')));
      } else {
        await wishlistRef.set({
          'itemId': item.id,
          'name': item.name,
          'tokenCost': item.tokenCost,
          'imageUrl': item.imageUrl,
          'sellerId': item.sellerId,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'location': item.location,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.name} added to wishlist!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update wishlist: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Swap'),
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
            icon: const Icon(Icons.favorite_border), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
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
              allItems.where((item) => item.flagCount < 10 && item.status == 'Available').toList(); 

          if (visibleItems.isEmpty) {
            return const Center(child: Text('No available items match criteria!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: visibleItems.length,
            itemBuilder: (context, index) {
              final item = visibleItems[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            })
                          : Container(
                              color: Colors.green.shade100,
                              child: Icon(Icons.inventory, size: 40, color: Colors.green.shade700),
                            ),
                    ),
                  ),
                  title: Text(
                    item.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Cost: ${item.tokenCost} Tokens', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                      Text('Condition: ${item.condition}'),
                    ],
                  ),

                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  
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
                ),
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