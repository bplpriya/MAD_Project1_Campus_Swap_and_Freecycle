// lib/screens/filter_search_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import 'item_details_screen.dart';

class FilterSearchScreen extends StatefulWidget {
  const FilterSearchScreen({super.key});

  @override
  State<FilterSearchScreen> createState() => _FilterSearchScreenState();
}

class _FilterSearchScreenState extends State<FilterSearchScreen> {
  String _searchQuery = '';
  int? _maxTokenCost;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _maxCostController = TextEditingController();

  // Method to build the Firestore query based on current filters
  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('items');

    // 1. Order by creation time (default)
    query = query.orderBy('createdAt', descending: true);

    // 2. Filter by max token cost (if set)
    // Firestore queries can't easily filter by "less than or equal to" without
    // a separate index, and are more optimized for range queries. For a simple
    // filter like this, we'll apply the filter logic in the StreamBuilder.
    // However, if we wanted to filter by name *starting with* a letter, we'd use
    // where('name', isGreaterThanOrEqualTo: 'A').where('name', isLessThan: 'B').

    return query;
  }

  // --- Filter/Search logic ---

  // Update max cost filter
  void _updateMaxCost(String value) {
    final cost = int.tryParse(value.trim());
    setState(() {
      _maxTokenCost = cost;
    });
  }

  // Update search query
  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
    });
  }

  // Check if an item matches the current filters
  bool _itemMatchesFilters(Item item) {
    // Filter by max token cost
    if (_maxTokenCost != null && item.tokenCost > _maxTokenCost!) {
      return false;
    }

    // Filter by name (case-insensitive substring match)
    if (_searchQuery.isNotEmpty && !item.name.toLowerCase().contains(_searchQuery)) {
      return false;
    }

    return true;
  }

  // --- Widget Builders ---

  Widget _buildFilterFields() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by Name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _updateSearchQuery,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _maxCostController,
            decoration: const InputDecoration(
              labelText: 'Max Token Cost',
              prefixIcon: Icon(Icons.money),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: _updateMaxCost,
          ),
          const SizedBox(height: 10),
          const Text(
            'Note: Filters are applied locally after fetching.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, Item item, String sellerId) {
    return ListTile(
      leading: item.imageUrl != null
          ? Image.network(
              item.imageUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
            )
          : const Icon(Icons.inventory, size: 40),
      title: Text(item.name),
      subtitle: Text('Cost: ${item.tokenCost} Tokens'),
      onTap: () async {
        String sellerName = 'Unknown';
        if (sellerId.isNotEmpty) {
          final sellerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .get();
          sellerName = sellerDoc.data()?['name'] ?? 'Unknown';
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(
              item: item,
              sellerName: sellerName,
              sellerId: sellerId,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filter & Search Items')),
      body: Column(
        children: [
          _buildFilterFields(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No items listed yet!'));
                }

                // Apply local filtering to the fetched documents
                final filteredItems = snapshot.data!.docs.map((doc) {
                  final item = Item.fromMap(doc);
                  final sellerId = (doc.data() as Map<String, dynamic>)['sellerId'] ?? '';
                  return {'item': item, 'sellerId': sellerId};
                }).where((map) => _itemMatchesFilters(map['item'] as Item)).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text('No items match your criteria.'));
                }

                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index]['item'] as Item;
                    final sellerId = filteredItems[index]['sellerId'] as String;
                    return _buildItemTile(context, item, sellerId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}