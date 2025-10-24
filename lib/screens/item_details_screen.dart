import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import '../models/item_model.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;
  final String sellerId;
  final String sellerName;

  const ItemDetailsScreen({
    Key? key,
    required this.item,
    required this.sellerId,
    required this.sellerName,
  }) : super(key: key);

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final _reviewController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;
  bool _isFlagging = false; 

  // --- Flagging Logic ---
  Future<void> _flagItem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to flag a listing.")),
      );
      return;
    }
    
    setState(() => _isFlagging = true);

    final itemRef = FirebaseFirestore.instance.collection('items').doc(widget.item.id);
    final flagCollectionRef = itemRef.collection('flags');
    
    try {
      // 1. Check if user already flagged this item
      final userFlagDoc = await flagCollectionRef.doc(user.uid).get();

      if (userFlagDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have already flagged this item.")),
        );
        return;
      }
      
      // 2. Add the user's unique flag document
      await flagCollectionRef.doc(user.uid).set({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // 3. Atomically increment the flagCount on the main item document
      await itemRef.update({
        'flagCount': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing flagged for review. Thank you.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to flag item: $e")),
      );
    } finally {
      setState(() => _isFlagging = false);
    }
  }
  // ---------------------------

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to submit a review.")),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide both rating and review.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
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
      setState(() {
        _rating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit review: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildReviewSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .doc(widget.item.id)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return const Text("No reviews yet. Be the first to review!");
        }

        return Column(
          children: reviews.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(Icons.person, color: Colors.blueAccent),
                title: Text(data['userEmail'] ?? 'Anonymous',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (data['rating'] ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(data['review'] ?? ''),
                    const SizedBox(height: 4),
                    if (data['timestamp'] != null)
                      Text(
                        (data['timestamp'] as Timestamp)
                            .toDate()
                            .toString()
                            .split('.')[0],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if the current user is the seller
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
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
                child: Image.network(
                  widget.item.imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Center(child: Icon(Icons.inventory, size: 100)),
            const SizedBox(height: 20),
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Cost: ${widget.item.tokenCost} Tokens'),
            const SizedBox(height: 10),
            Text('Condition: ${widget.item.condition ?? "Not specified"}'),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                // This line now displays the location name OR coordinates if no name was provided
                Text(
                  widget.item.location.isNotEmpty 
                    ? 'Location: ${widget.item.location}'
                    : 'Location: Lat ${widget.item.latitude.toStringAsFixed(4)}, Long ${widget.item.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            // REMOVED: Secondary Coordinates Text
            
            const SizedBox(height: 10),
            Text('Description: ${widget.item.description ?? "No description"}'),
            const SizedBox(height: 20),
            Text(
              'Sold by: ${widget.sellerName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            
            // --- Action Buttons Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat with Seller'),
                ),
                
                // Flag Button (Hidden for the seller)
                if (!isSeller)
                  ElevatedButton.icon(
                    onPressed: _isFlagging ? null : _flagItem,
                    icon: _isFlagging
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                          )
                        : const Icon(Icons.flag, color: Colors.red),
                    label: const Text('Flag Listing'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.red,
                      backgroundColor: Colors.red.shade50,
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            // --------------------------

            const SizedBox(height: 40),
            const Divider(),
            const Text(
              "Customer Reviews",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildReviewSection(),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              "Leave a Review",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() => _rating = (index + 1).toDouble());
                  },
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
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : const Text("Submit Review"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}