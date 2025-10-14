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

  Future<void> _updateOrderStatus() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/orders/${widget.orderId}/status'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'DELIVERED'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order marked as delivered successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to update order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: Text('Update Order', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
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
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Order #${widget.orderId}',
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
                      'IN TRANSIT',
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
                onPressed: _isUpdating ? null : _updateOrderStatus,
                icon: _isUpdating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(Icons.check_circle, size: 24),
                label: Text(
                  _isUpdating ? 'Updating...' : 'Mark as Delivered',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
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
