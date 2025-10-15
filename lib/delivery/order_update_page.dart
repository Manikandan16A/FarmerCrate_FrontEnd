import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderUpdatePage extends StatefulWidget {
  final String orderId;
  final String token;
  final Map<String, dynamic> orderDetails;

  const OrderUpdatePage({
    Key? key,
    required this.orderId,
    required this.token,
    required this.orderDetails,
  }) : super(key: key);

  @override
  _OrderUpdatePageState createState() => _OrderUpdatePageState();
}

class _OrderUpdatePageState extends State<OrderUpdatePage> {
  bool _isUpdating = false;
  bool _isLoading = true;
  String _currentStatus = 'IN_TRANSIT';
  Map<String, dynamic>? _orderData;

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false, bool isInfo = false}) {
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
      backgroundColor = Color(0xFF4CAF50);
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
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        elevation: 6,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchOrderStatus();
  }

  Future<void> _fetchOrderStatus() async {
    try {
      print('\n=== FETCHING ORDER STATUS ===');
      print('Order ID: ${widget.orderId}');
      
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/delivery-persons/orders'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final orders = responseData['data'] as List;
          final order = orders.firstWhere(
            (o) => o['order_id']?.toString() == widget.orderId,
            orElse: () => null,
          );
          
          if (order != null) {
            setState(() {
              _currentStatus = order['current_status']?.toString().toUpperCase() ?? 'IN_TRANSIT';
              _orderData = order;
              _isLoading = false;
            });
            print('Current Status from DB: $_currentStatus');
          }
        }
      }
    } catch (e) {
      print('Error fetching order status: $e');
      setState(() {
        _isLoading = false;
      });
    }
    print('=============================\n');
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      print('\n=== UPDATE ORDER STATUS ===');
      print('Order ID: ${widget.orderId}');
      print('New Status: $newStatus');
      print('Token: ${widget.token}');
      
      final url = 'https://farmercrate.onrender.com/api/orders/status';
      print('URL: $url');
      
      final requestBody = jsonEncode({
        'order_id': int.parse(widget.orderId),
        'status': newStatus
      });
      print('Request Body: $requestBody');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('===========================\n');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (mounted) {
          setState(() {
            _currentStatus = newStatus;
          });
          
          _showSnackBar(newStatus == 'OUT_FOR_DELIVERY' ? 'Order marked as out for delivery' : 'Order completed successfully');
          
          // Navigate back to dashboard after successful update
          await Future.delayed(Duration(milliseconds: 500));
          Navigator.pop(context, true);
        }
      } else if (response.statusCode == 403) {
        print('[ERROR] Access denied. Delivery person does not have permission to update order status.');
        print('[ERROR] Backend needs to allow delivery role to access PUT /api/orders/status endpoint');
        throw Exception('Access denied. Please contact administrator.');
      } else {
        print('[ERROR] Failed to update order. Status: ${response.statusCode}');
        throw Exception('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      print('[EXCEPTION] Error updating order status: $e');
      if (mounted) {
        _showSnackBar('Failed to update order status: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.orderDetails;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Update Order', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    order['productName'] ?? 'Product',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentStatus.replaceAll('_', ' '),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildInfoCard(
              'Product Details',
              Icons.shopping_bag,
              [
                _buildInfoRow('Product', order['productName'] ?? 'N/A'),
                _buildInfoRow('Quantity', order['quantity']?.toString() ?? 'N/A'),
                _buildInfoRow('Total Amount', '₹${order['totalAmount']?.toStringAsFixed(2) ?? '0'}'),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              'Customer Details',
              Icons.person,
              [
                _buildInfoRow('Name', order['customerName'] ?? 'N/A'),
                _buildInfoRow('Phone', order['phone'] ?? 'N/A'),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoCard(
              'Delivery Address',
              Icons.location_on,
              [
                Text(
                  order['deliveryAddress'] ?? 'No address provided',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : () => _updateOrderStatus(
                  _currentStatus == 'IN_TRANSIT' ? 'OUT_FOR_DELIVERY' : 'COMPLETED'
                ),
                icon: _isUpdating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(
                        _currentStatus == 'IN_TRANSIT' ? Icons.local_shipping : Icons.check_circle,
                        size: 24,
                      ),
                label: Text(
                  _isUpdating
                      ? 'Updating...'
                      : _currentStatus == 'IN_TRANSIT'
                          ? 'Mark as Out for Delivery'
                          : 'Order Completed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStatus == 'IN_TRANSIT' ? Color(0xFFFF9800) : Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
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
              Icon(icon, color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
              ),
            ],
          ),
          Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
