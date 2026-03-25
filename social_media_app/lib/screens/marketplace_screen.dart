import 'package:flutter/material.dart';

// 1. THE MARKETPLACE SCREEN: Manages state for product filtering and search
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  // Current active filter category
  String selectedCategory = 'All';

  // Mock Data: Local list of products with metadata
  List<Map<String, String>> allProducts = [
    {'title': 'Acoustic Guitar', 'price': '₱4,500', 'cat': 'Electronics', 'loc': 'Manila', 'image': 'https://images.unsplash.com/photo-1550291652-6ea9114a47b1?sig=1'},
    {'title': 'Bike (Mountain)', 'price': '₱3,500', 'cat': 'Vehicles', 'loc': 'Davao', 'image': 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?sig=2'},
    {'title': 'Camera (Vintage)', 'price': '₱5,200', 'cat': 'Electronics', 'loc': 'Quezon City', 'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?sig=3'},
    {'title': 'Desk Lamp', 'price': '₱1,150', 'cat': 'Furniture', 'loc': 'Cebu', 'image': 'https://images.unsplash.com/photo-1534073828943-f801091bb18c?sig=4'},
    {'title': 'Earbuds (Wireless)', 'price': '₱2,200', 'cat': 'Electronics', 'loc': 'Makati', 'image': 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?sig=5'},
    {'title': 'Furniture Sofa', 'price': '₱12,000', 'cat': 'Furniture', 'loc': 'Pasig', 'image': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?sig=6'},
    {'title': 'Gaming Laptop', 'price': '₱45,000', 'cat': 'Electronics', 'loc': 'Manila', 'image': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?sig=7'},
    {'title': 'Helmet (Full Face)', 'price': '₱3,100', 'cat': 'Vehicles', 'loc': 'Taguig', 'image': 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?sig=8'},
    {'title': 'iPhone 13 Pro', 'price': '₱28,000', 'cat': 'Electronics', 'loc': 'Makati', 'image': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?sig=9'},
    {'title': 'Jacket (Leather)', 'price': '₱1,800', 'cat': 'Clothing', 'loc': 'Manila', 'image': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?sig=10'},
    {'title': 'Keyboard (Mech)', 'price': '₱2,500', 'cat': 'Electronics', 'loc': 'Iloilo', 'image': 'https://images.unsplash.com/photo-1511467687858-23d96c32e4ae?sig=11'},
    {'title': 'Monitor 24 inch', 'price': '₱5,200', 'cat': 'Electronics', 'loc': 'Makati', 'image': 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?sig=12'},
    {'title': 'Nike Shoes', 'price': '₱3,200', 'cat': 'Clothing', 'loc': 'Manila', 'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?sig=13'},
    {'title': 'Office Chair', 'price': '₱1,200', 'cat': 'Furniture', 'loc': 'Quezon City', 'image': 'https://images.unsplash.com/photo-1592078615290-033ee584e267?sig=14'},
    {'title': 'Smart Watch', 'price': '₱1,500', 'cat': 'Electronics', 'loc': 'Davao', 'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?sig=15'},
  ];

  // Logic: Opens a full-screen view with pinch-to-zoom (InteractiveViewer)
  void _viewImageOnly(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Logic: Triggers the built-in Flutter search delegate
  void _openSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: MarketplaceSearchDelegate(
        allProducts: allProducts,
        onImageTap: (url) => _viewImageOnly(context, url),
      ),
    );
  }

  // UI: Shows a bottom drawer to filter items by category
  void _showCategories(BuildContext context) {
    final List<Map<String, dynamic>> filterOptions = [
      {'label': 'All', 'icon': Icons.grid_view_rounded},
      {'label': 'Electronics', 'icon': Icons.devices},
      {'label': 'Furniture', 'icon': Icons.chair_outlined},
      {'label': 'Vehicles', 'icon': Icons.directions_car_filled_outlined},
      {'label': 'Clothing', 'icon': Icons.checkroom},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Filter by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...filterOptions.map((option) => ListTile(
            leading: Icon(option['icon'], color: Colors.black),
            title: Text(option['label']),
            trailing: selectedCategory == option['label'] ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              setState(() => selectedCategory = option['label']);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Computes which items to show based on the active filter
    final filteredList = selectedCategory == 'All'
        ? allProducts
        : allProducts.where((p) => p['cat'] == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: GestureDetector(
          onTap: () => _openSearch(context),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey, size: 20),
                    SizedBox(width: 10),
                    Text('Search Marketplace', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              children: [
                _buildActionButton(Icons.list, selectedCategory == 'All' ? "Categories" : selectedCategory, () => _showCategories(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Main Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 items per row
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) => _buildMarketItem(context, filteredList[index]),
            ),
          ),
        ],
      ),
    );
  }

  // Builder: Creates the filter button widget
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // Builder: Creates individual product cards
  Widget _buildMarketItem(BuildContext context, Map<String, String> product) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _viewImageOnly(context, product['image']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  product['image']!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(product['price']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(product['title']!, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(product['loc']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// 2. SEARCH LOGIC: Handles live searching through the product list
class MarketplaceSearchDelegate extends SearchDelegate {
  final List<Map<String, String>> allProducts;
  final Function(String) onImageTap;
  MarketplaceSearchDelegate({required this.allProducts, required this.onImageTap});

  @override
  String get searchFieldLabel => "Search Marketplace";

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  // Shared builder for both suggestions and final results
  Widget _buildSearchResults(BuildContext context) {
    final suggestionList = query.isEmpty
        ? []
        : allProducts.where((p) => p['title']!.toLowerCase().contains(query.toLowerCase())).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final product = suggestionList[index];
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onImageTap(product['image']!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(product['image']!, fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 8),
                Text(product['price']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(product['title']!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }
}