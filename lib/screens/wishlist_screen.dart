// lib/screens/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import 'item_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  Future<void> _removeFromWishlist(BuildContext context, String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(itemId)
        .delete();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item removed from wishlist.')),
    );
  }

  Future<Map<String, String>> _fetchSellerDetails(String sellerId) async {
    if (sellerId.isEmpty) return {'name': 'Unknown', 'email': 'Not available'};
    final sellerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .get();
    return {
      'name': sellerDoc.data()?['name'] ?? 'Unknown',
      'email': sellerDoc.data()?['email'] ?? 'Not available',
    };
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
      appBar: AppBar(title: const Text('My Wishlist ✨')),
      body: StreamBuilder<QuerySnapshot>(
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
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final item = Item(
                id: data['itemId'] ?? doc.id,
                name: data['name'] ?? 'No Name',
                description: data['description'] ?? '',
                tokenCost: (data['tokenCost'] as num?)?.toInt() ?? 0,
                imageUrl: data['imageUrl'] as String?,
                sellerId: data['sellerId'] ?? '', // Retrieve sellerId
                latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
                longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
                location: data['location'] ?? '',
              );
              final sellerId = item.sellerId;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: SizedBox(
                      width: 55.0,
                      height: 55.0,
                      child: item.imageUrl != null
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : Container(
                              color: Colors.red.shade100, // Distinct color for wishlist items
                              child: const Icon(Icons.favorite, size: 30, color: Colors.red),
                            ),
                    ),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Cost: ${item.tokenCost} Tokens', style: TextStyle(color: Colors.orange.shade700)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _removeFromWishlist(context, doc.id),
                    tooltip: 'Remove from Wishlist',
                  ),
                  onTap: () async {
                    final sellerDetails = await _fetchSellerDetails(sellerId);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailsScreen(
                          item: item,
                          sellerName: sellerDetails['name']!,
                          sellerId: sellerId,
                          sellerEmail: sellerDetails['email']!,
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
    );
  }
}