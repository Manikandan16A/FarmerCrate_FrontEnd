import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final String? token;
  final String transporterRole;

  const OrderDetailPage({
    super.key,
    required this.order,
    required this.token,
    required this.transporterRole,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool isUpdating = false;

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

  Future<void> _updateOrderStatus(String status) async {
    setState(() => isUpdating = true);
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/orders/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'order_id': widget.order['order_id'], 'status': status}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Order status updated to $status');
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar(errorData['message'] ?? 'Failed to update status', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => isUpdating = false);
    }
  }

  void _showStatusUpdateDialog() {
    final currentStatus = widget.order['current_status'];
    final options = _getStatusOptions(currentStatus);

    if (options.isEmpty) {
      _showSnackBar('No status updates available', isWarning: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Order Status', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => ListTile(
            leading: Icon(option['icon'], color: option['color']),
            title: Text(option['label']),
            onTap: () {
              Navigator.pop(context);
              _updateOrderStatus(option['status']);
            },
          )).toList(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getStatusOptions(String currentStatus) {
    if (widget.transporterRole == 'PICKUP_SHIPPING') {
      if (currentStatus == 'ASSIGNED') {
        return [{'status': 'SHIPPED', 'label': 'Shipped', 'icon': Icons.local_shipping, 'color': Color(0xFF2196F3)}];
      }
    } else if (widget.transporterRole == 'DELIVERY') {
      if (currentStatus == 'SHIPPED') {
        return [{'status': 'RECEIVED', 'label': 'Received', 'icon': Icons.check_circle, 'color': Color(0xFF4CAF50)}];
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.order['product'];
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
    final status = widget.order['current_status'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Order Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Hero(
                tag: 'product_${widget.order['order_id']}',
                child: Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image, size: 80, color: Colors.grey[400]))),
                ),
              ),
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(product?['name'] ?? 'N/A', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)))),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: _getStatusColor(status).withOpacity(0.3), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Text(status ?? 'N/A', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildPriceCard(Icons.currency_rupee, 'Total', '₹${widget.order['total_price'] ?? 0}', Color(0xFF2E7D32))),
                      SizedBox(width: 12),
                      Expanded(child: _buildPriceCard(Icons.shopping_cart, 'Quantity', '${widget.order['quantity'] ?? 0}', Color(0xFF1976D2))),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildPriceCard(Icons.local_shipping, 'Transport', '₹${widget.order['transport_charge'] ?? 0}', Color(0xFFFF6F00))),
                      SizedBox(width: 12),
                      Expanded(child: _buildPriceCard(Icons.payment, 'Payment', widget.order['payment_status'] ?? 'N/A', Color(0xFF6A1B9A))),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 24),
                      SizedBox(width: 8),
                      Text('Addresses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildAddressCard(Icons.upload, 'Pickup Address', widget.order['pickup_address'], Color(0xFF1976D2)),
                  SizedBox(height: 12),
                  _buildAddressCard(Icons.download, 'Delivery Address', widget.order['delivery_address'], Color(0xFF2E7D32)),
                  if (widget.order['destination_transport_address'] != null)
                    SizedBox(height: 12),
                  if (widget.order['destination_transport_address'] != null)
                    _buildAddressCard(Icons.warehouse, 'Destination Transport', widget.order['destination_transport_address'], Color(0xFF6A1B9A)),
                ],
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 24),
                      SizedBox(width: 8),
                      Text('Additional Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today, 'Created', _formatDate(widget.order['created_at'])),
                  _buildInfoRow(Icons.update, 'Last Updated', _formatDate(widget.order['updated_at'])),
                ],
              ),
            ),
            SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isUpdating ? null : _showStatusUpdateDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              disabledBackgroundColor: Colors.grey[400],
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: isUpdating
                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.update, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Update Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Color(0xFF2E7D32)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(IconData icon, String title, String? address, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text(address ?? 'N/A', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87, height: 1.4)),
              ],
            ),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
