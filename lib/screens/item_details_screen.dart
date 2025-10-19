import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../models/item_model.dart';

class ItemDetailsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              Image.network(item.imageUrl!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Text(item.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // FIXED: Use tokenCost instead of price
            Text('${item.tokenCost} Tokens',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('Sold by: $sellerName',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text(item.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Seller'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: sellerId,
                        receiverName: sellerName,
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
