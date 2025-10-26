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
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final reviews = snapshot.data!.docs;
        if (reviews.isEmpty) return const Text("No reviews yet.");
        return Column(
          children: reviews.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blueAccent),
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
                          size: 18,
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
        final itemData = await itemRef.get();
        final tokenCost = (itemData.data()?['tokenCost'] ?? 0) as int;

        final buyerDoc = await _firestore.collection('users').doc(user.uid).get();
        final currentTokens = buyerDoc.data()?['tokens'] ?? 20;

        if (currentTokens < tokenCost) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Not enough tokens!")));
          return;
        }

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

    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.item.imageUrl != null)
              Center(
                  child:
                      Image.network(widget.item.imageUrl!, height: 200, fit: BoxFit.cover))
            else
              const Center(child: Icon(Icons.inventory, size: 100)),
            const SizedBox(height: 20),
            Text(widget.item.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Cost: ${widget.item.tokenCost} Tokens'),
            const SizedBox(height: 10),
            Text('Condition: ${widget.item.condition}'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(widget.item.location.isNotEmpty
                    ? widget.item.location
                    : 'Lat: ${widget.item.latitude}, Long: ${widget.item.longitude}'),
              ],
            ),
            const SizedBox(height: 10),
            Text('Description: ${widget.item.description}'),
            const SizedBox(height: 20),
            // Seller info, black email
            Text('Sold by: ${widget.sellerName}', style: const TextStyle(fontSize: 16)),
            Text('Email: ${widget.sellerEmail}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (!isSeller)
                  ElevatedButton.icon(
                    onPressed: _isFlagging ? null : _flagItem,
                    icon: _isFlagging
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.flag, color: Colors.red),
                    label: const Text("Flag"),
                  ),
                if (isSeller && widget.item.status != 'Sold')
                  ElevatedButton(
                      onPressed:
                          _isUpdatingStatus ? null : () => _updateTransaction(soldByMe: true),
                      child: _isUpdatingStatus
                          ? const CircularProgressIndicator()
                          : const Text("Mark as Sold")),
                if (!isSeller && widget.item.status != 'Sold')
                  ElevatedButton(
                      onPressed:
                          _isUpdatingStatus ? null : () => _updateTransaction(soldByMe: false),
                      child: _isUpdatingStatus
                          ? const CircularProgressIndicator()
                          : const Text("I Bought This")),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text("Customer Reviews",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildReviewSection(),
            const SizedBox(height: 20),
            const Divider(),
            const Text("Leave a Review",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber),
                  onPressed: () => setState(() => _rating = (index + 1).toDouble()),
                ),
              ),
            ),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: "Write your review...",
                border: OutlineInputBorder(),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
