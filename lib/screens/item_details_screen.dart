import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import '../models/item_model.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;
  final String sellerName;
  final String sellerId;

  const ItemDetailsScreen({
    super.key,
    required this.item,
    required this.sellerName,
    required this.sellerId,
  });

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Stream to check if the item is currently in the user's wishlist
  Stream<DocumentSnapshot>? _wishlistStream;

  @override
  void initState() {
    super.initState();
    _initializeWishlistStream();
  }

  void _initializeWishlistStream() {
    final user = _auth.currentUser;
    if (user != null) {
      // Stream the specific document in the user's wishlist subcollection
      _wishlistStream = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(widget.item.id)
          .snapshots();
    }
  }

  Future<void> _toggleWishlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(widget.item.id);

    final doc = await docRef.get();
    bool isInWishlist = doc.exists;

    try {
      if (isInWishlist) {
        // Remove from wishlist
        await docRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist.')),
        );
      } else {
        // Add to wishlist
        // Store the necessary item data for display in the WishlistScreen
        await docRef.set({
          'itemId': widget.item.id,
          'name': widget.item.name,
          'description': widget.item.description,
          'tokenCost': widget.item.tokenCost,
          'imageUrl': widget.item.imageUrl,
          'sellerId': widget.sellerId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to wishlist!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update wishlist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current user is the seller (don't show wishlist or chat button)
    final isSeller = _auth.currentUser?.uid == widget.sellerId;

    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item.imageUrl != null)
              Image.network(widget.item.imageUrl!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text(widget.item.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('${widget.item.tokenCost} Tokens',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('Sold by: ${widget.sellerName}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text(widget.item.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            
            // Wishlist Button
            if (!isSeller)
              Center(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _wishlistStream,
                  builder: (context, snapshot) {
                    bool isInWishlist = snapshot.hasData && snapshot.data!.exists;
                    return ElevatedButton.icon(
                      icon: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist ? Colors.red : null,
                      ),
                      label: Text(
                        isInWishlist ? 'Remove from Wishlist' : 'Add to Wishlist',
                      ),
                      onPressed: _toggleWishlist,
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 10),

            // Chat Button
            if (!isSeller)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat with Seller'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          receiverId: widget.sellerId,
                          receiverName: widget.sellerName,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}