import 'package:flutter/material.dart';
import 'chat_screen.dart';
import '../models/item_model.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Item item;
  final String sellerId;
  final String sellerName;

  ItemDetailsScreen({
    Key? key,
    required this.item,
    required this.sellerId,
    required this.sellerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              Center(
                child: Image.network(
                  item.imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: Icon(Icons.inventory, size: 100),
              ),
            SizedBox(height: 20),
            Text(
              item.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Cost: ${item.tokenCost} Tokens'),
            SizedBox(height: 10),
            Text('Condition: ${item.condition ?? "Not specified"}'),
            SizedBox(height: 10),
            Text('Description: ${item.description ?? "No description"}'),
            SizedBox(height: 20),
            Text(
              'Sold by: $sellerName',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
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
                icon: Icon(Icons.chat),
                label: Text('Chat with Seller'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
