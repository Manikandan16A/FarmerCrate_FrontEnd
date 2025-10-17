import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'admin_homepage.dart';

class AdminOrdersPage extends StatefulWidget {
  final String token;
  final dynamic user;
  
  const AdminOrdersPage({Key? key, required this.token, required this.user}) : super(key: key);

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
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
  final String productImage;
  final String sourceTransporterName;
  final String sourceTransporterAddress;
  final String destTransporterName;
  final String destTransporterAddress;
  final String deliveryPersonName;
  final String deliveryPersonPhone;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  OrderItem({
    required this.orderId,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.sourceTransporterName,
    required this.sourceTransporterAddress,
    required this.destTransporterName,
    required this.destTransporterAddress,
    required this.deliveryPersonName,
    required this.deliveryPersonPhone,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final images = product['images'] as List<dynamic>? ?? [];
    String imageUrl = '';
    
    if (images.isNotEmpty) {
      try {
        final primaryImage = images.firstWhere(
          (img) => img is Map && img['is_primary'] == true,
          orElse: () => null,
        );
        if (primaryImage != null && primaryImage is Map) {
          imageUrl = (primaryImage['image_url'] ?? '').toString();
        } else if (images.first is Map) {
          imageUrl = ((images.first as Map)['image_url'] ?? '').toString();
        }
      } catch (e) {
        if (images.first is Map) {
          imageUrl = ((images.first as Map)['image_url'] ?? '').toString();
        }
      }
    }
    
    final deliveryPerson = json['delivery_person'];
    final customer = json['customer'] ?? {};
    
    final customerName = (customer['name'] ?? '').toString();
    final deliveryPersonName = deliveryPerson != null ? (deliveryPerson['name'] ?? 'N/A').toString() : 'Wait for assigning';
    
    print('Customer data: $customer');
    print('Final customer name: $customerName');
    print('Final delivery person: $deliveryPersonName');
    
    return OrderItem(
      orderId: (json['order_id'] ?? json['id'] ?? 0) as int,
      quantity: (json['quantity'] ?? 0) as int,
      totalPrice: (json['total_price'] is num) ? (json['total_price'] as num).toDouble() : double.tryParse('${json['total_price']}') ?? 0.0,
      status: (json['current_status'] ?? json['status'] ?? '').toString(),
      deliveryAddress: (json['delivery_address'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      productName: (product['name'] ?? '').toString(),
      productPrice: (product['current_price'] is num) ? (product['current_price'] as num).toDouble() : double.tryParse('${product['current_price']}') ?? 0.0,
      productImage: imageUrl,
      sourceTransporterName: 'Wait for assigning',
      sourceTransporterAddress: 'Wait for assigning',
      destTransporterName: 'Wait for assigning',
      destTransporterAddress: 'Wait for assigning',
      deliveryPersonName: deliveryPersonName,
      deliveryPersonPhone: deliveryPerson != null ? (deliveryPerson['mobile_number'] ?? 'N/A').toString() : 'Wait for assigning',
      customerName: customerName,
      customerEmail: (customer['email'] ?? '').toString(),
      customerPhone: (customer['mobile_number'] ?? '').toString(),
    );
  }
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  bool _isLoading = true;
  String? _error;
  List<OrderItem> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('https://farmercrate.onrender.com/api/orders/all');
      final resp = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
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
      case 'COMPLETED':
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
                builder: (context) => AdminManagementPage(token: widget.token, user: widget.user),
              ),
            );
          },
        ),
        title: const Text(
          'All Orders',
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
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchOrders,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading orders...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Orders will appear here once customers place them',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: const Color(0xFF4CAF50),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showOrderDetails(order),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          child: order.productImage.isNotEmpty
                                              ? Image.network(
                                                  order.productImage,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          _statusColor(order.status).withOpacity(0.1),
                                                          _statusColor(order.status).withOpacity(0.05),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(15),
                                                    ),
                                                    child: Icon(
                                                      Icons.shopping_bag,
                                                      color: _statusColor(order.status),
                                                      size: 32,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        _statusColor(order.status).withOpacity(0.1),
                                                        _statusColor(order.status).withOpacity(0.05),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(15),
                                                  ),
                                                  child: Icon(
                                                    Icons.shopping_bag,
                                                    color: _statusColor(order.status),
                                                    size: 32,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                order.productName.isNotEmpty ? order.productName : 'Product',
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
                                                  color: _statusColor(order.status).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  order.status,
                                                  style: TextStyle(
                                                    color: _statusColor(order.status),
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
                                                child: _buildInfoItem('Quantity', '${order.quantity}'),
                                              ),
                                              Expanded(
                                                child: _buildInfoItem('Customer', order.customerName.isNotEmpty ? order.customerName : 'N/A'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildInfoItem('Total', '₹${order.totalPrice.toStringAsFixed(2)}', isTotal: true),
                                              ),
                                              Expanded(
                                                child: _buildInfoItem('Date', _formatDate(order.createdAt)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.green[50]!, Colors.green[100]!],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.green[200]!, width: 1),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[600],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.store,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Source',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.green[700],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        order.sourceTransporterName.isNotEmpty ? order.sourceTransporterName : 'Wait for assigning',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: order.sourceTransporterName.isNotEmpty ? Colors.green[900] : Colors.grey[600],
                                                        ),
                                                      ),
                                                      if (order.sourceTransporterAddress.isNotEmpty)
                                                        Text(
                                                          order.sourceTransporterAddress,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.green[700],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.blue[50]!, Colors.blue[100]!],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blue[200]!, width: 1),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[600],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Destination',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.blue[700],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        order.destTransporterName.isNotEmpty ? order.destTransporterName : 'Wait for assigning',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: order.destTransporterName.isNotEmpty ? Colors.blue[900] : Colors.grey[600],
                                                        ),
                                                      ),
                                                      if (order.destTransporterAddress.isNotEmpty)
                                                        Text(
                                                          order.destTransporterAddress,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.blue[700],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.orange[50]!, Colors.orange[100]!],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.orange[200]!, width: 1),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[600],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delivery_dining,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Delivery Person',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.orange[700],
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        order.deliveryPersonName.isNotEmpty ? order.deliveryPersonName : 'Wait for assigning',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: order.deliveryPersonName.isNotEmpty ? Colors.orange[900] : Colors.grey[600],
                                                        ),
                                                      ),
                                                      if (order.deliveryPersonPhone.isNotEmpty)
                                                        Text(
                                                          order.deliveryPersonPhone,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.orange[700],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (order.deliveryPersonPhone.isNotEmpty)
                                                  IconButton(
                                                    onPressed: () async {
                                                      final uri = Uri.parse('tel:${order.deliveryPersonPhone}');
                                                      if (await canLaunchUrl(uri)) {
                                                        await launchUrl(uri);
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.phone,
                                                      color: Colors.orange[700],
                                                    ),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
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
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 8,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminManagementPage(token: widget.token, user: widget.user),
              ),
            );
          } else if (index == 1) {
            // Management - could navigate to user management
          } else if (index == 3) {
            // Reports
          } else if (index == 4) {
            // Profile
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Management'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  void _showOrderDetails(OrderItem order) {
    Color statusColor = _statusColor(order.status);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.green[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[400],
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName.isNotEmpty ? order.customerName : 'Customer',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.deliveryAddress.isNotEmpty ? order.deliveryAddress : 'No address',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.productImage.isNotEmpty) ...[
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      order.productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildEnhancedDetailRow('Product', order.productName.isNotEmpty ? order.productName : 'N/A', Icons.inventory),
              _buildEnhancedDetailRow('Customer Email', order.customerEmail.isNotEmpty ? order.customerEmail : 'N/A', Icons.email),
              _buildEnhancedDetailRow('Customer Phone', order.customerPhone.isNotEmpty ? order.customerPhone : 'N/A', Icons.phone),
              _buildEnhancedDetailRow('Quantity', '${order.quantity}', Icons.scale),
              _buildEnhancedDetailRow('Total Price', '₹${order.totalPrice.toStringAsFixed(2)}', Icons.currency_rupee),
              _buildEnhancedDetailRow('Order Date', _formatDate(order.createdAt), Icons.access_time),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green[600], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}