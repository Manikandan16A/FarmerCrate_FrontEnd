import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Signin.dart';
import 'order_details.dart';


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

  // Sample data - replace with actual API calls
  List<Map<String, dynamic>> _assignedOrders = [];
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
      // Fetch assigned orders from API - using the correct endpoint
      final endpoint = 'https://farmercrate.onrender.com/api/delivery-persons/orders';

      http.Response? response;
      String? lastError;

      try {
        response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        lastError = e.toString();
      }

      // If no working endpoint found, handle error
      if (response == null || response.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load delivery data. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }

        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (response!.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            // Filter assigned orders (OUT_FOR_DELIVERY status)
            _assignedOrders = List<Map<String, dynamic>>.from(
                responseData['data'].where((order) =>
                order['status'] == 'OUT_FOR_DELIVERY'
                ).map((order) => {
                  'id': order['order_id']?.toString() ?? 'N/A',
                  'customerName': 'Customer', // Will be fetched from order details
                  'address': order['delivery_address'] ?? 'No address provided',
                  'phone': 'N/A', // Will be fetched from order details
                  'items': 0, // Will be fetched from order details
                  'totalAmount': 0.0, // Will be fetched from order details
                  'status': order['status'] ?? 'unknown',
                  'deliveryTime': order['assigned_at'] ?? 'Not specified',
                  'orderDate': order['assigned_at'] ?? 'Unknown date',
                })
            );

            // Filter completed deliveries (COMPLETED status)
            _completedDeliveries = List<Map<String, dynamic>>.from(
                responseData['data'].where((order) =>
                order['status'] == 'COMPLETED'
                ).map((order) => {
                  'id': order['order_id']?.toString() ?? 'N/A',
                  'customerName': 'Customer', // Will be fetched from order details
                  'address': order['delivery_address'] ?? 'No address provided',
                  'deliveredAt': order['assigned_at'] ?? 'Unknown date',
                  'totalAmount': 0.0, // Will be fetched from order details
                })
            );

            // Calculate stats
            _deliveryStats = {
              'todayDeliveries': _completedDeliveries.length,
              'totalEarnings': _completedDeliveries.fold(0.0, (sum, order) => sum + (order['totalAmount'] as double)),
              'rating': 4.8, // This would come from a separate API endpoint
              'activeOrders': _assignedOrders.length,
            };
          });
        } else {
          throw Exception('Invalid response format: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else if (response!.statusCode == 401) {
        // Handle unauthorized access
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        await Future.delayed(Duration(seconds: 3));
        _logout();
      } else {
        throw Exception('Failed to fetch orders: ${response!.statusCode} - ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load delivery data. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      // Keep existing data on error, don't overwrite with empty data
      setState(() {
        _assignedOrders = _assignedOrders.isEmpty ? [] : _assignedOrders;
        _completedDeliveries = _completedDeliveries.isEmpty ? [] : _completedDeliveries;
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

  Widget _buildDashboardView() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            SizedBox(height: 20),

            // Stats Cards
            _buildStatsCards(),
            SizedBox(height: 20),

            // Today's Orders
            _buildSectionTitle('Today\'s Deliveries'),
            SizedBox(height: 12),
            _buildOrdersList(),
          ],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.delivery_dining,
                  size: 30,
                  color: Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.user['name'] ?? 'Delivery Partner'}!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ID: ${widget.user['id'] ?? 'N/A'} • Ready to make deliveries today',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Orders',
            '${_deliveryStats?['activeOrders'] ?? 0}',
            Icons.shopping_bag,
            Colors.orange,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Today\'s Deliveries',
            '${_deliveryStats?['todayDeliveries'] ?? 0}',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Earnings',
            '₹${_deliveryStats?['totalEarnings']?.toStringAsFixed(0) ?? '0'}',
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF388E3C),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading orders...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_assignedOrders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8),
              Text(
                'No active deliveries',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Check back later for new assignments',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))),
                Expanded(flex: 3, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))),
                Expanded(flex: 4, child: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))),
                Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))),
              ],
            ),
          ),
          // Orders List
          ..._assignedOrders.map((order) => _buildOrderTableRow(order)).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderTableRow(Map<String, dynamic> order) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Order ID
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order['id']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF388E3C),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  order['orderDate']?.toString().substring(0, 10) ?? 'N/A',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Customer Information
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['customerName'],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      order['phone'],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Delivery Address
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['address'],
                  style: TextStyle(
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  order['deliveryTime'],
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Total Amount
          Expanded(
            flex: 2,
            child: Text(
              '₹${order['totalAmount'].toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(order['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order['status'].toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(order['status']),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.visibility, size: 18, color: Color(0xFF4CAF50)),
                  onPressed: () => _showOrderDetails(order),
                  tooltip: 'View Details',
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsPage(
          order: order,
          token: widget.token,
          onOrderCompleted: () {
            // Refresh the dashboard when returning from order details
            _loadDeliveryData();
          },
        ),
      ),
    );
  }



  Widget _buildHistoryView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Delivery History'),
            SizedBox(height: 12),
            if (_completedDeliveries.isEmpty)
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
                        'No delivery history yet',
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
                children: _completedDeliveries.map((delivery) => _buildHistoryCard(delivery)).toList(),
              ),
          ],
        ),
      ),
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
          SizedBox(height: 8),
          Text(
            'Customer: ${delivery['customerName']}',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Delivered: ${delivery['deliveredAt']}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Amount: ₹${delivery['totalAmount'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
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
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.delivery_dining,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
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
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(20),
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
                  _buildProfileItem('Mobile Number', widget.user['mobile_number'] ?? 'N/A'),
                  SizedBox(height: 16),
                  _buildProfileItem('User ID', widget.user['id'].toString()),
                  SizedBox(height: 16),
                  _buildProfileItem('Role', widget.user['role']?.toUpperCase() ?? 'N/A'),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF388E3C),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Dashboard'),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Show refresh indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refreshing orders...'),
                  duration: Duration(seconds: 1),
                ),
              );
              _loadDeliveryData();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(),
          _buildHistoryView(),
          _buildProfileView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey[600],
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
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