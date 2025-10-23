import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String itemId;
  final String userId;
  final double rating;
  final String comment;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Review.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      userId: data['userId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
