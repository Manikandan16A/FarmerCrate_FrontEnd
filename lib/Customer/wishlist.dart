import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'customerhomepage.dart';
import '../utils/user_utils.dart';
import 'navigation_utils.dart';

class WishlistItem {
  final int id;
  final int productId;
  final String name;
  final String description;
  final double price;
  final String images;
  final String category;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    final product = json['Product'] ?? json['product'] ?? json;
    return WishlistItem(
      id: json['id'] ?? 0,
      productId: product['id'] ?? json['product_id'] ?? 0,
      name: product['name'] ?? 'Unknown Product',
      description: product['description'] ?? '',
      price: double.tryParse((product['price']).toString()) ?? 0.0,
      images: product['images'] ?? '',
      category: product['category'] ?? '',
    );
  }
}

class WishlistPage extends StatefulWidget {
  final String? token;
  const WishlistPage({Key? key, this.token}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<WishlistItem> _wishlistItems = [];
  bool _isLoading = true;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _fetchWishlistItems();
  }

  Future<void> _fetchWishlistItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final customerId = await UserUtils.getCustomerId() ?? 1;
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/wishlist/$customerId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final itemsData = data['data'] ?? [];
        setState(() {
          if (itemsData is List) {
            _wishlistItems = itemsData.map((json) => WishlistItem.fromJson(json)).toList();
          } else {
            _wishlistItems = [];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load wishlist items.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(int itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://farmercrate.onrender.com/api/wishlist/$itemId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _wishlistItems.removeWhere((item) => item.id == itemId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from wishlist')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove item')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _addToCart(WishlistItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productId': item.productId,
          'quantity': 1,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('${item.name} added to cart!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to add to cart'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CustomerHomePage(token: widget.token)),
          ),
        ),
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            ElevatedButton(
              onPressed: _fetchWishlistItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _wishlistItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Your wishlist is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items you love to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _wishlistItems.length,
        itemBuilder: (context, index) {
          final item = _wishlistItems[index];
          return Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green[100]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: item.images.isNotEmpty
                            ? Image.network(
                          item.images.split(',')[0],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                        )
                            : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeFromWishlist(item.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite,
                              color: Colors.red[400],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${item.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green[700],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _addToCart(item),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green[600],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      drawer: CustomerNavigationUtils.buildCustomerDrawer(
        parentContext: context,
        token: _token,
      ),
      bottomNavigationBar: CustomerNavigationUtils.buildCustomerBottomNav(
        currentIndex: 1, // Wishlist is not in bottom nav, but we'll use categories index
        onTap: (index) => CustomerNavigationUtils.handleNavigation(index, context, _token),
      ),
    );
  }
}