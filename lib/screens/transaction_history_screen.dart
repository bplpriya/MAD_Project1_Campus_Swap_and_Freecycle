import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  // Removed const
  TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> transactions = [
      {"item": "Bike", "status": "Completed"},
      {"item": "Laptop", "status": "Pending"},
      {"item": "Books", "status": "In Progress"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Transaction History')),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return ListTile(
            leading: Icon(Icons.history),
            title: Text(tx["item"]!),
            subtitle: Text("Status: ${tx["status"]}"),
          );
        },
      ),
    );
  }
}
