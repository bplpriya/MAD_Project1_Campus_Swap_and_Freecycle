import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final String currentUserId;
  final void Function(int)? onTokenChanged;

  TransactionHistoryScreen({
    super.key,
    required this.currentUserId,
    this.onTokenChanged,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _markCompleted(DocumentSnapshot txDoc) async {
    final txData = txDoc.data() as Map<String, dynamic>;
    final buyerId = txData['buyerId'];
    final sellerId = txData['sellerId'];
    final tokenValue = txData['tokenValue'] ?? 1;

    // Update transaction status
    await _firestore.collection('transactions').doc(txDoc.id).update({'status': 'Completed'});

    // Update buyer and seller token balances
    final buyerRef = _firestore.collection('users').doc(buyerId);
    final sellerRef = _firestore.collection('users').doc(sellerId);

    final buyerDoc = await buyerRef.get();
    final sellerDoc = await sellerRef.get();

    final buyerTokens = (buyerDoc.data()?['tokenBalance'] ?? 0) - tokenValue;
    final sellerTokens = (sellerDoc.data()?['tokenBalance'] ?? 0) + tokenValue;

    await buyerRef.update({'tokenBalance': buyerTokens});
    await sellerRef.update({'tokenBalance': sellerTokens});

    // Update token in Profile if current user is buyer or seller
    if (onTokenChanged != null) {
      if (currentUserId == buyerId) onTokenChanged!(buyerTokens);
      if (currentUserId == sellerId) onTokenChanged!(sellerTokens);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('transactions')
            .where('buyerId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No transactions yet.'));
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final txData = tx.data() as Map<String, dynamic>;
              final status = txData['status'] ?? 'Pending';
              final itemName = txData['itemName'] ?? 'Item';
              final tokenValue = txData['tokenValue'] ?? 1;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text(itemName),
                  subtitle: Text("Status: $status\nToken: $tokenValue"),
                  trailing: status == 'In Progress'
                      ? ElevatedButton(
                          onPressed: () => _markCompleted(tx),
                          child: Text('Mark Completed'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
