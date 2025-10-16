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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 47,
              backgroundImage: widget.customer['imageUrl'] != null && widget.customer['imageUrl'].toString().isNotEmpty
                  ? NetworkImage(widget.customer['imageUrl'])
                  : null,
              child: widget.customer['imageUrl'] == null || widget.customer['imageUrl'].toString().isEmpty
                  ? Icon(Icons.person, size: 50, color: Colors.green[600])
                  : null,
              backgroundColor: Colors.green[50],
            ),
          ),
          SizedBox(height: 12),
          Text(widget.customer['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text(widget.customer['email'], style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Orders', widget.customer['orders'].toString(), Icons.shopping_bag, Colors.green)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Spent', '₹${widget.customer['spent']}', Icons.currency_rupee, Colors.green)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(widget.customer['phone'], style: TextStyle(fontSize: 14)),
                    Spacer(),
                    Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text('${widget.customer['age']} yrs', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.customer['address']}, ${widget.customer['district']}, ${widget.customer['state']}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
          child: Column(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text('No orders found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green[700], size: 24),
              SizedBox(width: 8),
              Text('Order History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${orders.length} Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700])),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: orders.length,
          itemBuilder: (context, index) => _buildOrderCard(orders[index]),
        ),
      ],
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final product = order['product'];
    final primaryImage = (product['images'] as List).firstWhere((img) => img['is_primary'] == true, orElse: () => product['images'][0]);

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
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
      ),
    );
  }

  void _showOrderDetails(dynamic order) {
    final product = order['product'];
    final farmer = product?['farmer'];
    final sourceTransporter = order['source_transporter'];
    final destTransporter = order['destination_transporter'];
    final deliveryPerson = order['delivery_person'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order['order_id']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                Divider(),
                _buildDetailSection('Farmer', farmer?['name'], farmer?['mobile_number'], farmer?['address']),
                Divider(),
                _buildDetailSection('Source Transporter', sourceTransporter?['name'], sourceTransporter?['mobile_number'], sourceTransporter?['address']),
                Divider(),
                _buildDetailSection('Destination Transporter', destTransporter?['name'], destTransporter?['mobile_number'], destTransporter?['address']),
                Divider(),
                deliveryPerson != null
                    ? _buildDetailSection('Delivery Person', deliveryPerson['name'], deliveryPerson['mobile_number'], deliveryPerson['vehicle_number'])
                    : _buildWaitingSection('Delivery Person'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String? name, String? contact, String? info) {
    if (name == null) return _buildWaitingSection(title);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
          SizedBox(height: 4),
          Text(name, style: TextStyle(fontSize: 14)),
          if (contact != null) Text(contact, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          if (info != null) Text(info, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildWaitingSection(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Text('Wait for assign', style: TextStyle(fontSize: 13, color: Colors.green[700], fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green[700]!;
      case 'SHIPPED':
        return Colors.green[500]!;
      case 'PLACED':
        return Colors.green[300]!;
      default:
        return Colors.grey;
    }
  }
}
