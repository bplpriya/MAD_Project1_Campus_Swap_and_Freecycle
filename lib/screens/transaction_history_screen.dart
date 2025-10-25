// lib/screens/transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) currentUserId = user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('transactions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allTransactions = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['buyerId'] == currentUserId || data['sellerId'] == currentUserId;
          }).toList();

          if (allTransactions.isEmpty) {
            return const Center(child: Text("No transactions yet."));
          }

          allTransactions.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: allTransactions.length,
            itemBuilder: (context, index) {
              final data = allTransactions[index].data() as Map<String, dynamic>;
              final type = data['buyerId'] == currentUserId ? 'Bought' : 'Sold';
              final tokenChange = data['tokenChange'] ?? 0;
              final status = data['status'] ?? '';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final timeString = timestamp != null ? timestamp.toLocal().toString().split('.')[0] : '';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(
                    type == 'Bought' ? Icons.shopping_cart : Icons.sell,
                    color: type == 'Bought' ? Colors.green : Colors.orange,
                  ),
                  title: Text('$type - Item ID: ${data['itemId']}'),
                  subtitle: Text('Tokens: $tokenChange\n$timeString\nStatus: $status'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
