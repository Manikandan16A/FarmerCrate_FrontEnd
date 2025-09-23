import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'common_navigation.dart';

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

      print('=== Fetching Orders from Database ===');
      print('API Endpoint: https://farmercrate.onrender.com/api/orders/all');
      print('Token: Present (${token.length} chars)');

      if (token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Make GET request to fetch orders from database
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/orders/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('=== API Response Details ===');
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body length: ${response.body.length}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedJson = jsonDecode(response.body);
        print('=== JSON Parsing ===');
        print('Decoded JSON structure: ${decodedJson.runtimeType}');
        print('Decoded JSON keys: ${decodedJson is Map ? decodedJson.keys.toList() : 'Not a Map'}');

        List<dynamic> ordersData = [];

        if (decodedJson is Map<String, dynamic>) {
          if (decodedJson.containsKey('data')) {
            ordersData = decodedJson['data'] ?? [];
            print('Found orders in "data" key: ${ordersData.length} items');
          } else {
            throw Exception('Expected "data" key in response: ${response.body}');
          }
        } else {
          throw Exception('Unexpected response format: ${response.body}');
        }

        print('=== Processing Database Records ===');
        print('Found ${ordersData.length} orders to parse from database');

        if (ordersData.isEmpty) {
          print('No orders found in database response');
          setState(() {
            allOrders = [];
            filteredOrders = [];
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No orders found in database'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Parse each order from database
          List<Order> parsedOrders = [];
          for (int i = 0; i < ordersData.length; i++) {
            try {
              print('Parsing order ${i + 1}: ${ordersData[i]}');
              Order order = Order.fromJson(ordersData[i]);
              parsedOrders.add(order);
              print('Successfully parsed order ${i + 1}: ${order.id}');
            } catch (e) {
              print('Error parsing order ${i + 1}: $e');
              print('Order data: ${ordersData[i]}');
            }
          }

          setState(() {
            allOrders = parsedOrders;
            _filterOrders();
            isLoading = false;
          });
          print('=== Database Records Loaded ===');
          print('Successfully loaded ${allOrders.length} orders from database');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded ${allOrders.length} orders from database'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied. You do not have permission to view orders.');
      } else if (response.statusCode == 404) {
        throw Exception('Orders endpoint not found. Please check the API configuration.');
      } else {
        throw Exception('Failed to load orders from database. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('=== Error Details ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching orders from database: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _filterOrders() {
    // Include all orders, regardless of status
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

      if (token.isEmpty) {
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
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'successful':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF757575);
    }
  }

  Widget _buildCategorySelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final categories = ['All', 'Pending', 'Completed', 'Successful', 'Cancelled'];

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
      case 'completed':
        return Icons.check_circle;
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

    // Use all orders for statistics
    final pendingCount = allOrders.where((order) => order.status.toLowerCase() == 'pending').length;
    final completedCount = allOrders.where((order) => order.status.toLowerCase() == 'completed').length;
    final cancelledCount = allOrders.where((order) => order.status.toLowerCase() == 'cancelled').length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminNavigation.buildAppBar(
        context,
        'Orders Management',
        onRefresh: () {
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
      drawer: AdminNavigation.buildDrawer(context, widget.user, widget.token),
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
                      'Completed',
                      completedCount.toString(),
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
                      ? _buildLoadingState(screenWidth, screenHeight)
                      : filteredOrders.isEmpty
                      ? RefreshIndicator(
                    onRefresh: _fetchOrders,
                    child: _buildEmptyState(screenWidth, screenHeight),
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
      bottomNavigationBar: AdminNavigation.buildBottomNavigationBar(context, _currentIndex, widget.user, widget.token),
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

  Widget _buildLoadingState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.08),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(screenWidth * 0.08),
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
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2E7D32)),
                  strokeWidth: 3,
                ),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  'Loading orders from database...',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    color: const Color(0xFF1B5E20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Please wait while we fetch your data',
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
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.08),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(screenWidth * 0.08),
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
                Icon(
                  Icons.shopping_cart_outlined,
                  size: screenWidth * 0.2,
                  color: const Color(0xFF2E7D32),
                ),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  'No orders found in database',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    color: const Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'There are currently no orders in the database',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  'Pull down to refresh and check again',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton.icon(
                  onPressed: _fetchOrders,
                  icon: Icon(Icons.refresh, size: screenWidth * 0.04),
                  label: Text('Refresh Database'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenWidth * 0.03,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final screenWidth = MediaQuery.of(context).size.width;

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
                        'Product: ${order.product.name}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF424242),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Qty: ${order.quantity}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    children: [
                      Icon(Icons.currency_rupee, size: screenWidth * 0.04, color: const Color(0xFF2E7D32)),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Total: ₹${order.totalAmount}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Commission: ₹${order.commission}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    children: [
                      Icon(Icons.payment, size: screenWidth * 0.04, color: const Color(0xFF757575)),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Payment: ${order.paymentStatus.toUpperCase()}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: order.paymentStatus == 'completed' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Transport: ₹${order.transportCharge}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF757575),
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
                        'Ordered: ${_formatDate(order.createdAt)}',
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
      case 'completed':
        return Icons.check_circle;
      case 'successful':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
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

class _OrderDetailsFullScreen extends StatefulWidget {
  final Order order;

  const _OrderDetailsFullScreen({
    required this.order,
  });

  @override
  State<_OrderDetailsFullScreen> createState() => _OrderDetailsFullScreenState();
}

class _OrderDetailsFullScreenState extends State<_OrderDetailsFullScreen> {

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenWidth * 0.02,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(widget.order.status),
                                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                              ),
                              child: Text(
                                widget.order.status.toUpperCase(),
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
                          _buildOrderInfoTileWithImage(Icons.person_outline, 'Customer Name', widget.order.customerName, widget.order.consumer.profileImage),
                          _buildOrderInfoTile(Icons.email_outlined, 'Email', widget.order.customerEmail),
                          _buildOrderInfoTile(Icons.phone_outlined, 'Phone', widget.order.customerPhone),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildOrderInfoSection(
                        'Product Information',
                        Icons.shopping_cart,
                        [
                          _buildOrderInfoTileWithImage(Icons.shopping_bag_outlined, 'Product Name', widget.order.product.name, widget.order.product.images),
                          _buildOrderInfoTile(Icons.currency_rupee, 'Product Price', '₹${widget.order.product.price}'),
                          _buildOrderInfoTile(Icons.inventory, 'Quantity', '${widget.order.quantity}'),
                          _buildOrderInfoTile(Icons.currency_rupee, 'Total Amount', '₹${widget.order.totalAmount}'),
                          _buildOrderInfoTile(Icons.access_time, 'Order Date', _formatDate(widget.order.createdAt)),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildOrderInfoSection(
                        'Financial Information',
                        Icons.account_balance_wallet,
                        [
                          _buildOrderInfoTile(Icons.currency_rupee, 'Total Amount', '₹${widget.order.totalAmount}'),
                          _buildOrderInfoTile(Icons.percent, 'Commission', '₹${widget.order.commission}'),
                          _buildOrderInfoTile(Icons.person, 'Farmer Amount', '₹${widget.order.farmerAmount}'),
                          _buildOrderInfoTile(Icons.local_shipping, 'Transport Charge', '₹${widget.order.transportCharge}'),
                          _buildOrderInfoTile(Icons.payment, 'Payment Status', widget.order.paymentStatus.toUpperCase()),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildOrderInfoSection(
                        'Farmer Information',
                        Icons.agriculture,
                        [
                          _buildOrderInfoTileWithImage(Icons.person_outline, 'Farmer Name', widget.order.farmer.name, widget.order.farmer.profileImage),
                          _buildOrderInfoTile(Icons.email_outlined, 'Farmer Email', widget.order.farmer.email),
                          _buildOrderInfoTile(Icons.phone_outlined, 'Farmer Phone', widget.order.farmer.mobileNumber),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildOrderInfoSection(
                        'Delivery Information',
                        Icons.local_shipping,
                        [
                          _buildOrderInfoTile(Icons.location_on_outlined, 'Delivery Address', widget.order.deliveryAddress),
                          _buildOrderInfoTileWithImage(Icons.person_outline, 'Delivery Person', widget.order.deliveryPerson.name, widget.order.deliveryPerson.profileImage),
                          _buildOrderInfoTile(Icons.phone_outlined, 'Delivery Phone', widget.order.deliveryPerson.mobileNumber),
                          _buildOrderInfoTile(Icons.directions_car, 'Vehicle Number', widget.order.deliveryPerson.vehicleNumber),
                        ],
                        screenWidth,
                      ),
                      if (widget.order.notes.isNotEmpty) ...[
                        SizedBox(height: screenWidth * 0.05),
                        _buildOrderInfoSection(
                          'Additional Notes',
                          Icons.notes,
                          [
                            _buildOrderInfoTile(Icons.note_outlined, 'Notes', widget.order.notes),
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
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'successful':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF757575);
    }
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
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

  Widget _buildOrderInfoTileWithImage(IconData icon, String label, String value, String imageUrl) {
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
          // Profile/Product Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF2E7D32),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    child: Icon(
                      icon,
                      color: const Color(0xFF2E7D32),
                      size: 24,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                      ),
                    ),
                  );
                },
              )
                  : Container(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                child: Icon(
                  icon,
                  color: const Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
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

class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String status;
  final int quantity;
  final double totalAmount;
  final double commission;
  final double farmerAmount;
  final String deliveryAddress;
  final String paymentStatus;
  final String farmerId;
  final String consumerId;
  final String productId;
  final String deliveryPersonId;
  final double transportCharge;
  final String createdAt;
  final String updatedAt;
  final Product product;
  final Farmer farmer;
  final Consumer consumer;
  final DeliveryPerson deliveryPerson;

  Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.status,
    required this.quantity,
    required this.totalAmount,
    required this.commission,
    required this.farmerAmount,
    required this.deliveryAddress,
    required this.paymentStatus,
    required this.farmerId,
    required this.consumerId,
    required this.productId,
    required this.deliveryPersonId,
    required this.transportCharge,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    required this.farmer,
    required this.consumer,
    required this.deliveryPerson,
  });

  int get itemCount => quantity;
  String get deliveryDate => '';
  String get notes => '';

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing order JSON: $json');

      String orderId = json['id']?.toString() ?? '';
      String status = json['status']?.toString() ?? 'pending';
      int quantity = json['quantity']?.toInt() ?? 0;
      double totalAmount = double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0;
      double commission = double.tryParse(json['commission']?.toString() ?? '0') ?? 0.0;
      double farmerAmount = double.tryParse(json['farmer_amount']?.toString() ?? '0') ?? 0.0;
      String deliveryAddress = json['delivery_address']?.toString() ?? '';
      String paymentStatus = json['payment_status']?.toString() ?? 'pending';
      String farmerId = json['farmer_id']?.toString() ?? '';
      String consumerId = json['consumer_id']?.toString() ?? '';
      String productId = json['product_id']?.toString() ?? '';
      String deliveryPersonId = json['delivery_person_id']?.toString() ?? '';
      double transportCharge = double.tryParse(json['transport_charge']?.toString() ?? '0') ?? 0.0;
      String createdAt = json['created_at']?.toString() ?? '';
      String updatedAt = json['updated_at']?.toString() ?? '';

      Product product = Product.fromJson(json['product'] ?? {});
      Farmer farmer = Farmer.fromJson(json['farmer'] ?? {});
      Consumer consumer = Consumer.fromJson(json['consumer'] ?? {});
      DeliveryPerson deliveryPerson = DeliveryPerson.fromJson(json['delivery_person'] ?? {});

      return Order(
        id: orderId,
        customerName: consumer.customerName,
        customerEmail: consumer.email,
        customerPhone: consumer.mobileNumber,
        status: status,
        quantity: quantity,
        totalAmount: totalAmount,
        commission: commission,
        farmerAmount: farmerAmount,
        deliveryAddress: deliveryAddress,
        paymentStatus: paymentStatus,
        farmerId: farmerId,
        consumerId: consumerId,
        productId: productId,
        deliveryPersonId: deliveryPersonId,
        transportCharge: transportCharge,
        createdAt: createdAt,
        updatedAt: updatedAt,
        product: product,
        farmer: farmer,
        consumer: consumer,
        deliveryPerson: deliveryPerson,
      );
    } catch (e) {
      print('Error parsing order JSON: $e');
      print('JSON data: $json');
      return Order(
        id: json['id']?.toString() ?? 'Unknown',
        customerName: 'Unknown Customer',
        customerEmail: 'unknown@email.com',
        customerPhone: 'Unknown',
        status: 'pending',
        quantity: 0,
        totalAmount: 0.0,
        commission: 0.0,
        farmerAmount: 0.0,
        deliveryAddress: 'Address not provided',
        paymentStatus: 'pending',
        farmerId: '',
        consumerId: '',
        productId: '',
        deliveryPersonId: '',
        transportCharge: 0.0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        product: Product(name: 'Unknown', price: 0.0, images: ''),
        farmer: Farmer(name: 'Unknown', email: '', mobileNumber: '', profileImage: ''),
        consumer: Consumer(customerName: 'Unknown', email: '', mobileNumber: '', profileImage: ''),
        deliveryPerson: DeliveryPerson(name: 'Unknown', mobileNumber: '', vehicleNumber: '', profileImage: ''),
      );
    }
  }
}

class Product {
  final String name;
  final double price;
  final String images;

  Product({
    required this.name,
    required this.price,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name']?.toString() ?? 'Unknown Product',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      images: json['images']?.toString() ?? '',
    );
  }
}

class Farmer {
  final String name;
  final String email;
  final String mobileNumber;
  final String profileImage;

  Farmer({
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.profileImage,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      name: json['name']?.toString() ?? 'Unknown Farmer',
      email: json['email']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      profileImage: json['image_url']?.toString() ?? '',
    );
  }
}

class Consumer {
  final String customerName;
  final String email;
  final String mobileNumber;
  final String profileImage;

  Consumer({
    required this.customerName,
    required this.email,
    required this.mobileNumber,
    required this.profileImage,
  });

  factory Consumer.fromJson(Map<String, dynamic> json) {
    return Consumer(
      customerName: json['customer_name']?.toString() ?? 'Unknown Customer',
      email: json['email']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      profileImage: json['image_url']?.toString() ?? '',
    );
  }
}

class DeliveryPerson {
  final String name;
  final String mobileNumber;
  final String vehicleNumber;
  final String profileImage;

  DeliveryPerson({
    required this.name,
    required this.mobileNumber,
    required this.vehicleNumber,
    required this.profileImage,
  });

  factory DeliveryPerson.fromJson(Map<String, dynamic> json) {
    return DeliveryPerson(
      name: json['name']?.toString() ?? 'Unknown Delivery Person',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      profileImage: json['profile_image']?.toString() ?? '',
    );
  }
}