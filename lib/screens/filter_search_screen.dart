// lib/screens/filter_search_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; 
import '../models/item_model.dart';
import 'item_details_screen.dart';

class FilterSearchScreen extends StatefulWidget {
  const FilterSearchScreen({super.key});

  @override
  State<FilterSearchScreen> createState() => _FilterSearchScreenState();
}

class _FilterSearchScreenState extends State<FilterSearchScreen> {
  String _searchQuery = '';
  int? _minTokenCost;
  int? _maxTokenCost;
  
  // --- LOCATION STATE ---
  bool _isLocating = false;
  double? _userLatitude;
  double? _userLongitude;
  double _filterRadiusMiles = 0.0; // 0.0 means filter is off (NOW IN MILES)
  // --------------------------

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minCostController = TextEditingController();
  final TextEditingController _maxCostController = TextEditingController();

  // Method to build the Firestore query (remains simple, as filtering is done locally)
  Query _buildQuery() {
    // Fetch all items ordered by creation time.
    return FirebaseFirestore.instance.collection('items').orderBy('createdAt', descending: true);
  }

  // --- Filter/Search logic Helpers ---

  void _updateMinCost(String value) {
    final cost = int.tryParse(value.trim());
    setState(() {
      _minTokenCost = cost;
    });
  }

  void _updateMaxCost(String value) {
    final cost = int.tryParse(value.trim());
    setState(() {
      _maxTokenCost = cost;
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _minTokenCost = null;
      _maxTokenCost = null;
      _userLatitude = null;
      _userLongitude = null;
      _filterRadiusMiles = 0.0;
      _searchController.clear();
      _minCostController.clear();
      _maxCostController.clear();
    });
  }
  
  // Location fetching logic (to set the user's current location for filtering)
  Future<void> _getCurrentLocationForFilter() async {
    setState(() => _isLocating = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }
      
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your location is set for filtering.')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      setState(() {
        _userLatitude = null;
        _userLongitude = null;
      });
    } finally {
      setState(() => _isLocating = false);
    }
  }

  // Utility method to calculate distance in Miles (meters * 0.000621371)
  double _calculateDistanceMiles(double itemLat, double itemLong) {
    if (_userLatitude == null || _userLongitude == null) {
      return double.infinity; // Cannot calculate distance without user location
    }
    // Geolocator returns distance in meters
    final distanceMeters = Geolocator.distanceBetween(
      _userLatitude!,
      _userLongitude!,
      itemLat,
      itemLong,
    );
    // Conversion factor for meters to miles: 1 meter = 0.000621371 miles
    return distanceMeters * 0.000621371; 
  }

  // Check if an item matches the current filters
  bool _itemMatchesFilters(Item item) {
    // Filter by cost and name
    if (_minTokenCost != null && item.tokenCost < _minTokenCost!) return false;
    if (_maxTokenCost != null && item.tokenCost > _maxTokenCost!) return false;
    if (_searchQuery.isNotEmpty && !item.name.toLowerCase().contains(_searchQuery)) return false;
    
    // NEW: Filter by distance (in Miles)
    if (_filterRadiusMiles > 0.0 && _userLatitude != null && _userLongitude != null) {
      // Skip items with default coordinates (0,0) as they can skew distance calculations
      if (item.latitude == 0.0 && item.longitude == 0.0) return false; 
      
      final distance = _calculateDistanceMiles(item.latitude, item.longitude);
      if (distance > _filterRadiusMiles) {
        return false;
      }
    }

    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minCostController.dispose();
    _maxCostController.dispose();
    super.dispose();
  }

  // --- Widget Builders ---

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text('Filter by Distance (in miles):', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: _filterRadiusMiles,
          min: 0,
          max: 10, // Max 10 miles filter
          divisions: 10,
          label: _filterRadiusMiles == 0.0 ? 'Off' : '${_filterRadiusMiles.toStringAsFixed(1)} miles',
          onChanged: (double value) {
            setState(() {
              _filterRadiusMiles = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Radius: ${_filterRadiusMiles == 0.0 ? 'Off' : '${_filterRadiusMiles.toStringAsFixed(1)} miles'}'),
            ElevatedButton.icon(
              onPressed: _isLocating ? null : _getCurrentLocationForFilter,
              icon: _isLocating
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.location_searching, size: 18),
              label: Text(_userLatitude == null ? 'Set My Location' : 'Location Set'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _userLatitude != null ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCostController,
                  decoration: const InputDecoration(
                    labelText: 'Min Cost',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _updateMinCost,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _maxCostController,
                  decoration: const InputDecoration(
                    labelText: 'Max Cost',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _updateMaxCost,
                ),
              ),
            ],
          ),
          _buildDistanceFilter(), // <--- NEW DISTANCE FILTER
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear Filters'),
              onPressed: _clearFilters,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, Item item, String sellerId) {
    double distanceMiles = _calculateDistanceMiles(item.latitude, item.longitude);
    // Only display distance if user location is set and calculation is valid
    String distanceText = distanceMiles.isFinite && distanceMiles < double.infinity
        ? ' - ${distanceMiles.toStringAsFixed(2)} miles away'
        : '';
        
    return ListTile(
      leading: SizedBox(
        width: 50.0,
        height: 50.0,
        child: item.imageUrl != null
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
              )
            : const Icon(Icons.inventory, size: 40),
      ),
      title: Text(item.name),
      subtitle: Text('Cost: ${item.tokenCost} Tokens${distanceText}'),
      onTap: () async {
        String sellerName = 'Unknown';
        String sellerEmail = 'Not available';

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
              sellerEmail: sellerEmail, 
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