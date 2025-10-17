import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'farmer_details_page.dart';
import 'transporter_details_page.dart';
import 'delivery_person_details_page.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(product['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Builder(
                    builder: (dialogContext) => Column(
                      children: [
                        _buildDetailCard('Farmer', farmer?['name'], farmer?['mobile_number'], farmer?['address'], farmer?['image_url'], Icons.agriculture, data: farmer, dialogContext: dialogContext),
                        SizedBox(height: 12),
                        _buildDetailCard('Source Transporter', sourceTransporter?['name'], sourceTransporter?['mobile_number'], sourceTransporter?['address'], sourceTransporter?['image_url'], Icons.local_shipping, data: sourceTransporter, dialogContext: dialogContext),
                        SizedBox(height: 12),
                        _buildDetailCard('Destination Transporter', destTransporter?['name'], destTransporter?['mobile_number'], destTransporter?['address'], destTransporter?['image_url'], Icons.local_shipping, data: destTransporter, dialogContext: dialogContext),
                        SizedBox(height: 12),
                        deliveryPerson != null && deliveryPerson['name'] != null
                            ? _buildDetailCard('Delivery Person', deliveryPerson['name'], deliveryPerson['mobile_number'], deliveryPerson['vehicle_number'], deliveryPerson['image_url'], Icons.delivery_dining, data: deliveryPerson, dialogContext: dialogContext)
                            : _buildWaitingCard('Delivery Person'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String? name, String? contact, String? info, String? imageUrl, IconData icon, {dynamic data, BuildContext? dialogContext}) {
    if (name == null || name.isEmpty) return _buildWaitingCard(title);
    
    return GestureDetector(
      onTap: () async {
        if (dialogContext != null) {
          Navigator.pop(dialogContext);
        }
        
        if (title == 'Farmer' && data != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmerDetailsPage(
                farmerId: data['farmer_id'].toString(),
                token: widget.token,
                user: data,
              ),
            ),
          );
        } else if ((title == 'Source Transporter' || title == 'Destination Transporter') && data != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (loadingContext) => Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
          
          final transporterId = data['transporter_id'].toString();
          final fullData = await _fetchTransporterDetails(transporterId);
          
          Navigator.of(context, rootNavigator: true).pop();
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransporterDetailsPage(
                  transporterId: transporterId,
                  token: widget.token,
                  transporter: fullData ?? {
                    'name': data['name'] ?? 'Unknown',
                    'email': 'N/A',
                    'phone': data['mobile_number'] ?? 'N/A',
                    'age': 0,
                    'zone': 'N/A',
                    'district': 'N/A',
                    'state': 'N/A',
                    'verifiedStatus': false,
                    'totalOrders': 0,
                    'totalAmount': 0.0,
                    'sourceOrders': 0,
                    'destOrders': 0,
                    'imageUrl': null,
                  },
                ),
              ),
            );
          }
        } else if (title == 'Delivery Person' && data != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (loadingContext) => Center(child: CircularProgressIndicator(color: Colors.purple)),
          );
          
          final deliveryPersonId = data['delivery_person_id'].toString();
          final fullData = await _fetchDeliveryPersonDetails(deliveryPersonId);
          
          Navigator.of(context, rootNavigator: true).pop();
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryPersonDetailsPage(
                  deliveryPersonId: deliveryPersonId,
                  token: widget.token,
                  deliveryPerson: fullData ?? {
                    'id': data['delivery_person_id'],
                    'name': data['name'] ?? 'Unknown',
                    'vehicleNumber': data['vehicle_number'] ?? 'N/A',
                    'isAvailable': false,
                    'totalOrders': 0,
                    'rating': '0.0',
                    'phone': data['mobile_number'] ?? 'N/A',
                    'licenseNumber': 'N/A',
                    'currentLocation': 'N/A',
                    'vehicleType': 'bike',
                    'totalAmount': 0.0,
                  },
                ),
              ),
            );
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green[50],
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl == null || imageUrl.isEmpty ? Icon(icon, color: Colors.green[700], size: 28) : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  if (contact != null) ...[
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(contact, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                  if (info != null) ...[
                    SizedBox(height: 2),
                    Text(info, style: TextStyle(fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingCard(String title) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!, width: 1.5, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.hourglass_empty, color: Colors.green[700], size: 28),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text('Wait for assign', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green[700], fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchTransporterDetails(String transporterId) async {
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/transporters'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transporters = data['data'] as List;
        final transporter = transporters.firstWhere(
          (t) => t['transporter_id'].toString() == transporterId,
          orElse: () => null,
        );
        
        if (transporter != null) {
          final stats = transporter['order_stats'] ?? {};
          return {
            'name': transporter['name'],
            'email': transporter['email'] ?? 'N/A',
            'phone': transporter['mobile_number'],
            'age': transporter['age'] ?? 0,
            'zone': transporter['zone'] ?? 'N/A',
            'district': transporter['district'],
            'state': transporter['state'],
            'verifiedStatus': transporter['is_verified'] ?? false,
            'totalOrders': stats['total_orders'] ?? 0,
            'totalAmount': (stats['total_amount'] ?? 0.0).toDouble(),
            'sourceOrders': stats['source_orders'] ?? 0,
            'destOrders': stats['destination_orders'] ?? 0,
            'imageUrl': transporter['image_url'],
          };
        }
      }
    } catch (e) {
      print('Error fetching transporter details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchDeliveryPersonDetails(String deliveryPersonId) async {
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/delivery-persons'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final deliveryPersons = data['data'] as List;
        final deliveryPerson = deliveryPersons.firstWhere(
          (dp) => dp['delivery_person_id'].toString() == deliveryPersonId,
          orElse: () => null,
        );
        
        if (deliveryPerson != null) {
          final stats = deliveryPerson['order_stats'] ?? {};
          return {
            'id': deliveryPerson['delivery_person_id'],
            'name': deliveryPerson['name'],
            'vehicleNumber': deliveryPerson['vehicle_number'],
            'isAvailable': deliveryPerson['is_available'] ?? false,
            'totalOrders': stats['total_orders'] ?? 0,
            'rating': (stats['average_rating'] ?? 0.0).toString(),
            'phone': deliveryPerson['mobile_number'],
            'licenseNumber': deliveryPerson['license_number'] ?? 'N/A',
            'currentLocation': deliveryPerson['current_location'] ?? 'N/A',
            'vehicleType': deliveryPerson['vehicle_type'] ?? 'bike',
            'totalAmount': (stats['total_amount'] ?? 0.0).toDouble(),
          };
        }
      }
    } catch (e) {
      print('Error fetching delivery person details: $e');
    }
    return null;
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
