// lib/screens/item_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;

  const ItemDetailsScreen({
    Key? key,
    required this.item,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
  }) : super(key: key);

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final _reviewController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;
  bool _isFlagging = false;
  bool _isUpdatingStatus = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Toggle Wishlist Function
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
        // Remove from wishlist
        await wishlistRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from wishlist.')));
      } else {
        // Add to wishlist
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
            const SnackBar(content: Text('Added to wishlist!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update wishlist: $e')));
    }
  }

  Future<void> _flagItem() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isFlagging = true);

    final itemRef = _firestore.collection('items').doc(widget.item.id);
    final flagCollectionRef = itemRef.collection('flags');

    try {
      final userFlagDoc = await flagCollectionRef.doc(user.uid).get();
      if (userFlagDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You have already flagged this item.")));
        return;
      }

      await flagCollectionRef.doc(user.uid).set({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await itemRef.update({'flagCount': FieldValue.increment(1)});

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Listing flagged for review.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to flag: $e")));
    } finally {
      setState(() => _isFlagging = false);
    }
  }

  Future<void> _submitReview() async {
    final user = _auth.currentUser;
    if (user == null || _reviewController.text.trim().isEmpty || _rating == 0) return;

    setState(() => _isSubmitting = true);

    try {
      await _firestore
          .collection('items')
          .doc(widget.item.id)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'userEmail': user.email ?? 'Anonymous',
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _reviewController.clear();
      setState(() => _rating = 0);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Review submitted!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to submit: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildReviewSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('items')
          .doc(widget.item.id)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No reviews yet. Be the first!", style: TextStyle(color: Colors.grey));
        
        final reviews = snapshot.data!.docs;
        return Column(
          children: reviews.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.white, // Lighter card for reviews
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade100,
                  child: Text(data['userEmail']?.substring(0, 1).toUpperCase() ?? '?', style: TextStyle(color: Colors.blueGrey.shade700)),
                ),
                title: Text(data['userEmail'] ?? 'Anonymous',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < (data['rating'] ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(data['review'] ?? ''),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _updateTransaction({required bool soldByMe}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isUpdatingStatus = true);

    try {
      final itemRef = _firestore.collection('items').doc(widget.item.id);
      final transactionRef = _firestore.collection('transactions').doc();

      if (soldByMe) {
        // Seller marks as sold
        await itemRef.update({'status': 'Sold'});

        await transactionRef.set({
          'itemId': widget.item.id,
          'buyerId': '',
          'sellerId': user.uid,
          'tokenChange': widget.item.tokenCost,
          'status': 'Completed',
          'timestamp': FieldValue.serverTimestamp(),
        });

        final sellerDoc = await _firestore.collection('users').doc(user.uid).get();
        final currentTokens = sellerDoc.data()?['tokens'] ?? 20;
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'tokens': currentTokens + widget.item.tokenCost});
      } else {
        // Buyer marks as purchased
        final itemData = await itemRef.get();
        final tokenCost = (itemData.data()?['tokenCost'] ?? 0) as int;

        final buyerDoc = await _firestore.collection('users').doc(user.uid).get();
        final currentTokens = buyerDoc.data()?['tokens'] ?? 20;

        if (currentTokens < tokenCost) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Not enough tokens!")));
          return;
        }

        await itemRef.update({'status': 'Sold'}); // Mark item as sold on purchase

        await transactionRef.set({
          'itemId': widget.item.id,
          'buyerId': user.uid,
          'sellerId': widget.item.sellerId,
          'tokenChange': -tokenCost,
          'status': 'Completed',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'tokens': currentTokens - tokenCost});
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Transaction updated!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final isSeller = currentUserId == widget.sellerId;
    final isAvailable = widget.item.status != 'Sold';

    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image/Placeholder ---
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: widget.item.imageUrl != null
                    ? Image.network(widget.item.imageUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(Icons.inventory_2, size: 100, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Item Info ---
            Text(widget.item.name,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cost: ${widget.item.tokenCost} Tokens', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                Text('Condition: ${widget.item.condition}', 
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              ],
            ),
            const SizedBox(height: 15),

            // --- Location ---
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.item.location.isNotEmpty
                      ? widget.item.location
                      : 'Lat: ${widget.item.latitude.toStringAsFixed(4)}, Long: ${widget.item.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- Description ---
            const Text('Description:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(widget.item.description, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 20),

            // --- Seller Info ---
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            const Text('Seller Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(widget.sellerName.isNotEmpty ? widget.sellerName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(widget.sellerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(widget.sellerEmail),
              // REMOVED: Trailing chat icon since chat_screen was removed.
            ),
            const SizedBox(height: 20),

            // --- Wishlist and Flag Buttons ---
            if (!isSeller)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Wishlist Button (StreamBuilder to show current status)
                  if (currentUserId != null)
                    StreamBuilder<DocumentSnapshot>(
                        stream: _firestore
                            .collection('users')
                            .doc(currentUserId)
                            .collection('wishlist')
                            .doc(widget.item.id)
                            .snapshots(),
                        builder: (context, wishlistSnapshot) {
                          final isWishlisted = wishlistSnapshot.hasData && wishlistSnapshot.data!.exists;
                          return ElevatedButton.icon(
                            onPressed: () => _toggleWishlist(widget.item, isWishlisted),
                            icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                            label: Text(isWishlisted ? "Wishlisted" : "Add to Wishlist"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          );
                        }),
                  const SizedBox(width: 10),

                  // Flag Button
                  ElevatedButton.icon(
                    onPressed: _isFlagging ? null : _flagItem,
                    icon: _isFlagging
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.flag, color: Colors.white),
                    label: const Text("Flag"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // --- Transaction Buttons (Primary Action) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isSeller && isAvailable)
                  Expanded(
                    child: ElevatedButton.icon(
                        onPressed: _isUpdatingStatus ? null : () => _updateTransaction(soldByMe: true),
                        icon: _isUpdatingStatus ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle),
                        label: const Text("Mark as Sold"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12))),
                  ),
                if (!isSeller && isAvailable)
                  Expanded(
                    child: ElevatedButton.icon(
                        onPressed: _isUpdatingStatus ? null : () => _updateTransaction(soldByMe: false),
                        icon: _isUpdatingStatus ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shopping_bag),
                        label: const Text("I Bought This"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12))),
                  ),
                if (!isAvailable)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400, 
                        borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Text("SOLD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                    ),
                  ),
              ].where((widget) => widget != null).toList(), // Filter out nulls
            ),
            const SizedBox(height: 30),
            
            // --- Reviews Section ---
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            const Text("Customer Reviews",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildReviewSection(),
            const SizedBox(height: 20),
            
            // --- Leave Review Form ---
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 15),
            const Text("Leave a Review",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Your Rating:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                ...List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber),
                    onPressed: () => setState(() => _rating = (index + 1).toDouble()),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: "Write your review...",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text("Submit Review"),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}