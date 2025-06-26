import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CartProduct {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  CartProduct({required this.id, required this.name, required this.price, required this.quantity, required this.imageUrl});

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

class CartPage extends StatefulWidget {
  final int customerId;
  const CartPage({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Commented out API logic for testing
  // late Future<List<CartProduct>> _cartProductsFuture;

  // Sample products for testing
  List<CartProduct> _products = [
    CartProduct(id: 1, name: 'Tomato', price: 2.5, quantity: 1, imageUrl: 'assets/images/OIP.jpeg'),
    CartProduct(id: 2, name: 'Potato', price: 1.8, quantity: 2, imageUrl: 'assets/images/tomato-lot-1327838.jpeg'),
  ];

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      _products[index] = CartProduct(
        id: _products[index].id,
        name: _products[index].name,
        price: _products[index].price,
        quantity: newQuantity,
        imageUrl: _products[index].imageUrl,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double cartTotal = _products.fold(0, (sum, item) => sum + item.price * item.quantity);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/FarmersHomePage');
          },
        ),
      ),
      body: _products.isEmpty
          ? const Center(child: Text('No products in your cart.'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 60, color: Colors.grey),
                      ),
                    ),
                    title: Text(product.name, style: const TextStyle(fontFamily: 'Roboto')),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Quantity: '),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: product.quantity > 1
                                  ? () => _updateQuantity(index, product.quantity - 1)
                                  : null,
                            ),
                            Text(product.quantity.toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(index, product.quantity + 1),
                            ),
                          ],
                        ),
                        Text('Total: ₹${(product.price * product.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: Text('₹${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹${cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}