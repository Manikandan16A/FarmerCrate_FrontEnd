import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerDetailsPage extends StatefulWidget {
  final String customerId;
  final String token;
  final Map<String, dynamic> customer;

  const CustomerDetailsPage({
    Key? key,
    required this.customerId,
    required this.token,
    required this.customer,
  }) : super(key: key);

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  List<dynamic> orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomerOrders();
  }

  Future<void> _fetchCustomerOrders() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/customers/${widget.customerId}/orders'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orders = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
            ),
          ),
        ),
        title: Text('Customer Details', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCustomerInfo(),
            _buildOrdersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: widget.customer['imageUrl'] != null && widget.customer['imageUrl'].toString().isNotEmpty
                ? NetworkImage(widget.customer['imageUrl'])
                : null,
            child: widget.customer['imageUrl'] == null || widget.customer['imageUrl'].toString().isEmpty
                ? Icon(Icons.person, size: 40, color: Colors.white)
                : null,
            backgroundColor: Colors.blue[600],
          ),
          SizedBox(height: 12),
          Text(widget.customer['name'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(widget.customer['email'], style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInfoTile('Phone', widget.customer['phone'])),
              Expanded(child: _buildInfoTile('Age', widget.customer['age'].toString())),
            ],
          ),
          SizedBox(height: 8),
          _buildInfoTile('Address', '${widget.customer['address']}, ${widget.customer['district']}, ${widget.customer['state']}'),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No orders found', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final product = order['product'];
    final primaryImage = (product['images'] as List).firstWhere((img) => img['is_primary'] == true, orElse: () => product['images'][0]);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(primaryImage['image_url'], width: 50, height: 50, fit: BoxFit.cover),
            ),
            title: Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Order #${order['order_id']}'),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(order['current_status']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(order['current_status'], style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Qty: ${order['quantity']}', style: TextStyle(fontSize: 12)),
                Text('₹${order['total_price']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'SHIPPED':
        return Colors.blue;
      case 'PLACED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
