import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool isLoading = false;

  // Mock data - will be replaced with API data
  Map<String, dynamic> farmerData = {
    'name': 'John Farmer',
    'email': 'john@example.com',
    'phone': '+91 9876543210',
    'address': 'Village Road, District',
    'zone': 'North Zone',
    'state': 'Karnataka',
    'image': '',
    'totalProducts': 12,
    'activeOrders': 8,
    'totalCustomers': 25,
    'revenue': 45000,
  };

  List<Map<String, dynamic>> products = [
    {'name': 'Tomatoes', 'stock': 150, 'price': 40, 'status': 'In Stock', 'image': ''},
    {'name': 'Potatoes', 'stock': 0, 'price': 30, 'status': 'Out of Stock', 'image': ''},
    {'name': 'Onions', 'stock': 200, 'price': 35, 'status': 'In Stock', 'image': ''},
  ];

  List<Map<String, dynamic>> orders = [
    {'id': 'ORD001', 'customer': 'Alice', 'product': 'Tomatoes', 'qty': 10, 'amount': 400, 'date': '2024-01-15', 'status': 'Delivered'},
    {'id': 'ORD002', 'customer': 'Bob', 'product': 'Onions', 'qty': 15, 'amount': 525, 'date': '2024-01-14', 'status': 'Pending'},
  ];

  List<Map<String, dynamic>> customers = [
    {'name': 'Alice Johnson', 'orders': 5, 'spent': 2500, 'lastOrder': '2024-01-15'},
    {'name': 'Bob Smith', 'orders': 3, 'spent': 1800, 'lastOrder': '2024-01-14'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchFarmerDetails();
  }

  Future<void> _fetchFarmerDetails() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/getAllFarmers'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        final farmer = data.firstWhere(
          (f) => f['farmer_id'].toString() == widget.farmerId,
          orElse: () => null,
        );
        if (farmer != null) {
          final productsList = farmer['products'] as List<dynamic>? ?? [];
          final orderStats = farmer['order_stats'] as Map<String, dynamic>?;
          Set<String> uniqueCustomers = {};
          List<Map<String, dynamic>> ordersList = [];
          List<Map<String, dynamic>> productData = [];
          
          for (var product in productsList) {
            productData.add({
              'name': product['name'] ?? 'Unknown',
              'stock': product['stock_quantity'] ?? 0,
              'price': product['price_per_unit'] ?? 0,
              'status': (product['stock_quantity'] ?? 0) > 0 ? 'In Stock' : 'Out of Stock',
              'image': '',
            });
            final orders = product['Orders'] as List<dynamic>? ?? [];
            for (var order in orders) {
              final customer = order['customer'] as Map<String, dynamic>?;
              if (customer != null) {
                uniqueCustomers.add(customer['mobile_number']?.toString() ?? '');
                ordersList.add({
                  'id': 'ORD${order['order_id']}',
                  'customer': customer['name'] ?? 'Unknown',
                  'product': product['name'] ?? 'Unknown',
                  'qty': order['quantity'] ?? 0,
                  'amount': order['farmer_amount'] ?? 0,
                  'date': order['order_date']?.toString().split('T')[0] ?? 'N/A',
                  'status': order['current_status'] ?? 'Pending',
                });
              }
            }
          }
          
          setState(() {
            farmerData = {
              'name': farmer['name'] ?? 'Unknown',
              'email': farmer['email'] ?? 'N/A',
              'phone': farmer['mobile_number'] ?? 'N/A',
              'address': farmer['address'] ?? 'N/A',
              'zone': farmer['zone'] ?? 'N/A',
              'state': farmer['state'] ?? 'N/A',
              'image': '',
              'totalProducts': productsList.length,
              'activeOrders': orderStats?['total_orders'] ?? 0,
              'totalCustomers': uniqueCustomers.length,
              'revenue': (orderStats?['total_revenue'] ?? 0).toDouble(),
            };
            products = productData;
            orders = ordersList;
          });
        }
      }
    } catch (e) {
      print('Error fetching farmer details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildFarmerHeader()),
          SliverToBoxAdapter(child: _buildStatsCards()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF2E7D32),
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Farmer Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.green.shade50]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farmerData['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(farmerData['email'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(farmerData['phone'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Products', farmerData['totalProducts'].toString(), Icons.inventory, Colors.blue)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard('Orders', farmerData['activeOrders'].toString(), Icons.shopping_cart, Colors.orange)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard('Customers', farmerData['totalCustomers'].toString(), Icons.people, Colors.purple)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard('Revenue', '₹${(farmerData['revenue'] / 1000).toStringAsFixed(0)}K', Icons.currency_rupee, Colors.green)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
          borderRadius: BorderRadius.circular(12),
        ),
        tabs: [
          Tab(icon: Icon(Icons.info, size: 20), text: 'Overview'),
          Tab(icon: Icon(Icons.inventory, size: 20), text: 'Products'),
          Tab(icon: Icon(Icons.shopping_bag, size: 20), text: 'Orders'),
          Tab(icon: Icon(Icons.people, size: 20), text: 'Customers'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Farmer Information'),
          _buildInfoCard([
            _buildInfoRow(Icons.location_on, 'Address', farmerData['address']),
            _buildInfoRow(Icons.map, 'Zone', farmerData['zone']),
            _buildInfoRow(Icons.location_city, 'State', farmerData['state']),
          ]),
          SizedBox(height: 16),
          _buildSectionTitle('Stock Status'),
          _buildStockStatusCard(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildOrdersTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }

  Widget _buildCustomersTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: customers.length,
      itemBuilder: (context, index) => _buildCustomerCard(customers[index]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: Colors.green[700]),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusCard() {
    int inStock = products.where((p) => p['stock'] > 0).length;
    int outOfStock = products.where((p) => p['stock'] == 0).length;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.red.shade50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('$inStock', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green[700])),
                Text('In Stock', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: Column(
              children: [
                Text('$outOfStock', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red[700])),
                Text('Out of Stock', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    bool inStock = product['stock'] > 0;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, inStock ? Colors.green.shade50 : Colors.red.shade50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: inStock ? Colors.green.shade200 : Colors.red.shade200, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory, size: 30, color: Colors.grey[600]),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Text('Stock: ${product['stock']} kg', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                Text('Price: ₹${product['price']}/kg', style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: inStock ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(product['status'], style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    Color statusColor = order['status'] == 'Delivered' ? Colors.green : Colors.orange;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order['id'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                child: Text(order['status'], style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Divider(height: 20),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(order['customer'], style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              Spacer(),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(order['date'], style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text('${order['product']} - ${order['qty']} kg', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              Spacer(),
              Text('₹${order['amount']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.blue.shade50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(Icons.person, size: 28, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Text('${customer['orders']} Orders • ₹${customer['spent']} Spent', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                Text('Last Order: ${customer['lastOrder']}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
