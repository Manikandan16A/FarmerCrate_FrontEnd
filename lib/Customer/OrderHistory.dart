import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrderHistoryPage extends StatefulWidget {
  final String? token;
  const OrderHistoryPage({Key? key, this.token}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class OrderItem {
  final int orderId;
  final int quantity;
  final double totalPrice;
  final String status;
  final String deliveryAddress;
  final DateTime createdAt;
  final String productName;
  final double productPrice;

  OrderItem({
    required this.orderId,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
    required this.productName,
    required this.productPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    return OrderItem(
      orderId: (json['order_id'] ?? json['id'] ?? 0) as int,
      quantity: (json['quantity'] ?? 0) as int,
      totalPrice: (json['total_price'] is num) ? (json['total_price'] as num).toDouble() : double.tryParse('${json['total_price']}') ?? 0.0,
      status: (json['status'] ?? '').toString(),
      deliveryAddress: (json['delivery_address'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      productName: (product['name'] ?? product['title'] ?? '').toString(),
      productPrice: (product['current_price'] is num) ? (product['current_price'] as num).toDouble() : double.tryParse('${product['current_price']}') ?? 0.0,
    );
  }
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  bool _isLoading = true;
  String? _error;
  List<OrderItem> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<String?> _resolveToken() async {
    if (widget.token != null && widget.token!.trim().isNotEmpty) return widget.token;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token') ?? prefs.getString('jwt_token');
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await _resolveToken();
    if (token == null || token.trim().isEmpty) {
      setState(() {
        _error = 'Authentication required. Please sign in.';
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('https://farmercrate.onrender.com/api/orders');
      final resp = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final data = body['data'] as List<dynamic>?;
        if (data == null || data.isEmpty) {
          setState(() {
            _orders = [];
            _isLoading = false;
          });
          return;
        }

        final parsed = data.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(growable: false);
        setState(() {
          _orders = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load orders (${resp.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching orders: $e';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
      case 'REFUNDED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      )
                    ],
                  )
                : _orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('No orders found'))
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final o = _orders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(o.status).withOpacity(0.15),
                                child: Icon(Icons.shopping_bag, color: _statusColor(o.status)),
                              ),
                              title: Text(o.productName.isNotEmpty ? o.productName : 'Order #${o.orderId}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text('Quantity: ${o.quantity} • Item: ₹${o.productPrice.toStringAsFixed(2)}'),
                                  const SizedBox(height: 4),
                                  Text('Total: ₹${o.totalPrice.toStringAsFixed(2)}'),
                                  const SizedBox(height: 6),
                                  Text('Address: ${o.deliveryAddress}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Text('Ordered: ${o.createdAt.toLocal().toString().split('.').first}'),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(o.status),
                                backgroundColor: _statusColor(o.status).withOpacity(0.12),
                                labelStyle: TextStyle(color: _statusColor(o.status)),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(o.productName.isNotEmpty ? o.productName : 'Order #${o.orderId}'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order ID: ${o.orderId}'),
                                        const SizedBox(height: 8),
                                        Text('Status: ${o.status}'),
                                        const SizedBox(height: 8),
                                        Text('Quantity: ${o.quantity}'),
                                        const SizedBox(height: 8),
                                        Text('Item Price: ₹${o.productPrice.toStringAsFixed(2)}'),
                                        const SizedBox(height: 8),
                                        Text('Total Price: ₹${o.totalPrice.toStringAsFixed(2)}'),
                                        const SizedBox(height: 8),
                                        Text('Delivery Address:'),
                                        Text(o.deliveryAddress),
                                        const SizedBox(height: 8),
                                        Text('Ordered At: ${o.createdAt.toLocal().toString().split('.').first}'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

