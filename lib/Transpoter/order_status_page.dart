import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'qrscan.dart';
import 'bill_preview_page.dart';
import 'transporter_dashboard.dart';
import 'order_history_page.dart';
import 'vehicle_page.dart';
import 'profile_page.dart';
import 'navigation_utils.dart';
import 'transporter_order_tracking.dart';

class OrderStatusPage extends StatefulWidget {
  final String? token;

  const OrderStatusPage({super.key, this.token});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  List<dynamic> sourceOrders = [];
  List<dynamic> destinationOrders = [];
  bool isLoading = true;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/orders/transporter/allocated'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allOrders = data['data'] ?? [];
        setState(() {
          sourceOrders = allOrders.where((order) => 
            order['transporter_role'] == 'PICKUP_SHIPPING' && 
            order['current_status'] != 'COMPLETED' && 
            order['current_status'] != 'CANCELLED'
          ).toList();
          destinationOrders = allOrders.where((order) => 
            order['transporter_role'] == 'DELIVERY' && 
            order['current_status'] != 'COMPLETED' && 
            order['current_status'] != 'CANCELLED'
          ).toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showSnackBar('Failed to load orders', isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    Widget page;
    switch (index) {
      case 0:
        page = TransporterDashboard(token: widget.token);
        break;
      case 2:
        page = OrderHistoryPage(token: widget.token);
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TransporterDashboard(token: widget.token)),
        );
        return false;
      },
      child: Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        title: Text('Order Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRScanPage(token: widget.token)),
              );
              _fetchOrders();
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      drawer: TransporterNavigationUtils.buildTransporterDrawer(context, widget.token, _selectedIndex, _onNavItemTapped),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.upload, color: Color(0xFF2196F3), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text('Source Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    SizedBox(height: 12),
                    sourceOrders.isEmpty
                        ? _buildEmptyState('No source orders')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: sourceOrders.length,
                            itemBuilder: (context, index) => _buildOrderCard(sourceOrders[index], true),
                          ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF9C27B0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.download, color: Color(0xFF9C27B0), size: 20),
                        ),
                        SizedBox(width: 12),
                        Text('Destination Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    SizedBox(height: 12),
                    destinationOrders.isEmpty
                        ? _buildEmptyState('No destination orders')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: destinationOrders.length,
                            itemBuilder: (context, index) => _buildOrderCard(destinationOrders[index], false),
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QRScanPage(token: widget.token)),
          );
          _fetchOrders();
        },
        backgroundColor: Color(0xFF2E7D32),
        icon: Icon(Icons.qr_code_scanner, color: Colors.white),
        label: Text('Scan QR', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          selectedItemColor: Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 13,
          unselectedFontSize: 12,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.dashboard, size: 24),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.track_changes, size: 24),
              ),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history, size: 24),
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 3 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.local_shipping, size: 24),
              ),
              label: 'Vehicles',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 4 ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, size: 24),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isSource) {
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (imageUrl != null)
                      Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey)),
                        ),
                      ),
                    Expanded(child: Text(product?['name'] ?? 'N/A', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSource ? Color(0xFF2196F3) : Color(0xFF9C27B0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(isSource ? 'SOURCE' : 'DESTINATION', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status ?? 'N/A', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              SizedBox(width: 4),
              Expanded(child: Text(order['delivery_address'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                  Text('${order['total_price'] ?? 0}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  SizedBox(width: 12),
                  Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text('Qty: ${order['quantity'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  if (status != 'COMPLETED' && status != 'DELIVERED' && status != 'CANCELLED')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransporterOrderTrackingPage(
                              token: widget.token,
                              orderId: order['order_id']?.toString(),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.location_on, size: 16),
                      label: Text('Track', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  if (status == 'ASSIGNED')
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BillPreviewPage(order: order, token: widget.token)),
                        );
                        _fetchOrders();
                      },
                      icon: Icon(Icons.receipt_long, size: 16),
                      label: Text('Bill', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PLACED': return Color(0xFFFFA726);
      case 'SHIPPED': return Color(0xFF42A5F5);
      case 'RECEIVED': return Color(0xFF66BB6A);
      case 'IN_TRANSIT': return Color(0xFFAB47BC);
      case 'ASSIGNED': return Color(0xFF66BB6A);
      case 'OUT_FOR_DELIVERY': return Color(0xFFFF9800);
      case 'COMPLETED': return Color(0xFF4CAF50);
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(message, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
