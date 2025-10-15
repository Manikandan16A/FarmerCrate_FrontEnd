import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'customerhomepage.dart';
import 'customer_order_tracking.dart';

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

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerHomePage(token: widget.token),
              ),
            );
          },
        ),
        title: const Text(
          'Order History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchOrders,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading your orders...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        )
            : _error != null
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Oops! Something went wrong',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchOrders,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : _orders.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green[200]!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Colors.green[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Orders Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to see your orders here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final o = _orders[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _statusColor(o.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.shopping_bag,
                                color: _statusColor(o.status),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                o.productName.isNotEmpty ? o.productName : 'Order #${o.orderId}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDialogRow('Order ID', '${o.orderId}'),
                            _buildDialogRow('Status', o.status),
                            _buildDialogRow('Quantity', '${o.quantity}'),
                            _buildDialogRow('Item Price', '₹${o.productPrice.toStringAsFixed(2)}'),
                            _buildDialogRow('Total Price', '₹${o.totalPrice.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            const Text(
                              'Delivery Address:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(o.deliveryAddress),
                            const SizedBox(height: 8),
                            _buildDialogRow('Ordered At', o.createdAt.toLocal().toString().split('.').first),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerOrderTrackingPage(
                                    token: widget.token,
                                    orderId: o.orderId.toString(),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.track_changes, size: 18),
                            label: const Text('Track Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _statusColor(o.status).withOpacity(0.1),
                                    _statusColor(o.status).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.shopping_bag,
                                color: _statusColor(o.status),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.productName.isNotEmpty ? o.productName : 'Order #${o.orderId}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(o.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      o.status,
                                      style: TextStyle(
                                        color: _statusColor(o.status),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem('Quantity', '${o.quantity}'),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem('Item Price', '₹${o.productPrice.toStringAsFixed(2)}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem('Total', '₹${o.totalPrice.toStringAsFixed(2)}', isTotal: true),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem('Date', _formatDate(o.createdAt)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CustomerOrderTrackingPage(
                                          token: widget.token,
                                          orderId: o.orderId.toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.track_changes, size: 18),
                                  label: const Text('Track Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}