// lib/screens/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import 'item_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  // Function to remove an item from the wishlist
  Future<void> _removeFromWishlist(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(itemId)
        .delete();
  }

  // Function to fetch seller details by ID (copied from item_listings_screen)
  Future<String> _fetchSellerName(String sellerId) async {
    if (sellerId.isEmpty) return 'Unknown';
    final sellerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .get();
    return sellerDoc.data()?['name'] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Wishlist')),
        body: const Center(child: Text('Please log in to view your wishlist.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: StreamBuilder<QuerySnapshot>(
        // Stream the items from the 'wishlist' subcollection under the current user's document
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your wishlist is empty!'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // The wishlist document stores the necessary item details
              final item = Item(
                id: data['itemId'] ?? doc.id,
                name: data['name'] ?? 'No Name',
                description: data['description'] ?? '',
                tokenCost: (data['tokenCost'] as num?)?.toInt() ?? 0,
                imageUrl: data['imageUrl'] as String?,
                // --- ADD NEW REQUIRED FIELDS WITH DEFAULTS ---
                latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
                longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
                location: data['location'] ?? '',
                // ---------------------------------------------
              );
              final sellerId = data['sellerId'] ?? '';

              return ListTile(
                leading: SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: item.imageUrl != null
                      ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.inventory, size: 40),
                ),
                title: Text(item.name),
                subtitle: Text('Cost: ${item.tokenCost} Tokens'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromWishlist(doc.id),
                ),
                onTap: () async {
                  final sellerName = await _fetchSellerName(sellerId);
                  String sellerEmail = 'Not available';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailsScreen(
                        item: item,
                        sellerName: sellerName,
                        sellerId: sellerId,
                        sellerEmail: sellerEmail,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}