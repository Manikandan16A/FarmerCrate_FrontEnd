import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransporterDetailsPage extends StatefulWidget {
  final String transporterId;
  final String token;
  final Map<String, dynamic> transporter;

  const TransporterDetailsPage({
    Key? key,
    required this.transporterId,
    required this.token,
    required this.transporter,
  }) : super(key: key);

  @override
  State<TransporterDetailsPage> createState() => _TransporterDetailsPageState();
}

class _TransporterDetailsPageState extends State<TransporterDetailsPage> {
  List<dynamic> sourceOrders = [];
  List<dynamic> destinationOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransporterOrders();
  }

  Future<void> _fetchTransporterOrders() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/transporters/${widget.transporterId}/orders'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = data['data'] ?? [];
        
        setState(() {
          sourceOrders = orders.where((order) => order['source_transporter_id'].toString() == widget.transporterId).toList();
          destinationOrders = orders.where((order) => order['destination_transporter_id'].toString() == widget.transporterId).toList();
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
              colors: [Color(0xFFE65100), Color(0xFFFF9800), Color(0xFFFFB74D)],
            ),
          ),
        ),
        title: Text('Transporter Details', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTransporterInfo(),
            _buildOrdersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransporterInfo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF9800), Color(0xFFFFB74D)],
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
              backgroundImage: widget.transporter['imageUrl'] != null && widget.transporter['imageUrl'].toString().isNotEmpty
                  ? NetworkImage(widget.transporter['imageUrl'])
                  : null,
              child: widget.transporter['imageUrl'] == null || widget.transporter['imageUrl'].toString().isEmpty
                  ? Icon(Icons.local_shipping, size: 50, color: Colors.orange[600])
                  : null,
              backgroundColor: Colors.orange[50],
            ),
          ),
          SizedBox(height: 12),
          Text(widget.transporter['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text(widget.transporter['email'], style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.transporter['verifiedStatus'] ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.transporter['verifiedStatus'] ? 'Verified' : 'Unverified',
              style: TextStyle(
                color: widget.transporter['verifiedStatus'] ? Colors.green[700] : Colors.red[700],
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
                    Expanded(child: _buildStatCard('Total Orders', widget.transporter['totalOrders'].toString(), Icons.shopping_bag, Colors.orange)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Amount', '₹${widget.transporter['totalAmount'].toStringAsFixed(2)}', Icons.currency_rupee, Colors.green)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Source', widget.transporter['sourceOrders'].toString(), Icons.upload, Colors.purple)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Destination', widget.transporter['destOrders'].toString(), Icons.download, Colors.blue)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(widget.transporter['phone'], style: TextStyle(fontSize: 14)),
                    Spacer(),
                    Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text('${widget.transporter['age']} yrs', style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.transporter['zone']}, ${widget.transporter['district']}, ${widget.transporter['state']}',
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

  Widget _buildOrdersSection() {
    if (_isLoading) {
      return Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    return Column(
      children: [
        _buildOrdersList('Source Orders', sourceOrders, Colors.purple),
        SizedBox(height: 16),
        _buildOrdersList('Destination Orders', destinationOrders, Colors.blue),
      ],
    );
  }

  Widget _buildOrdersList(String title, List<dynamic> orders, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: color, size: 24),
              SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${orders.length} Orders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
        ),
        orders.isEmpty
            ? Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text('No orders found', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
              )
            : ListView.builder(
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
    final sourceTransporter = order['source_transporter'];
    final destTransporter = order['destination_transporter'];
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
                    colors: [Color(0xFFE65100), Color(0xFFFF9800), Color(0xFFFFB74D)],
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
                      SizedBox(height: 12),
                      _buildEnhancedDetailCard('Source Transporter', sourceTransporter?['name'], sourceTransporter?['mobile_number'], sourceTransporter?['address'], null, Icons.upload, Colors.purple),
                      SizedBox(height: 12),
                      _buildEnhancedDetailCard('Destination Transporter', destTransporter?['name'], destTransporter?['mobile_number'], destTransporter?['address'], null, Icons.download, Colors.orange),
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
