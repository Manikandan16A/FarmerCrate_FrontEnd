import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryPersonDetailsPage extends StatefulWidget {
  final String deliveryPersonId;
  final String token;
  final Map<String, dynamic> deliveryPerson;

  const DeliveryPersonDetailsPage({
    Key? key,
    required this.deliveryPersonId,
    required this.token,
    required this.deliveryPerson,
  }) : super(key: key);

  @override
  State<DeliveryPersonDetailsPage> createState() => _DeliveryPersonDetailsPageState();
}

class _DeliveryPersonDetailsPageState extends State<DeliveryPersonDetailsPage> {
  List<dynamic> orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/delivery-persons/${widget.deliveryPersonId}/orders'),
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
              colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0), Color(0xFFAB47BC)],
            ),
          ),
        ),
        title: Text('Delivery Person Details', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDeliveryPersonInfo(),
            _buildOrdersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPersonInfo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0), Color(0xFFAB47BC)],
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
              backgroundImage: widget.deliveryPerson['imageUrl'] != null && widget.deliveryPerson['imageUrl'].toString().isNotEmpty
                  ? NetworkImage(widget.deliveryPerson['imageUrl'])
                  : null,
              child: widget.deliveryPerson['imageUrl'] == null || widget.deliveryPerson['imageUrl'].toString().isEmpty
                  ? Icon(Icons.delivery_dining, size: 50, color: Colors.purple[600])
                  : null,
              backgroundColor: Colors.purple[50],
            ),
          ),
          SizedBox(height: 12),
          Text(widget.deliveryPerson['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text(widget.deliveryPerson['vehicleNumber'], style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.deliveryPerson['isAvailable'] ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.deliveryPerson['isAvailable'] ? 'Available' : 'Busy',
              style: TextStyle(
                color: widget.deliveryPerson['isAvailable'] ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
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
                    Expanded(child: _buildStatCard('Orders', widget.deliveryPerson['totalOrders'].toString(), Icons.shopping_bag, Colors.purple)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Rating', widget.deliveryPerson['rating'], Icons.star, Colors.amber)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Vehicle', widget.deliveryPerson['vehicleType'].toUpperCase(), Icons.two_wheeler, Colors.blue)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Amount', '₹${widget.deliveryPerson['totalAmount'].toStringAsFixed(2)}', Icons.currency_rupee, Colors.green)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(widget.deliveryPerson['phone'], style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.deliveryPerson['licenseNumber'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.deliveryPerson['currentLocation'],
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
              Icon(Icons.receipt_long, color: Colors.purple[700], size: 24),
              SizedBox(width: 8),
              Text('Delivery Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${orders.length} Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple[700])),
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
    final images = product['images'] as List;
    final primaryImage = images.firstWhere((img) => img['is_primary'] == true, orElse: () => images.isNotEmpty ? images[0] : null);

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
                child: primaryImage != null
                    ? Image.network(primaryImage['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                    : Container(width: 50, height: 50, color: Colors.grey[300], child: Icon(Icons.image)),
              ),
              title: Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(product['category'] ?? 'Product', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
    final customer = order['customer'];
    final images = product['images'] as List;
    final primaryImage = images.firstWhere((img) => img['is_primary'] == true, orElse: () => images.isNotEmpty ? images[0] : null);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0), Color(0xFFAB47BC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: primaryImage != null
                              ? Image.network(primaryImage['image_url'], width: 60, height: 60, fit: BoxFit.cover)
                              : Container(width: 60, height: 60, color: Colors.white24, child: Icon(Icons.image, color: Colors.white)),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              SizedBox(height: 4),
                              Text(product['category'] ?? 'Product', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Qty: ${order['quantity']}', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  SizedBox(width: 8),
                                  Text('₹${order['total_price']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Status: ${order['current_status']}', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildEnhancedDetailCard('Farmer', farmer?['name'], farmer?['mobile_number'], farmer?['address'], farmer?['image_url'], Icons.agriculture, Colors.green),
                      SizedBox(height: 12),
                      _buildEnhancedDetailCard('Customer', customer?['name'], customer?['mobile_number'], customer?['address'], customer?['image_url'], Icons.person, Colors.blue),
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

  Widget _buildEnhancedDetailCard(String title, String? name, String? contact, String? info, String? imageUrl, IconData icon, Color color) {
    if (name == null) return SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: color.withOpacity(0.15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(icon, color: color, size: 30),
                        )
                      : Icon(icon, color: color, size: 30),
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                  SizedBox(height: 6),
                  Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  if (contact != null) ...[ 
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: color),
                        SizedBox(width: 6),
                        Text(contact, style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                  if (info != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: color),
                        SizedBox(width: 6),
                        Expanded(child: Text(info, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green[700]!;
      case 'SHIPPED':
        return Colors.green[500]!;
      case 'ASSIGNED':
        return Colors.blue[500]!;
      case 'PLACED':
        return Colors.orange[500]!;
      default:
        return Colors.grey;
    }
  }
}
