import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Customer/product_details_screen.dart';
import 'customer_details_page.dart';

class FarmerDetailsPage extends StatefulWidget {
  final String farmerId;
  final String token;
  final dynamic user;

  const FarmerDetailsPage({
    Key? key,
    required this.farmerId,
    required this.token,
    required this.user,
  }) : super(key: key);

  @override
  State<FarmerDetailsPage> createState() => _FarmerDetailsPageState();
}

class _FarmerDetailsPageState extends State<FarmerDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingProducts = true;
  bool _isLoadingOrders = true;
  bool _isLoadingCustomers = true;

  List<dynamic> products = [];
  List<dynamic> orders = [];
  List<dynamic> customers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProducts();
    _fetchOrders();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/${widget.farmerId}/products'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          products = data['data'] ?? [];
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/${widget.farmerId}/orders'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orders = data['data'] ?? [];
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/customers'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          customers = data['data'] ?? [];
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      print('Error fetching customers: $e');
      setState(() => _isLoadingCustomers = false);
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
        title: Text('Farmer Details', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFarmerOverview(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildOrdersTab(),
                _buildCustomersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerOverview() {
    final farmer = widget.user;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.green[100],
              backgroundImage: farmer['image_url'] != null && farmer['image_url'].toString().isNotEmpty
                  ? NetworkImage(farmer['image_url'])
                  : null,
              child: farmer['image_url'] == null || farmer['image_url'].toString().isEmpty
                  ? Icon(Icons.person, size: 35, color: Colors.green[700])
                  : null,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        farmer['name'] ?? 'Farmer',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    if (farmer['is_verified'] == true)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Verified', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6),
                if (farmer['mobile_number'] != null)
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.white.withOpacity(0.9)),
                      SizedBox(width: 6),
                      Text(farmer['mobile_number'], style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                if (farmer['address'] != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.9)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          farmer['address'],
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(10),
        ),
        tabs: [
          Tab(icon: Icon(Icons.inventory, size: 20), text: 'Products'),
          Tab(icon: Icon(Icons.shopping_bag, size: 20), text: 'Orders'),
          Tab(icon: Icon(Icons.people, size: 20), text: 'Customers'),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoadingProducts) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No products found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No orders found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildCustomersTab() {
    if (_isLoadingCustomers) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No customers found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: customers.length,
      itemBuilder: (context, index) => _buildCustomerCard(customers[index]),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final images = product['images'] as List;
    final primaryImage = images.firstWhere((img) => img['is_primary'] == true, orElse: () => images.isNotEmpty ? images[0] : null);
    bool inStock = product['quantity'] > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: product['product_id'],
              token: widget.token,
              productData: product,
              isAdminView: true,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: inStock ? Colors.green.shade200 : Colors.red.shade200, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: primaryImage != null
                    ? Image.network(primaryImage['image_url'], width: 60, height: 60, fit: BoxFit.cover)
                    : Container(width: 60, height: 60, color: Colors.grey[300], child: Icon(Icons.image)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(product['category'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text('₹${product['current_price']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[700])),
                        SizedBox(width: 12),
                        Text('Stock: ${product['quantity']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: inStock ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(inStock ? 'In Stock' : 'Out', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final product = order['product'];
    final customer = order['customer'];
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
              subtitle: Text(customer['name'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

  Widget _buildCustomerCard(dynamic customer) {
    final orderStats = customer['order_stats'] ?? {};
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailsPage(
              customerId: customer['customer_id'].toString(),
              token: widget.token,
              customer: {
                'name': customer['name'],
                'email': customer['email'],
                'phone': customer['mobile_number'],
                'age': customer['age'] ?? 0,
                'address': customer['address'],
                'district': customer['district'],
                'state': customer['state'],
                'orders': orderStats['total_orders'] ?? 0,
                'spent': orderStats['total_spent'] ?? 0,
                'imageUrl': customer['image_url'],
              },
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue[100],
            backgroundImage: customer['image_url'] != null && customer['image_url'].toString().isNotEmpty
                ? NetworkImage(customer['image_url'])
                : null,
            child: customer['image_url'] == null || customer['image_url'].toString().isEmpty
                ? Icon(Icons.person, color: Colors.blue[700])
                : null,
          ),
          title: Text(customer['name'], style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${orderStats['total_orders'] ?? 0} Orders • ₹${orderStats['total_spent'] ?? 0}', style: TextStyle(fontSize: 12)),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ),
      ),
    );
  }

  void _showOrderDetails(dynamic order) {
    final product = order['product'];
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
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
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
      case 'IN_TRANSIT':
        return Colors.blue[500]!;
      case 'ASSIGNED':
        return Colors.blue[500]!;
      case 'PLACED':
        return Colors.orange[500]!;
      default:
        return Colors.grey;
    }
  }
}