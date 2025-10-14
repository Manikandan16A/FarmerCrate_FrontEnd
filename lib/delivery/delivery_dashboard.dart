import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/Signin.dart';
import 'delivery_history_page.dart';
import 'delivery_earnings_page.dart';
import 'delivery_profile_page.dart';
import 'qr_scanner_page.dart';
import 'order_update_page.dart';


class DeliveryDashboard extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const DeliveryDashboard({
    Key? key,
    required this.token,
    required this.user,
  }) : super(key: key);

  @override
  _DeliveryDashboardState createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = false;
  String _statusFilter = 'all';
  String _historyFilter = 'today';
  String _historySortBy = 'date';
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light Mode';
  String _earningsPeriod = 'week';

  // Sample data - replace with actual API calls
  List<Map<String, dynamic>> _pickupOrders = [];
  List<Map<String, dynamic>> _deliveryOrders = [];
  List<Map<String, dynamic>> _completedDeliveries = [];
  Map<String, dynamic>? _deliveryStats;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  get bold => null;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    // Load initial data
    _loadDeliveryData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== FETCHING DELIVERY PERSON ORDERS ===');
      print('Delivery Person ID: ${widget.user['id']}');
      
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/delivery-persons/orders'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final orders = responseData['data'] as List;
          print('Total Orders: ${orders.length}');

          setState(() {
            // Filter pickup orders (ASSIGNED status)
            _pickupOrders = orders.where((order) {
              final status = order['current_status']?.toString().toUpperCase() ?? '';
              return status == 'ASSIGNED';
            }).map((order) {
              final customer = order['customer'];
              final product = order['product'];
              final totalPrice = order['total_price'];
              final price = totalPrice is String ? double.tryParse(totalPrice) ?? 0.0 : (totalPrice ?? 0).toDouble();
              
              return {
                'id': order['order_id']?.toString() ?? 'N/A',
                'customerName': customer?['name'] ?? 'Customer',
                'pickupAddress': order['pickup_address'] ?? 'No address provided',
                'deliveryAddress': order['delivery_address'] ?? 'No address provided',
                'phone': customer?['mobile_number'] ?? 'N/A',
                'productName': product?['name'] ?? 'Product',
                'quantity': order['quantity'] ?? 1,
                'totalAmount': price,
                'status': 'ASSIGNED',
              };
            }).toList();

            // Filter delivery orders (IN_TRANSIT status)
            _deliveryOrders = orders.where((order) {
              final status = order['current_status']?.toString().toUpperCase() ?? '';
              return status == 'IN_TRANSIT';
            }).map((order) {
              final customer = order['customer'];
              final product = order['product'];
              final totalPrice = order['total_price'];
              final price = totalPrice is String ? double.tryParse(totalPrice) ?? 0.0 : (totalPrice ?? 0).toDouble();
              
              return {
                'id': order['order_id']?.toString() ?? 'N/A',
                'customerName': customer?['name'] ?? 'Customer',
                'pickupAddress': order['pickup_address'] ?? 'No address provided',
                'deliveryAddress': order['delivery_address'] ?? 'No address provided',
                'phone': customer?['mobile_number'] ?? 'N/A',
                'productName': product?['name'] ?? 'Product',
                'quantity': order['quantity'] ?? 1,
                'totalAmount': price,
                'status': 'IN_TRANSIT',
              };
            }).toList();

            // Filter completed deliveries
            _completedDeliveries = orders.where((order) {
              final status = order['current_status']?.toString().toUpperCase() ?? '';
              return status == 'DELIVERED' || status == 'COMPLETED';
            }).map((order) {
              final customer = order['customer'];
              final totalPrice = order['total_price'];
              final price = totalPrice is String ? double.tryParse(totalPrice) ?? 0.0 : (totalPrice ?? 0).toDouble();
              
              return {
                'id': order['order_id']?.toString() ?? 'N/A',
                'customerName': customer?['name'] ?? 'Customer',
                'address': order['delivery_address'] ?? 'No address provided',
                'deliveredAt': order['updated_at'] ?? 'Unknown date',
                'totalAmount': price,
              };
            }).toList();

            // Calculate stats
            _deliveryStats = {
              'todayDeliveries': _completedDeliveries.length,
              'totalEarnings': _completedDeliveries.fold(0.0, (sum, order) => sum + (order['totalAmount'] as double)),
              'rating': 4.8,
              'activeOrders': _pickupOrders.length + _deliveryOrders.length,
            };
          });
          
          print('Pickup Orders: ${_pickupOrders.length}');
          print('Delivery Orders: ${_deliveryOrders.length}');
          print('Completed Deliveries: ${_completedDeliveries.length}');
          print('===========================================\n');
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session expired. Please login again.'), backgroundColor: Colors.red),
        );
        await Future.delayed(Duration(seconds: 2));
        _logout();
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading delivery data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders'), backgroundColor: Colors.red),
        );
      }
      setState(() {
        _deliveryStats = _deliveryStats ?? {
          'todayDeliveries': 0,
          'totalEarnings': 0.0,
          'rating': 0.0,
          'activeOrders': 0,
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDeliveryData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 20),
            _buildStatsCards(),
            SizedBox(height: 20),
            _buildStatusFilterChips(),
            SizedBox(height: 20),
            Text('Pickup Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
            SizedBox(height: 12),
            _buildPickupOrdersList(),
            SizedBox(height: 20),
            Text('Delivery Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
            SizedBox(height: 12),
            _buildDeliveryOrdersList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QRScannerPage()),
          );
          if (result != null && mounted) {
            await _handleQRScan(result);
          }
        },
        backgroundColor: Color(0xFF4CAF50),
        child: Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.delivery_dining, size: 30, color: Color(0xFF4CAF50)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Ready to make deliveries today', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Active Orders', '${_deliveryStats?['activeOrders'] ?? 0}', Icons.shopping_bag, Colors.orange)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Today\'s Deliveries', '${_deliveryStats?['todayDeliveries'] ?? 0}', Icons.check_circle, Colors.green)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Earnings Today', '₹${_deliveryStats?['totalEarnings']?.toStringAsFixed(0) ?? '0'}', Icons.account_balance_wallet, Colors.blue)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'All', Icons.list, Colors.grey),
          SizedBox(width: 8),
          _buildFilterChip('pending', 'Pending Pickup', Icons.access_time, Colors.orange),
          SizedBox(width: 8),
          _buildFilterChip('in_transit', 'In Transit', Icons.local_shipping, Colors.blue),
          SizedBox(width: 8),
          _buildFilterChip('delivered', 'Delivered', Icons.check_circle, Colors.green),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, Color color) {
    bool isSelected = _statusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: color, width: 1.5),
      elevation: isSelected ? 4 : 0,
    );
  }

  Widget _buildPickupOrdersList() {
    if (_pickupOrders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text('No pickup orders', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _pickupOrders.map((order) => _buildOrderCard(order, isPickup: true)).toList(),
    );
  }

  Widget _buildDeliveryOrdersList() {
    if (_deliveryOrders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text('No delivery orders', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _deliveryOrders.map((order) => _buildOrderCard(order, isPickup: false)).toList(),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isPickup}) {
    final statusColor = isPickup ? Colors.orange : Colors.blue;
    final statusText = isPickup ? 'PICKUP' : 'DELIVERY';
    final address = isPickup ? order['pickupAddress'] : order['deliveryAddress'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${order['productName']} (x${order['quantity']})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF388E3C))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(statusText, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Divider(height: 20),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Expanded(child: Text(address, style: TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(order['phone']),
                  icon: Icon(Icons.phone, size: 16),
                  label: Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openMaps(address),
                  icon: Icon(Icons.navigation, size: 16),
                  label: Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone dialer'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openMaps(String address) async {
    final Uri launchUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {'api': '1', 'query': address},
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleQRScan(String qrData) async {
    print('\n=== QR SCAN HANDLER ===');
    print('QR Data: $qrData');

    final RegExp orderIdRegex = RegExp(r'order_id:\s*(\d+)');
    final match = orderIdRegex.firstMatch(qrData);
    
    if (match == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid QR code format'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final orderId = match.group(1);
    print('Extracted Order ID: $orderId');

    // Find order in delivery orders list
    final order = _deliveryOrders.firstWhere(
      (o) => o['id'] == orderId,
      orElse: () => {},
    );

    if (order.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order not found or not IN_TRANSIT'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    print('Order found in delivery list');
    print('Order Status: ${order['status']}');

    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderUpdatePage(
            orderId: orderId!,
            token: widget.token,
            orderDetails: order,
          ),
        ),
      );
      
      if (result == true) {
        await _loadDeliveryData();
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    print('\n=== UPDATING ORDER STATUS ===');
    print('Order ID: $orderId');
    print('New Status: $newStatus');

    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      print('Update Status Code: ${response.statusCode}');
      print('Update Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Reload orders
        await _loadDeliveryData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order status'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
      case 'out_for_delivery':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }



  List<Map<String, dynamic>> _getFilteredHistory() {
    final now = DateTime.now();
    return _completedDeliveries.where((delivery) {
      final deliveryDate = DateTime.tryParse(delivery['deliveredAt'] ?? '') ?? now;
      switch (_historyFilter) {
        case 'today':
          return deliveryDate.day == now.day && deliveryDate.month == now.month && deliveryDate.year == now.year;
        case 'week':
          final weekAgo = now.subtract(Duration(days: 7));
          return deliveryDate.isAfter(weekAgo);
        case 'month':
          return deliveryDate.month == now.month && deliveryDate.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildHistoryView() {
    final filteredHistory = _getFilteredHistory();
    final totalEarnings = filteredHistory.fold(0.0, (sum, d) => sum + (d['totalAmount'] as double));
    final avgTime = filteredHistory.isEmpty ? 0 : 35;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('History', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHistorySummaryCards(filteredHistory.length, totalEarnings, avgTime),
            SizedBox(height: 16),
            _buildHistoryFilters(),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Export feature coming soon!')),
                    );
                  },
                  icon: Icon(Icons.download, size: 16),
                  label: Text('Download Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (filteredHistory.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No delivery history for selected period',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: filteredHistory.map((delivery) => _buildHistoryCard(delivery)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySummaryCards(int totalDeliveries, double totalEarnings, int avgTime) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Deliveries',
            '$totalDeliveries',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Earnings',
            '₹${totalEarnings.toStringAsFixed(0)}',
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Time',
            '$avgTime min',
            Icons.timer,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filter by:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildHistoryFilterChip('today', 'Today'),
              SizedBox(width: 8),
              _buildHistoryFilterChip('week', 'This Week'),
              SizedBox(width: 8),
              _buildHistoryFilterChip('month', 'This Month'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryFilterChip(String value, String label) {
    bool isSelected = _historyFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _historyFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: Color(0xFF4CAF50), width: 1.5),
    );
  }

  Widget _buildEarningsView() {
    final totalEarnings = _completedDeliveries.fold(0.0, (sum, d) => sum + (d['totalAmount'] as double));
    final weeklyEarnings = totalEarnings * 0.7;
    final monthlyEarnings = totalEarnings * 4;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Earnings', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadDeliveryData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refreshing earnings...'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Earnings',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String>(
                          value: _earningsPeriod,
                          dropdownColor: Color(0xFF4CAF50),
                          underline: SizedBox(),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          items: [
                            DropdownMenuItem(value: 'week', child: Text('This Week')),
                            DropdownMenuItem(value: 'month', child: Text('This Month')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _earningsPeriod = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹${_earningsPeriod == 'week' ? weeklyEarnings.toStringAsFixed(2) : monthlyEarnings.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Earnings Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
            ),
            SizedBox(height: 12),
            _buildEarningsGraph(),
            SizedBox(height: 20),
            Text(
              'Per Delivery Earnings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
            ),
            SizedBox(height: 12),
            _buildDeliveryEarningsList(),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showWithdrawDialog();
                },
                icon: Icon(Icons.account_balance_wallet, size: 20),
                label: Text('Withdraw / Request Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  _showPaymentHistoryDialog();
                },
                child: Text(
                  'Payment History',
                  style: TextStyle(fontSize: 16, color: Color(0xFF4CAF50), decoration: TextDecoration.underline),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsGraph() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final earnings = [450.0, 620.0, 380.0, 720.0, 550.0, 680.0, 590.0];
    final maxEarning = earnings.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₹${earnings.reduce((a, b) => a + b).toStringAsFixed(0)}', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final height = (earnings[index] / maxEarning) * 120;
              return Column(
                children: [
                  Text('₹${earnings[index].toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(days[index], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryEarningsList() {
    final deliveries = [
      {'date': '2024-01-15', 'orderId': 'ORD001', 'amount': 150.0, 'status': 'Paid'},
      {'date': '2024-01-15', 'orderId': 'ORD002', 'amount': 200.0, 'status': 'Paid'},
      {'date': '2024-01-14', 'orderId': 'ORD003', 'amount': 180.0, 'status': 'Pending'},
      {'date': '2024-01-14', 'orderId': 'ORD004', 'amount': 220.0, 'status': 'Paid'},
      {'date': '2024-01-13', 'orderId': 'ORD005', 'amount': 170.0, 'status': 'Paid'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: deliveries.map((delivery) {
          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: delivery['status'] == 'Paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    delivery['status'] == 'Paid' ? Icons.check_circle : Icons.pending,
                    color: delivery['status'] == 'Paid' ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Order #${delivery['orderId']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  delivery['date'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(delivery['amount'] as double).toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4CAF50)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: delivery['status'] == 'Paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        delivery['status'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: delivery['status'] == 'Paid' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (delivery != deliveries.last) Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Withdraw Earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available Balance: ₹${(_completedDeliveries.fold(0.0, (sum, d) => sum + (d['totalAmount'] as double)) * 0.7).toStringAsFixed(2)}'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showPaymentHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Payment History'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildPaymentHistoryItem('2024-01-08', '₹2,450.00', 'Completed'),
              _buildPaymentHistoryItem('2024-01-01', '₹2,180.00', 'Completed'),
              _buildPaymentHistoryItem('2023-12-25', '₹2,650.00', 'Completed'),
              _buildPaymentHistoryItem('2023-12-18', '₹2,320.00', 'Completed'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(String date, String amount, String status) {
    return ListTile(
      leading: Icon(Icons.payment, color: Colors.green),
      title: Text(amount, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(date),
      trailing: Text(status, style: TextStyle(color: Colors.green, fontSize: 12)),
    );
  }



  Widget _buildHistoryCard(Map<String, dynamic> delivery) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${delivery['id']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388E3C),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DELIVERED',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 20),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('Customer: ${delivery['customerName']}', style: TextStyle(fontSize: 14)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.agriculture, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('Farmer: ${delivery['farmerName'] ?? 'N/A'}', style: TextStyle(fontSize: 14)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('Delivered: ${delivery['deliveredAt']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Earnings: ₹${delivery['totalAmount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.share, size: 18, color: Colors.blue),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share feature coming soon!')),
                  );
                },
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.delivery_dining,
                          size: 60,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Edit profile picture coming soon!')),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt, size: 16, color: Color(0xFF4CAF50)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.user['name'] ?? 'Delivery Partner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Delivery Partner',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit profile coming soon!')),
                      );
                    },
                    icon: Icon(Icons.edit, color: Colors.white, size: 16),
                    label: Text('Edit Profile', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildProfileSection(
              'Personal Information',
              Icons.person,
              [
                _buildProfileItem('Name', widget.user['name'] ?? 'N/A'),
                _buildProfileItem('Mobile Number', widget.user['mobile_number'] ?? 'N/A'),
                _buildProfileItem('Delivery Person ID', widget.user['delivery_person_id']?.toString() ?? widget.user['id']?.toString() ?? 'N/A'),
                _buildProfileItem('Vehicle Type', widget.user['vehicle_type']?.toString().toUpperCase() ?? 'N/A'),
                _buildProfileItem('Vehicle Number', widget.user['vehicle_number'] ?? 'N/A'),
                _buildProfileItem('License Number', widget.user['license_number'] ?? 'N/A'),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileSection(
              'Earnings & Payments',
              Icons.account_balance_wallet,
              [
                _buildProfileItem('Weekly Earnings', '₹${(_deliveryStats?['totalEarnings'] ?? 0).toStringAsFixed(0)}'),
                _buildProfileItem('Monthly Earnings', '₹${((_deliveryStats?['totalEarnings'] ?? 0) * 4).toStringAsFixed(0)}'),
                _buildProfileItem('Payment Status', 'Up to date', valueColor: Colors.green),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileSection(
              'Performance Stats',
              Icons.bar_chart,
              [
                _buildProfileItem('Total Deliveries', widget.user['total_deliveries']?.toString() ?? '${_completedDeliveries.length}'),
                _buildProfileItem('Average Rating', '${widget.user['rating'] ?? _deliveryStats?['rating'] ?? 0.0} ⭐'),
                _buildProfileItem('Availability', widget.user['is_available'] == true ? 'Available' : 'Unavailable', valueColor: widget.user['is_available'] == true ? Colors.green : Colors.red),
                _buildProfileItem('Current Location', widget.user['current_location'] ?? 'Not set'),
              ],
            ),
            SizedBox(height: 16),
            _buildProfileMenuCard(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388E3C),
                ),
              ),
            ],
          ),
          Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileMenuCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: Color(0xFF4CAF50)),
            title: Text('Wallet / Earnings'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.star_rate, color: Color(0xFF4CAF50)),
            title: Text('My Ratings / Reviews'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ratings feature coming soon!'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.history, color: Color(0xFF4CAF50)),
            title: Text('Delivery History'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: Color(0xFF4CAF50)),
            title: Text('Notifications'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notifications feature coming soon!'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Color(0xFF4CAF50)),
            title: Text('Settings'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSettingsDialog(),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
            title: Text('App Info / Privacy Policy'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('App Info coming soon!'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.help_outline, color: Color(0xFF4CAF50)),
            title: Text('Help & Support / Contact Us'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showHelpSupportOptions(),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.share_outlined, color: Color(0xFF4CAF50)),
            title: Text('Share App'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share feature coming soon!'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
          ),
          Divider(height: 1, thickness: 2),
          Container(
            color: Colors.red[50],
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red[700]),
              title: Text('Logout', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red[700]),
              onTap: _confirmLogout,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Help & Support / Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.question_answer, color: Color(0xFF4CAF50)),
              title: Text('FAQ'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showFAQDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback, color: Color(0xFF4CAF50)),
              title: Text('Feedback'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showFeedbackDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_mail, color: Color(0xFF4CAF50)),
              title: Text('Contact Us'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showContactUsDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Frequently Asked Questions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem('How do I accept an order?', 'Tap on the order card and click "Accept Order" button.'),
              SizedBox(height: 12),
              _buildFAQItem('How do I mark an order as delivered?', 'After reaching the destination, tap "Mark as Delivered" button.'),
              SizedBox(height: 12),
              _buildFAQItem('How do I contact customer?', 'Use the "Call" button on the order card to contact the customer.'),
              SizedBox(height: 12),
              _buildFAQItem('When will I receive my payment?', 'Payments are processed weekly and credited to your account.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  void _showContactUsDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFF4CAF50)),
              title: Text('Email'),
              subtitle: Text('support@farmercrate.com'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Color(0xFF4CAF50)),
              title: Text('Phone'),
              subtitle: Text('+91 1234567890'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.language, color: Color(0xFF4CAF50)),
              title: Text('Website'),
              subtitle: Text('www.farmercrate.com'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Push Notifications'),
                subtitle: Text('Receive order updates'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setDialogState(() {
                    _notificationsEnabled = value;
                  });
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_notificationsEnabled ? 'Notifications enabled' : 'Notifications disabled'),
                      backgroundColor: Color(0xFF4CAF50),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                activeColor: Color(0xFF4CAF50),
              ),
              Divider(),
              ListTile(
                title: Text('Language'),
                subtitle: Text(_selectedLanguage),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageDialog();
                },
              ),
              Divider(),
              ListTile(
                title: Text('Theme'),
                subtitle: Text(_selectedTheme),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showThemeDialog();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Color(0xFF4CAF50))),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('English'),
              value: 'English',
              groupValue: _selectedLanguage,
              activeColor: Color(0xFF4CAF50),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to $_selectedLanguage'), backgroundColor: Color(0xFF4CAF50)),
                );
              },
            ),
            RadioListTile<String>(
              title: Text('தமிழ் (Tamil)'),
              value: 'Tamil',
              groupValue: _selectedLanguage,
              activeColor: Color(0xFF4CAF50),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to $_selectedLanguage'), backgroundColor: Color(0xFF4CAF50)),
                );
              },
            ),
            RadioListTile<String>(
              title: Text('हिन्दी (Hindi)'),
              value: 'Hindi',
              groupValue: _selectedLanguage,
              activeColor: Color(0xFF4CAF50),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to $_selectedLanguage'), backgroundColor: Color(0xFF4CAF50)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Light Mode'),
              subtitle: Text('Bright and clear'),
              value: 'Light Mode',
              groupValue: _selectedTheme,
              activeColor: Color(0xFF4CAF50),
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Theme changed to $_selectedTheme'), backgroundColor: Color(0xFF4CAF50)),
                );
              },
            ),
            RadioListTile<String>(
              title: Text('Dark Mode'),
              subtitle: Text('Easy on the eyes'),
              value: 'Dark Mode',
              groupValue: _selectedTheme,
              activeColor: Color(0xFF4CAF50),
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Theme changed to $_selectedTheme'), backgroundColor: Color(0xFF4CAF50)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience or suggestions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFD32F2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_outlined, color: Colors.white, size: 32),
                ),
                SizedBox(height: 20),
                Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Color(0xFF388E3C),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(),
          DeliveryHistoryPage(
            completedDeliveries: _completedDeliveries,
            historyFilter: _historyFilter,
            onFilterChanged: (value) {
              setState(() {
                _historyFilter = value;
              });
            },
          ),
          DeliveryEarningsPage(
            completedDeliveries: _completedDeliveries,
            earningsPeriod: _earningsPeriod,
            onPeriodChanged: (value) {
              setState(() {
                _earningsPeriod = value;
              });
            },
            onRefresh: _loadDeliveryData,
          ),
          DeliveryProfilePage(
            user: widget.user,
            deliveryStats: _deliveryStats,
            completedDeliveries: _completedDeliveries,
            notificationsEnabled: _notificationsEnabled,
            selectedLanguage: _selectedLanguage,
            selectedTheme: _selectedTheme,
            onNotificationsChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            onLanguageChanged: (value) {
              setState(() {
                _selectedLanguage = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language changed to $value'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
            onThemeChanged: (value) {
              setState(() {
                _selectedTheme = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Theme changed to $value'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
            onLogout: _logout,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}