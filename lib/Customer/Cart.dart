import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'customerhomepage.dart';
import 'navigation_utils.dart';
import '../utils/user_utils.dart';
import '../utils/snackbar_utils.dart';

import 'order_confirm.dart';
import 'product_details_screen.dart';
import 'payment.dart';

class CartItem {
  int cartItemId;
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
    // Normalize and parse cart item JSON from API

    // The API sometimes returns the product inside a nested field 'cart_product' or 'product'
    final product = json['cart_product'] ?? json['product'] ?? json['Product'] ?? json;

    // cart uses cart_id and product_id at top-level in some responses
    final cartItemId = json['cart_id'] ?? json['cart_item_id'] ?? json['id'] ?? json['cartItemId'] ?? 0;
    final productId = json['product_id'] ?? product['product_id'] ?? product['id'] ?? json['productId'] ?? 0;

    // price can be string or number; prefer current_price then price
    final priceRaw = product['current_price'] ?? product['current_price'] ?? product['price'] ?? json['current_price'] ?? json['price'] ?? '0.0';

    // images may be provided under many names and formats. Normalize to a single URL string.
    dynamic imagesField = product['images'] ?? product['image'] ?? product['image_url'] ?? product['imageUrl'] ?? json['images'] ?? json['image'] ?? json['image_url'];
    String imagesRaw = '';
    if (imagesField != null) {
      if (imagesField is List && imagesField.isNotEmpty) {
        // Try to find primary image first
        try {
          final primaryImage = imagesField.firstWhere(
            (img) => img is Map && img['is_primary'] == true,
            orElse: () => null,
          );
          if (primaryImage != null && primaryImage is Map) {
            imagesRaw = (primaryImage['image_url'] ?? primaryImage['url'] ?? '').toString();
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error finding primary image: $e');
        }
        // If no primary image found, take the first image
        if (imagesRaw.isEmpty) {
          final firstImg = imagesField[0];
          if (firstImg is Map) {
            imagesRaw = (firstImg['image_url'] ?? firstImg['url'] ?? '').toString();
          } else {
            imagesRaw = firstImg.toString();
          }
        }
      } else if (imagesField is String) {
        // If it's a comma-separated list, take the first
        imagesRaw = imagesField.split(',').map((s) => s.trim()).firstWhere((s) => s.isNotEmpty, orElse: () => '');
      } else {
        imagesRaw = imagesField.toString();
      }
    }

    // If still empty, try common alternative fields inside product or farmer
    if (imagesRaw.isEmpty) {
      final farmer = product['farmer'] ?? product['Farmer'] ?? {};
      dynamic farmerImage = farmer is Map ? (farmer['image_url'] ?? farmer['imageUrl'] ?? farmer['photo'] ?? farmer['avatar'] ?? farmer['image']) : null;
      if (farmerImage != null) {
        if (farmerImage is String) imagesRaw = farmerImage.split(',').map((s) => s.trim()).firstWhere((s) => s.isNotEmpty, orElse: () => '');
      }
    }

    if (imagesRaw.isEmpty) {
      // Try a few other keys that some APIs use
      final alt = product['thumbnail'] ?? product['photo'] ?? product['image_path'] ?? product['picture'];
      if (alt != null) imagesRaw = alt.toString();
    }

    if (kDebugMode) {
      if (imagesRaw.isEmpty) {
        debugPrint('No product image found for cart item (product id: $productId, cart id: $cartItemId)');
      } else {
        debugPrint('Using product image for cart item: $imagesRaw');
      }
    }

    final name = product['name'] ?? product['product_name'] ?? json['name'] ?? 'Unknown Product';
    final description = product['description'] ?? json['description'] ?? '';
    final category = product['category'] ?? json['category'] ?? '';
    final stockRaw = product['quantity'] ?? product['stock'] ?? json['quantity'] ?? json['stock'] ?? 999;

    return CartItem(
      cartItemId: (cartItemId is int) ? cartItemId : int.tryParse(cartItemId.toString()) ?? 0,
      productId: (productId is int) ? productId : int.tryParse(productId.toString()) ?? 0,
      name: name.toString(),
      description: description.toString(),
      price: double.tryParse(priceRaw.toString()) ?? 0.0,
      quantity: (json['quantity'] is int) ? json['quantity'] : int.tryParse((json['quantity'] ?? '1').toString()) ?? 1,
  images: imagesRaw ?? '',
      category: category.toString(),
      stock: int.tryParse(stockRaw.toString()) ?? 999,
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
    // Prefer token passed from parent. Then try UserUtils (jwt_token). Fallback to legacy 'auth_token'.
    if (widget.token != null && widget.token!.isNotEmpty) {
      _token = widget.token;
    } else {
      // Try UserUtils helper (uses 'jwt_token')
      _token = await UserUtils.getToken();
      if (_token == null || _token!.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('auth_token') ?? prefs.getString('jwt_token');
      }
    }
    // fetch items once we attempted to obtain a token
    _fetchCartItems();
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

    if (kDebugMode) {
      final tokenPreview = _token != null
        ? ((_token!.length > 10) ? '${_token!.substring(0, 10)}...' : _token)
        : 'null';
      debugPrint('Fetching cart items with token: $tokenPreview');
    }

      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/cart'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      if (kDebugMode) {
        debugPrint('Cart API Response Status: ${response.statusCode}');
        debugPrint('Cart API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
  final data = json.decode(response.body);
  if (kDebugMode) debugPrint('Full API response: $data');
        
  final dynamic itemsData = data['data'] ?? data['cart_items'] ?? data['items'] ?? [];
  if (kDebugMode) debugPrint('Cart items data: $itemsData');

        setState(() {
          if (itemsData is List) {
            _cartItems = itemsData.map((item) => CartItem.fromJson(item)).toList();
            if (kDebugMode) debugPrint('Parsed ${_cartItems.length} cart items');
          } else if (itemsData is Map) {
            final items = itemsData['items'] ?? itemsData['cart_items'] ?? [];
            if (items is List) {
              _cartItems = items.map((item) => CartItem.fromJson(item)).toList();
              if (kDebugMode) debugPrint('Parsed ${_cartItems.length} cart items from nested structure');
            }
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
      if (kDebugMode) debugPrint('Cart fetch error: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // Attempt to add a cart item server-side (used for Undo). Returns true on success.
  Future<bool> _addCartItemServer(CartItem item) async {
    try {
      final response = await http.post(
        Uri.parse('https://farmercrate.onrender.com/api/cart'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'product_id': item.productId, 'quantity': item.quantity}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = json.decode(response.body);
        if (kDebugMode) debugPrint('Add cart response: $respData');

        // If server returned a cart id, update the local item's cartItemId
        final newId = respData['data']?['cart_id'] ?? respData['cart_id'] ?? respData['id'];
        if (newId != null) {
          setState(() {
            final idx = _cartItems.indexWhere((i) => i.productId == item.productId && i.cartItemId == 0);
            if (idx != -1) {
              _cartItems[idx].cartItemId = int.tryParse(newId.toString()) ?? _cartItems[idx].cartItemId;
            }
          });
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error adding cart item: $e');
      return false;
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
        SnackBarUtils.showError(context, 'Failed to update item quantity');
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Error: $e');
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
        SnackBarUtils.showSuccess(context, 'Item removed from cart');
      } else {
        SnackBarUtils.showError(context, 'Failed to remove item');
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
        SnackBarUtils.showSuccess(context, 'Cart cleared successfully');
      } else {
        SnackBarUtils.showError(context, 'Failed to clear cart');
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Error: $e');
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
              (p) => (p['product_id'] ?? p['id']) == item.productId,
          orElse: () => null,
        );
        if (product != null) {
          final actualStock = int.tryParse(product['quantity'].toString()) ?? 0;
          if (actualStock > 0 && item.quantity >= actualStock) {
            SnackBarUtils.showWarning(context, 'Only $actualStock quantity available in stock');
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
      appBar: CustomerNavigationUtils.buildGlassmorphicAppBar(
        title: 'Cart',
        onRefresh: _isLoading ? null : _fetchCartItems,
        additionalActions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.delete_outline, color: Colors.green[800], size: 18),
              ),
              onPressed: () => _showClearCartDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade500],
                      ).createShader(bounds),
                      child: const Text(
                        'Loading cart...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
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

                // Wrap each item in a Dismissible for swipe-to-delete UX
                return Dismissible(
                  key: ValueKey(item.cartItemId != 0 ? item.cartItemId : item.productId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    // show a confirmation dialog before deleting
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Item'),
                        content: Text('Remove ${item.name} from your cart?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    return result ?? false;
                  },
                  onDismissed: (direction) {
                    // Temporarily store removed item for undo
                    final removedItem = item;
                    final removedIndex = index;
                    setState(() {
                      _cartItems.removeAt(removedIndex);
                    });

                    // Call API to remove the item in background
                    _removeCartItem(removedItem.cartItemId);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${removedItem.name} removed'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            // Re-insert locally first for instant UX
                            setState(() {
                              _cartItems.insert(removedIndex, removedItem);
                            });
                            // Attempt to restore on server
                            final success = await _addCartItemServer(removedItem);
                            if (!success) {
                              // If server restore failed, remove locally again and notify user
                              setState(() {
                                _cartItems.removeWhere((ci) => ci.productId == removedItem.productId && ci.cartItemId == removedItem.cartItemId);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not restore item on server')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Item restored')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                  child: GestureDetector(
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
                                      item.images,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '₹${cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 6),
                            // Selected count summary
                            Text(
                              '$selectedCount items selected',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        // Checkout button remains on the right
                        SizedBox(
                          width: 170,
                          child: ElevatedButton(
                            onPressed: selectedCount > 0
                                ? () {
                                    final selectedItems = _cartItems.where((item) => item.isSelected).toList();
                                    if (selectedItems.length == 1) {
                                      final item = selectedItems.first;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FarmerCratePaymentPage(
                                            orderData: {
                                              'product_id': item.productId,
                                              'product_name': item.name,
                                              'quantity': item.quantity,
                                              'unit_price': item.price,
                                              'total_price': item.price * item.quantity,
                                            },
                                            token: _token ?? widget.token ?? '',
                                          ),
                                        ),
                                      );
                                    } else {
                                      SnackBarUtils.showWarning(context, 'Please select only one item for checkout');
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Proceed to Checkout',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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