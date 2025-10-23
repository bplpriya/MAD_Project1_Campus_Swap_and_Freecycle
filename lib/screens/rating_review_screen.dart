import 'package:flutter/material.dart';

class RatingReviewScreen extends StatefulWidget {
  // Removed const
  RatingReviewScreen({super.key});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  double rating = 0;
  final TextEditingController reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rate & Review")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("How was your experience?", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            TextField(
              controller: reviewController,
              decoration: InputDecoration(labelText: "Write a review"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Save rating & review to Firestore
                Navigator.pop(context);
              },
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
