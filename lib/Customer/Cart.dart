
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'customerhomepage.dart';
import 'navigation_utils.dart';

import 'order_confirm.dart';
import 'product_details_screen.dart';

class CartItem {
  final int cartItemId;
  final int productId;
  final String name;
  final String description;
  final double price;
  int quantity;
  final String images;
  final String category;
  final int stock;
  bool isSelected;

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.images,
    required this.category,
    required this.stock,
    this.isSelected = true,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? json;
    return CartItem(
      cartItemId: json['id'] ?? json['cartItemId'] ?? 0,
      productId: product['id'] ?? json['productId'] ?? json['product_id'] ?? 0,
      name: product['name'] ?? json['name'] ?? 'Unknown Product',
      description: product['description'] ?? json['description'] ?? '',
      price: double.tryParse((product['price'] ?? json['price']).toString()) ?? 0.0,
      quantity: json['quantity'] ?? 1,
      images: product['images'] ?? json['images'] ?? '',
      category: product['category'] ?? json['category'] ?? '',
      stock: int.tryParse((product['stock'] ?? product['quantity'] ?? json['stock'] ?? json['quantity'] ?? 999).toString()) ?? 999,
    );
  }
}

class CartPage extends StatefulWidget {
  final String? token;
  const CartPage({Key? key, this.token}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String? _error;
  String? _token;
  bool _selectAll = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    // Use the token passed from the parent widget first, then fallback to SharedPreferences
    if (widget.token != null && widget.token!.isNotEmpty) {
      _token = widget.token;
      _fetchCartItems();
    } else {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _fetchCartItems();
    }
  }

  Future<void> _fetchCartItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_token == null || _token!.isEmpty) {
        setState(() {
          _error = 'No valid token found';
          _isLoading = false;
        });
        return;
      }

      print('Fetching cart items with token: ${_token!.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/cart'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      print('Cart API Response Status: ${response.statusCode}');
      print('Cart API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dynamic itemsData = data['data'] ?? [];
        print('Cart items data: $itemsData');

        setState(() {
          if (itemsData is List) {
            _cartItems = itemsData.map((json) => CartItem.fromJson(json)).toList();
            print('Parsed ${_cartItems.length} cart items from List');
          } else if (itemsData is Map && itemsData['items'] != null) {
            _cartItems = (itemsData['items'] as List).map((json) => CartItem.fromJson(json)).toList();
            print('Parsed ${_cartItems.length} cart items from Map items');
          } else {
            _cartItems = [];
            print('No cart items found in response');
          }
          _isLoading = false;
        });
      } else {
        final errorBody = response.body;
        print('Cart API Error: $errorBody');
        setState(() {
          _error = 'Failed to load cart items. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Cart fetch error: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCartItem(int cartItemId, int newQuantity) async {
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/cart/item/$cartItemId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'quantity': newQuantity}),
      );
      if (response.statusCode == 200) {
        setState(() {
          final index = _cartItems.indexWhere((item) => item.cartItemId == cartItemId);
          if (index != -1) {
            _cartItems[index].quantity = newQuantity;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update item quantity')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeCartItem(int cartItemId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://farmercrate.onrender.com/api/cart/item/$cartItemId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _cartItems.removeWhere((item) => item.cartItemId == cartItemId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from cart')),
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

  Future<void> _clearCart() async {
    try {
      final response = await http.delete(
        Uri.parse('https://farmercrate.onrender.com/api/cart'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _cartItems.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart cleared successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear cart')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _decreaseQuantity(CartItem item) {
    if (item.quantity <= 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Item'),
          content: Text('Are you sure you want to remove ${item.name} from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeCartItem(item.cartItemId);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      _updateCartItem(item.cartItemId, item.quantity - 1);
    }
  }

  Future<void> _increaseQuantity(CartItem item) async {
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/products'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['data'] as List;
        final product = products.firstWhere(
              (p) => p['id'] == item.productId,
          orElse: () => null,
        );
        if (product != null) {
          final actualStock = int.tryParse(product['quantity'].toString()) ?? 0;
          if (actualStock > 0 && item.quantity >= actualStock) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Only $actualStock quantity available in stock')),
            );
            return;
          }
        }
      }
      _updateCartItem(item.cartItemId, item.quantity + 1);
    } catch (e) {
      _updateCartItem(item.cartItemId, item.quantity + 1);
    }
  }



  @override
  Widget build(BuildContext context) {
    double cartTotal = _cartItems.where((item) => item.isSelected).fold(0, (sum, item) => sum + item.price * item.quantity);
    int selectedCount = _cartItems.where((item) => item.isSelected).length;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        elevation: 0,
        title: const Text(
          'Cart',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _showClearCartDialog(),
            ),
        ],
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
              onPressed: _fetchCartItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _cartItems.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      )
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  activeColor: Colors.green[600],
                  onChanged: (value) {
                    setState(() {
                      _selectAll = value ?? false;
                      for (var item in _cartItems) {
                        item.isSelected = _selectAll;
                      }
                    });
                  },
                ),
                Text('Select All', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productId: item.productId,
                          token: _token ?? widget.token ?? '',
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.green[100]!, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isSelected,
                            activeColor: Colors.green[600],
                            onChanged: (value) {
                              setState(() {
                                item.isSelected = value ?? false;
                                _selectAll = _cartItems.every((item) => item.isSelected);
                              });
                            },
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.images.isNotEmpty
                                ? Image.network(
                              item.images.split(',')[0],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                            )
                                : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Category: ${item.category}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _decreaseQuantity(item),
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.green[700],
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: () => _increaseQuantity(item),
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: Colors.green[700],
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => _removeCartItem(item.cartItemId),
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.green[700],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total ($selectedCount items)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedCount > 0 ? () {
                      final selectedItems = _cartItems.where((item) => item.isSelected).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderConfirmPage(
                            cartItems: selectedItems.map((item) => {
                              'name': item.name,
                              'description': item.description,
                              'price': item.price,
                              'quantity': item.quantity,
                              'images': item.images,
                              'product_id': item.productId,
                              'id': item.productId,
                            }).toList(),
                            token: widget.token,
                          ),
                        ),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                ),
              ],
            ),
          ),
        ],
      ),
      drawer: CustomerNavigationUtils.buildCustomerDrawer(
        parentContext: context,
        token: widget.token,
      ),
      bottomNavigationBar: CustomerNavigationUtils.buildCustomerBottomNav(
        currentIndex: 2, // Cart is index 2
        onTap: (index) => CustomerNavigationUtils.handleNavigation(index, context, widget.token),
      ),
    );
  }




  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Are you sure you want to remove all items from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearCart();
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}