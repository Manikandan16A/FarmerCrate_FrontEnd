import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final String token;
  final Function onOrderCompleted;

  const OrderDetailsPage({
    Key? key,
    required this.order,
    required this.token,
    required this.onOrderCompleted,
  }) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _isCompleting = false;

  Future<void> _completeOrder() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/delivery-persons/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'order_id': widget.order['id'],
          'status': 'COMPLETED',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order completed successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        // Call the callback to refresh parent data
        widget.onOrderCompleted();

        // Navigate back
        Navigator.pop(context);
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/signin');
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete order: ${errorData['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCompleting = false;
      });
    }
  }

  void _showCompleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text('Complete Delivery'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to mark this order as completed?'),
              SizedBox(height: 8),
              Text(
                'Order #${widget.order['id']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Customer: ${widget.order['customerName']}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _completeOrder();
              },
              icon: Icon(Icons.check),
              label: Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Color(0xFF4CAF50);
      case 'assigned':
      case 'in_transit':
        return Color(0xFFFF9800);
      case 'pending':
        return Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order['id']}'),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        actions: [
          if (widget.order['status'] != 'delivered' && widget.order['status'] != 'completed')
            IconButton(
              icon: Icon(Icons.check_circle),
              onPressed: _showCompleteConfirmation,
              tooltip: 'Complete Delivery',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getStatusColor(widget.order['status']), _getStatusColor(widget.order['status']).withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(widget.order['status']).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    widget.order['status'] == 'delivered' ? Icons.check_circle : Icons.delivery_dining,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Order Status',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.order['status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Customer Information Section
            _buildSectionCard(
              'Customer Information',
              Icons.person,
              [
                _buildInfoRow('Name', widget.order['customerName']),
                SizedBox(height: 12),
                _buildInfoRow('Phone', widget.order['phone']),
              ],
            ),

            SizedBox(height: 16),

            // Delivery Information Section
            _buildSectionCard(
              'Delivery Information',
              Icons.location_on,
              [
                _buildInfoRow('Delivery Address', widget.order['address']),
                SizedBox(height: 12),
                _buildInfoRow('Estimated Time', widget.order['deliveryTime']),
                SizedBox(height: 12),
                _buildInfoRow('Order Date', widget.order['orderDate']),
              ],
            ),

            SizedBox(height: 16),

            // Order Summary Section
            _buildSectionCard(
              'Order Summary',
              Icons.shopping_cart,
              [
                _buildInfoRow('Items Count', widget.order['items'].toString()),
                SizedBox(height: 12),
                _buildInfoRow('Total Amount', '₹${widget.order['totalAmount'].toStringAsFixed(2)}'),
              ],
            ),

            SizedBox(height: 24),

            // Action Button
            if (widget.order['status'] != 'delivered' && widget.order['status'] != 'completed')
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isCompleting ? null : _showCompleteConfirmation,
                  icon: _isCompleting
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(Icons.check_circle, size: 24),
                  label: Text(
                    _isCompleting ? 'Completing...' : 'Mark as Delivered',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
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
              Icon(icon, size: 20, color: Color(0xFF4CAF50)),
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
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}