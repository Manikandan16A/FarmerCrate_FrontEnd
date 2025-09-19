import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Signin.dart';
import 'ConsumerManagement.dart';
import 'Farmeruser.dart';
import 'adminreport.dart';
import 'requstaccept.dart';

class OrdersManagementPage extends StatefulWidget {
  final dynamic user;
  final String token;
  const OrdersManagementPage({Key? key, required this.user, required this.token}) : super(key: key);

  @override
  State<OrdersManagementPage> createState() => _OrdersManagementPageState();
}

class _OrdersManagementPageState extends State<OrdersManagementPage> {
  List<Order> allOrders = [];
  List<Order> filteredOrders = [];
  bool isLoading = true;
  int _currentIndex = 1; // Orders tab is selected
  String selectedCategory = 'All'; // Default selection

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = widget.token;

      print('=== Fetching Orders ===');
      print('Token: ${token != null ? 'Present (${token.length} chars)' : 'Not found'}');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedJson = jsonDecode(response.body);

        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson.containsKey('orders') || decodedJson.containsKey('data')) {
            final List<dynamic> data = decodedJson['orders'] ?? decodedJson['data'] ?? [];
            setState(() {
              allOrders = data.map((json) => Order.fromJson(json)).toList();
              _filterOrders();
              isLoading = false;
            });
            print('Successfully loaded ${allOrders.length} orders');
          } else if (decodedJson.containsKey('success') && decodedJson['success'] == true) {
            final List<dynamic> data = decodedJson['data'] ?? [];
            setState(() {
              allOrders = data.map((json) => Order.fromJson(json)).toList();
              _filterOrders();
              isLoading = false;
            });
          } else {
            throw Exception('Unexpected response structure: ${response.body}');
          }
        } else if (decodedJson is List) {
          setState(() {
            allOrders = decodedJson.map((json) => Order.fromJson(json)).toList();
            _filterOrders();
            isLoading = false;
          });
          print('Successfully loaded ${allOrders.length} orders from direct array');
        } else {
          throw Exception('Unexpected response format: ${response.body}');
        }
      } else {
        throw Exception('Failed to load orders. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching orders: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      print('Error details: $e');
    }
  }

  void _filterOrders() {
    if (selectedCategory == 'All') {
      filteredOrders = allOrders;
    } else {
      filteredOrders = allOrders.where((order) =>
      order.status.toLowerCase() == selectedCategory.toLowerCase()
      ).toList();
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final token = widget.token;

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final response = await http.patch(
        Uri.parse('https://farmercrate.onrender.com/api/admin/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: _getStatusColor(newStatus),
            duration: Duration(seconds: 2),
          ),
        );
        _fetchOrders(); // Refresh the list
      } else {
        throw Exception('Failed to update order status. Status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFD32F2F);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF757575);
    }
  }

  Widget _buildCategorySelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final categories = ['All', 'Pending', 'Successful', 'Cancelled'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
      height: screenWidth * 0.12,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
                _filterOrders();
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: screenWidth * 0.02),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.02,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                )
                    : null,
                color: isSelected ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(screenWidth * 0.06),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: screenWidth * 0.02,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.list_alt;
      case 'pending':
        return Icons.pending_actions;
      case 'successful':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final pendingCount = allOrders.where((order) => order.status.toLowerCase() == 'pending').length;
    final successfulCount = allOrders.where((order) => order.status.toLowerCase() == 'successful' || order.status.toLowerCase() == 'completed').length;
    final cancelledCount = allOrders.where((order) => order.status.toLowerCase() == 'cancelled' || order.status.toLowerCase() == 'canceled').length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 5,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.green[800]),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Orders Management',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.green[800]),
            onPressed: () {
              _fetchOrders();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Refreshing orders list...'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.green[800]),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[600],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FarmerCrate Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.green[600]),
              title: const Text('Home'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminManagementPage(
                      user: widget.user,
                      token: widget.token,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.pending_actions, color: Colors.green[600]),
              title: const Text('User Management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUserManagementPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: Colors.green[600]),
              title: const Text('Consumer Management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.green[600]),
              title: const Text('Total Orders'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.green[600]),
              title: const Text('Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportsPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[600]),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFC8E6C9),
              Color(0xFFA5D6A7),
              Color(0xFF81C784),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders Management',
                      style: TextStyle(
                        fontSize: screenWidth * 0.07,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Track and manage all customer orders',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCategorySelector(),
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: screenWidth * 0.025,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Orders',
                      allOrders.length.toString(),
                      Icons.shopping_cart,
                    ),
                    Container(
                      height: screenHeight * 0.06,
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    _buildStatItem(
                      'Successful',
                      successfulCount.toString(),
                      Icons.check_circle,
                    ),
                    Container(
                      height: screenHeight * 0.06,
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    _buildStatItem(
                      'Pending',
                      pendingCount.toString(),
                      Icons.pending,
                    ),
                    Container(
                      height: screenHeight * 0.06,
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    _buildStatItem(
                      'Cancelled',
                      cancelledCount.toString(),
                      Icons.cancel,
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredOrders.isEmpty
                      ? RefreshIndicator(
                    onRefresh: _fetchOrders,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: screenWidth * 0.2,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Pull down to refresh',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: _fetchOrders,
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.025),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.blueGrey,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          currentIndex: _currentIndex,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            

            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminManagementPage(
                    user: widget.user,
                    token: widget.token,
                  ),
                ),
              );
            } else if (index == 1) {
              // Already on orders page, do nothing
            } else if (index == 2) { // Reports tab
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportsPage(),
                ),
              );
            }

          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart, size: 24),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions, size: 24),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics, size: 24),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2E7D32),
          size: screenWidth * 0.06,
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: const Color(0xFF424242),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: screenWidth * 0.025,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(order.status),
                        _getStatusColor(order.status).withOpacity(0.8)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.06),
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: Colors.white,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: screenWidth * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status),
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        order.customerName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: const Color(0xFF424242),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        order.customerEmail,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_bag, size: screenWidth * 0.04, color: const Color(0xFF757575)),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Items: ${order.itemCount}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF424242),
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.currency_rupee, size: screenWidth * 0.04, color: const Color(0xFF2E7D32)),
                      Text(
                        '${order.totalAmount}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: screenWidth * 0.04, color: const Color(0xFF757575)),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Ordered: ${order.createdAt}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  if (order.deliveryAddress.isNotEmpty) ...[
                    SizedBox(height: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: screenWidth * 0.04, color: const Color(0xFF757575)),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: const Color(0xFF757575),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            Row(
              children: [
                if (order.status.toLowerCase() == 'pending') ...[
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _updateOrderStatus(order.id, 'successful'),
                        icon: Icon(Icons.check, size: screenWidth * 0.04),
                        label: Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      child: ElevatedButton.icon(
                        onPressed: () => _updateOrderStatus(order.id, 'cancelled'),
                        icon: Icon(Icons.close, size: screenWidth * 0.04),
                        label: Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          ),
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showOrderDetailsDialog(order),
                      icon: Icon(Icons.info_outline, size: screenWidth * 0.04),
                      label: Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  void _showOrderDetailsDialog(Order order) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _OrderDetailsFullScreen(order: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}

// Order Details Full Screen
class _OrderDetailsFullScreen extends StatelessWidget {
  final Order order;

  const _OrderDetailsFullScreen({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E8),
              Color(0xFFC8E6C9),
              Color(0xFFA5D6A7),
              Color(0xFF81C784),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Order #${order.id}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenWidth * 0.02,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status),
                                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildOrderInfoSection(
                        'Customer Information',
                        Icons.person,
                        [
                          _buildOrderInfoTile(Icons.person_outline, 'Customer Name', order.customerName),
                          _buildOrderInfoTile(Icons.email_outlined, 'Email', order.customerEmail),
                          _buildOrderInfoTile(Icons.phone_outlined, 'Phone', order.customerPhone),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildOrderInfoSection(
                        'Order Information',
                        Icons.shopping_cart,
                        [
                          _buildOrderInfoTile(Icons.shopping_bag_outlined, 'Items Count', '${order.itemCount}'),
                          _buildOrderInfoTile(Icons.currency_rupee, 'Total Amount', '₹${order.totalAmount}'),
                          _buildOrderInfoTile(Icons.access_time, 'Order Date', order.createdAt),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildOrderInfoSection(
                        'Delivery Information',
                        Icons.local_shipping,
                        [
                          _buildOrderInfoTile(Icons.location_on_outlined, 'Delivery Address', order.deliveryAddress),
                          _buildOrderInfoTile(Icons.schedule, 'Delivery Date', order.deliveryDate.isNotEmpty ? order.deliveryDate : 'Not scheduled'),
                        ],
                        screenWidth,
                      ),
                      if (order.notes.isNotEmpty) ...[
                        SizedBox(height: screenWidth * 0.05),
                        _buildOrderInfoSection(
                          'Additional Notes',
                          Icons.notes,
                          [
                            _buildOrderInfoTile(Icons.note_outlined, 'Notes', order.notes),
                          ],
                          screenWidth,
                        ),
                      ],
                      SizedBox(height: screenWidth * 0.08),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFD32F2F);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF757575);
    }
  }

  Widget _buildOrderInfoSection(String title, IconData icon, List<Widget> children, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOrderInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.isEmpty ? const Color(0xFF9E9E9E) : const Color(0xFF424242),
                    fontWeight: FontWeight.w600,
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

// Order Model
class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String status;
  final int itemCount;
  final double totalAmount;
  final String deliveryAddress;
  final String deliveryDate;
  final String createdAt;
  final String notes;

  Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.status,
    required this.itemCount,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.deliveryDate,
    required this.createdAt,
    required this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing order JSON: $json');

      return Order(
        id: json['id']?.toString() ?? json['order_id']?.toString() ?? '',
        customerName: json['customer_name'] ?? json['customerName'] ?? json['user_name'] ?? '',
        customerEmail: json['customer_email'] ?? json['customerEmail'] ?? json['user_email'] ?? '',
        customerPhone: json['customer_phone'] ?? json['customerPhone'] ?? json['user_phone'] ?? '',
        status: json['status'] ?? json['order_status'] ?? 'pending',
        itemCount: json['item_count'] ?? json['itemCount'] ?? json['items_count'] ?? 1,
        totalAmount: (json['total_amount'] ?? json['totalAmount'] ?? json['amount'] ?? 0).toDouble(),
        deliveryAddress: json['delivery_address'] ?? json['deliveryAddress'] ?? json['address'] ?? '',
        deliveryDate: json['delivery_date'] ?? json['deliveryDate'] ?? '',
        createdAt: json['created_at'] ?? json['createdAt'] ?? json['order_date'] ?? '',
        notes: json['notes'] ?? json['special_instructions'] ?? '',
      );
    } catch (e) {
      print('Error parsing order JSON: $e');
      print('JSON data: $json');
      // Return a default order object if parsing fails
      return Order(
        id: '0',
        customerName: 'Error parsing order data',
        customerEmail: '',
        customerPhone: '',
        status: 'unknown',
        itemCount: 0,
        totalAmount: 0.0,
        deliveryAddress: '',
        deliveryDate: '',
        createdAt: '',
        notes: '',
      );
    }
  }
}