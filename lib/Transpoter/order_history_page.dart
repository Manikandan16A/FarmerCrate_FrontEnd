import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'transporter_dashboard.dart';
import 'order_status_page.dart';
import 'vehicle_page.dart';
import 'profile_page.dart';
import 'transporter_order_tracking.dart';

class OrderHistoryPage extends StatefulWidget {
  final String? token;

  const OrderHistoryPage({super.key, this.token});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> sourceOrders = [];
  List<dynamic> destinationOrders = [];
  bool isLoading = true;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _fetchAllOrders();
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false, bool isInfo = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      ),
    );

    await Future.delayed(Duration(milliseconds: 500));
    Navigator.of(context, rootNavigator: true).pop();

    Color backgroundColor;
    IconData icon;
    if (isError) {
      backgroundColor = Color(0xFFD32F2F);
      icon = Icons.error_outline;
    } else if (isWarning) {
      backgroundColor = Color(0xFFFF9800);
      icon = Icons.warning_amber;
    } else if (isInfo) {
      backgroundColor = Color(0xFF2196F3);
      icon = Icons.info_outline;
    } else {
      backgroundColor = Color(0xFF2E7D32);
      icon = Icons.check_circle;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  Future<void> _fetchAllOrders() async {
    setState(() => isLoading = true);
    try {
      print('DEBUG: Fetching completed orders...');
      final url = 'https://farmercrate.onrender.com/api/orders/transporter/allocated';
      print('DEBUG: API URL: $url');
      print('DEBUG: Token length: ${widget.token?.length ?? 0}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allOrders = data['data'] ?? [];
        print('DEBUG: Total orders received: ${allOrders.length}');
        
        final srcOrders = allOrders.where((order) => 
          order['transporter_role'] == 'PICKUP_SHIPPING'
        ).toList();
        final destOrders = allOrders.where((order) => 
          order['transporter_role'] == 'DELIVERY'
        ).toList();
        
        print('DEBUG: Source Orders Count: ${srcOrders.length}');
        print('DEBUG: Destination Orders Count: ${destOrders.length}');
        
        setState(() {
          sourceOrders = srcOrders;
          destinationOrders = destOrders;
          isLoading = false;
        });
      } else {
        print('DEBUG: API request failed with status ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('DEBUG: Error fetching orders: $e');
      setState(() => isLoading = false);
    }
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    Widget page;
    switch (index) {
      case 0:
        page = TransporterDashboard(token: widget.token);
        break;
      case 1:
        page = OrderStatusPage(token: widget.token);
        break;
      case 3:
        page = VehiclePage(token: widget.token);
        break;
      case 4:
        page = ProfilePage(token: widget.token);
        break;
      default:
        return;
    }
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        title: Text('Order History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAllOrders,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _fetchAllOrders,
              child: sourceOrders.isEmpty && destinationOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('No order history', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sourceOrders.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2E7D32).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.upload, color: Color(0xFF2E7D32), size: 20),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Source Orders (${sourceOrders.length})',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ...sourceOrders.map((order) => _buildOrderCard(order)),
                            SizedBox(height: 24),
                          ],
                          if (destinationOrders.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2E7D32).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.download, color: Color(0xFF2E7D32), size: 20),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Destination Orders (${destinationOrders.length})',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ...destinationOrders.map((order) => _buildOrderCard(order)),
                          ],
                        ],
                      ),
                    ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final product = order['product'];
    final images = product?['images'] as List?;
    dynamic primaryImage;
    if (images != null && images.isNotEmpty) {
      try {
        primaryImage = images.firstWhere((img) => img['is_primary'] == true);
      } catch (e) {
        primaryImage = images.first;
      }
    }
    final imageUrl = primaryImage?['image_url'];
    final status = order['current_status'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (imageUrl != null)
                      Container(
                        width: 70,
                        height: 70,
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey, size: 32),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product?['name'] ?? 'N/A',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status ?? ''),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status ?? 'N/A',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                              Text(
                                '${order['total_price'] ?? 0}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                'Qty: ${order['quantity'] ?? 0}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (status?.toUpperCase() != 'COMPLETED' && status?.toUpperCase() != 'CANCELLED') ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransporterOrderTrackingPage(
                              token: widget.token,
                              orderId: order['order_id'].toString(),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.track_changes, size: 18),
                      label: Text('Track Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Color(0xFF4CAF50);
      case 'CANCELLED':
        return Colors.red;
      case 'RECEIVED':
        return Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  void _showOrderDetails(dynamic order) {
    String addressLabel = 'Source Address';
    String addressValue = order['pickup_address'] ?? 'N/A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Order #${order['order_id'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailSection(
                      'Product Information',
                      Icons.inventory,
                      [
                        _buildDetailRow('Name', order['product']?['name'] ?? 'N/A'),
                        _buildDetailRow('Quantity', '${order['quantity'] ?? 0} kg'),
                        _buildDetailRow('Price', '₹${order['total_price'] ?? 0}'),
                        _buildDetailRow('Status', order['current_status'] ?? 'N/A'),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildDetailSection(
                      'Delivery Information',
                      Icons.local_shipping,
                      [
                        _buildDetailRow(addressLabel, addressValue),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
