import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/Signin.dart';
import 'admin_homepage.dart';
import 'adminreport.dart';
import 'admin_orders_page.dart';
import 'common_drawer.dart';
import 'farmer_details_page.dart';
import 'ConsumerManagement.dart';
import 'transpoter_mang.dart';
import 'customer_details_page.dart';
import 'transporter_details_page.dart';
import 'delivery_person_details_page.dart';

class AdminUserManagementPage extends StatefulWidget {
  final dynamic user;
  final String token;
  const AdminUserManagementPage({super.key, required this.user, required this.token});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  String? selectedFilter;
  String? expandedFarmerId;
  String? expandedCustomerId;
  
  List<Map<String, dynamic>> farmers = [];
  bool _isLoadingFarmers = false;
  
  List<Map<String, dynamic>> customers = [];
  bool _isLoadingCustomers = false;
  List<Map<String, dynamic>> transporters = [];
  bool _isLoadingTransporters = false;
  String? expandedTransporterId;
  List<Map<String, dynamic>> deliveryPersons = [];
  bool _isLoadingDeliveryPersons = false;
  String? expandedDeliveryPersonId;

  @override
  void initState() {
    super.initState();
    _fetchFarmers();
    _fetchCustomers();
    _fetchTransporters();
    _fetchDeliveryPersons();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString == 'N/A') return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _fetchFarmers() async {
    setState(() => _isLoadingFarmers = true);

    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          farmers = (data['data'] as List).map((farmer) {
            return {
              'id': farmer['farmer_id']?.toString() ?? 'N/A',
              'name': farmer['name'] ?? 'N/A',
              'email': farmer['email'] ?? 'N/A',
              'phone': farmer['mobile_number'] ?? 'N/A',
              'address': farmer['address'] ?? 'N/A',
              'zone': farmer['zone'] ?? 'N/A',
              'state': farmer['state'] ?? 'N/A',
              'district': farmer['district'] ?? 'N/A',
              'age': farmer['age'] ?? 0,
              'imageUrl': farmer['image_url'],
              'isVerified': farmer['is_verified_by_gov'] ?? false,
              'products': farmer['product_count'] ?? 0,
              'orders': farmer['order_count'] ?? 0,
              'revenue': (farmer['total_earnings'] ?? 0).toDouble(),
            };
          }).toList();
          _isLoadingFarmers = false;
        });
      }
    } catch (e) {
      print('Error fetching farmers: $e');
      setState(() => _isLoadingFarmers = false);
    }
  }

  Future<void> _fetchDeliveryPersons() async {
    setState(() => _isLoadingDeliveryPersons = true);

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
        
        setState(() {
          deliveryPersons = (data['data'] as List).map((dp) {
            final orderStats = dp['order_stats'] ?? {};
            return {
              'id': dp['delivery_person_id']?.toString() ?? 'N/A',
              'name': dp['name'] ?? 'N/A',
              'phone': dp['mobile_number'] ?? 'N/A',
              'vehicleNumber': dp['vehicle_number'] ?? 'N/A',
              'licenseNumber': dp['license_number'] ?? 'N/A',
              'vehicleType': dp['vehicle_type'] ?? 'N/A',
              'currentLocation': dp['current_location'] ?? 'N/A',
              'imageUrl': dp['image_url'],
              'licenseUrl': dp['license_url'],
              'isAvailable': dp['is_available'] ?? false,
              'rating': dp['rating'] ?? '0.00',
              'totalOrders': orderStats['total_orders'] ?? 0,
              'totalAmount': (orderStats['total_amount_received'] ?? 0).toDouble(),
            };
          }).toList();
          _isLoadingDeliveryPersons = false;
        });
      }
    } catch (e) {
      print('Error fetching delivery persons: $e');
      setState(() => _isLoadingDeliveryPersons = false);
    }
  }

  Future<void> _fetchTransporters() async {
    setState(() {
      _isLoadingTransporters = true;
    });

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
        
        setState(() {
          transporters = (data['data'] as List).map((transporter) {
            final orderStats = transporter['order_stats'] ?? {};
            return {
              'id': transporter['transporter_id']?.toString() ?? 'N/A',
              'name': transporter['name'] ?? 'N/A',
              'email': transporter['email'] ?? 'N/A',
              'phone': transporter['mobile_number'] ?? 'N/A',
              'address': transporter['address'] ?? 'N/A',
              'zone': transporter['zone'] ?? 'N/A',
              'state': transporter['state'] ?? 'N/A',
              'district': transporter['district'] ?? 'N/A',
              'age': transporter['age'] ?? 0,
              'imageUrl': transporter['image_url'],
              'totalOrders': orderStats['total_orders'] ?? 0,
              'sourceOrders': orderStats['source_orders'] ?? 0,
              'destOrders': orderStats['destination_orders'] ?? 0,
              'totalAmount': (orderStats['total_amount_received'] ?? 0).toDouble(),
              'verifiedStatus': transporter['verified_status'] ?? false,
            };
          }).toList();
          _isLoadingTransporters = false;
        });
      }
    } catch (e) {
      print('Error fetching transporters: $e');
      setState(() {
        _isLoadingTransporters = false;
      });
    }
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
    });

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
          customers = (data['data'] as List).map((customer) {
            final orderStats = customer['order_stats'] ?? {};
            final orders = customer['orders'] as List? ?? [];
            String lastOrderDate = _formatDate(customer['created_at']);
            
            if (orders.isNotEmpty) {
              lastOrderDate = 'Recent';
            }
            
            return {
              'id': customer['customer_id']?.toString() ?? 'N/A',
              'name': customer['name'] ?? 'N/A',
              'email': customer['email'] ?? 'N/A',
              'phone': customer['mobile_number'] ?? 'N/A',
              'address': customer['address'] ?? 'N/A',
              'zone': customer['zone'] ?? 'N/A',
              'state': customer['state'] ?? 'N/A',
              'district': customer['district'] ?? 'N/A',
              'age': customer['age'] ?? 0,
              'imageUrl': customer['image_url'],
              'orders': orderStats['total_orders'] ?? 0,
              'spent': (orderStats['total_spent'] ?? 0).toInt(),
              'lastOrder': lastOrderDate,
            };
          }).toList();
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      print('Error fetching customers: $e');
      setState(() {
        _isLoadingCustomers = false;
      });
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.black26,
        leading: Builder(
          builder: (context) => Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        title: Text('User Management', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchFarmers();
              _fetchCustomers();
              _fetchTransporters();
              _fetchDeliveryPersons();
            },
            tooltip: 'Reload',
          ),
        ],
      ),
      drawer: AdminDrawer(token: widget.token, user: widget.user, currentIndex: 1),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Farmers', Icons.agriculture_rounded, Color(0xFF4CAF50), selectedFilter == 'Farmers', () {
                    setState(() => selectedFilter = 'Farmers');
                  }),
                  SizedBox(width: 8),
                  _buildFilterChip('Customers', Icons.people_rounded, Color(0xFF2196F3), selectedFilter == 'Customers', () {
                    setState(() => selectedFilter = 'Customers');
                  }),
                  SizedBox(width: 8),
                  _buildFilterChip('Transporters', Icons.local_shipping_rounded, Color(0xFFFF9800), selectedFilter == 'Transporters', () {
                    setState(() => selectedFilter = 'Transporters');
                  }),
                  SizedBox(width: 8),
                  _buildFilterChip('Delivery', Icons.delivery_dining_rounded, Color(0xFF9C27B0), selectedFilter == 'Delivery', () {
                    setState(() => selectedFilter = 'Delivery');
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: selectedFilter == null
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE8F5E9), Color(0xFFF5F7FA)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.manage_accounts_rounded, size: 80, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text('Select a category to manage', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                : selectedFilter == 'Farmers'
                    ? _buildFarmersList()
                    : selectedFilter == 'Customers'
                        ? _buildCustomersList()
                        : selectedFilter == 'Transporters'
                            ? _buildTransportersList()
                            : selectedFilter == 'Delivery'
                                ? _buildDeliveryPersonsList()
                                : Container(
                                    color: Color(0xFFF5F7FA),
                                    child: Center(
                                      child: Text('$selectedFilter management coming soon', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                    ),
                                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 8,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AdminManagementPage(token: widget.token, user: widget.user)),
              (route) => false,
            );
          } else if (index == 1) {
            // Already on management page
          } else if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AdminOrdersPage(token: widget.token, user: widget.user)),
              (route) => false,
            );
          } else if (index == 3) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ReportsPage(token: widget.token, user: widget.user)),
              (route) => false,
            );
          } else if (index == 4) {
            _showAdminProfile();
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Management'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildFarmersList() {
    if (_isLoadingFarmers) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (farmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No farmers found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Container(
      color: Color(0xFFF5F7FA),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: farmers.length,
        itemBuilder: (context, index) => _buildFarmerAccordion(farmers[index]),
      ),
    );
  }

  Widget _buildFarmerAccordion(Map<String, dynamic> farmer) {
    bool isExpanded = expandedFarmerId == farmer['id'];
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expandedFarmerId = isExpanded ? null : farmer['id']),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: farmer['imageUrl'] != null && farmer['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                              farmer['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 28, color: Colors.white),
                            )
                          : Icon(Icons.person, size: 28, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(farmer['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                            ),
                            if (farmer['isVerified'])
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(farmer['email'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildExpandedContent(farmer),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(Map<String, dynamic> farmer) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatBox('Products', farmer['products'].toString(), Icons.inventory, Colors.blue)),
              SizedBox(width: 8),
              Expanded(child: _buildStatBox('Orders', farmer['orders'].toString(), Icons.shopping_cart, Colors.orange)),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade300)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.currency_rupee, color: Colors.green[700], size: 18),
                        SizedBox(width: 8),
                        Text('Total Revenue', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                    Text('₹${farmer['revenue'].toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  ],
                ),
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Text(farmer['phone'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Expanded(child: Text('${farmer['zone']}, ${farmer['district']}, ${farmer['state']}', style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FarmerDetailsPage(farmerId: farmer['id'], token: widget.token, user: widget.user))),
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('View Full Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    if (_isLoadingCustomers) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No customers found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Container(
      color: Color(0xFFF5F7FA),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: customers.length,
        itemBuilder: (context, index) => _buildCustomerAccordion(customers[index]),
      ),
    );
  }

  Widget _buildCustomerAccordion(Map<String, dynamic> customer) {
    bool isExpanded = expandedCustomerId == customer['id'];
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expandedCustomerId = isExpanded ? null : customer['id']),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: customer['imageUrl'] != null && customer['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                              customer['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 28, color: Colors.white),
                            )
                          : Icon(Icons.person, size: 28, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
                        Text(customer['email'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildCustomerExpandedContent(customer),
        ],
      ),
    );
  }

  Widget _buildCustomerExpandedContent(Map<String, dynamic> customer) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildCustomerStatBox('Orders', customer['orders'].toString(), Icons.shopping_bag, Colors.blue)),
              SizedBox(width: 8),
              Expanded(child: _buildCustomerStatBox('Spent', '₹${customer['spent']}', Icons.currency_rupee, Colors.green)),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade300)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.blue[700], size: 18),
                    SizedBox(width: 8),
                    Text('Last Order', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
                Text(customer['lastOrder'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700])),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerDetailsPage(
                          customerId: customer['id'],
                          token: widget.token,
                          customer: customer,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('View Full Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTransportersList() {
    if (_isLoadingTransporters) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
    }

    if (transporters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No transporters found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Container(
      color: Color(0xFFF5F7FA),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: transporters.length,
        itemBuilder: (context, index) => _buildTransporterAccordion(transporters[index]),
      ),
    );
  }

  Widget _buildTransporterAccordion(Map<String, dynamic> transporter) {
    bool isExpanded = expandedTransporterId == transporter['id'];
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expandedTransporterId = isExpanded ? null : transporter['id']),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF9800)]),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: transporter['imageUrl'] != null && transporter['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                              transporter['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.local_shipping, size: 28, color: Colors.white),
                            )
                          : Icon(Icons.local_shipping, size: 28, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(transporter['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: transporter['verifiedStatus'] ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                transporter['verifiedStatus'] ? 'Verified' : 'Unverified',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: transporter['verifiedStatus'] ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(transporter['email'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildTransporterExpandedContent(transporter),
        ],
      ),
    );
  }

  Widget _buildTransporterExpandedContent(Map<String, dynamic> transporter) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTransporterStatBox('Total Orders', transporter['totalOrders'].toString(), Icons.shopping_bag, Colors.orange)),
              SizedBox(width: 8),
              Expanded(child: _buildTransporterStatBox('Source', transporter['sourceOrders'].toString(), Icons.upload, Colors.purple)),
              SizedBox(width: 8),
              Expanded(child: _buildTransporterStatBox('Destination', transporter['destOrders'].toString(), Icons.download, Colors.blue)),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade300)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.currency_rupee, color: Colors.orange[700], size: 18),
                        SizedBox(width: 8),
                        Text('Total Amount', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                    Text('₹${transporter['totalAmount'].toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[700])),
                  ],
                ),
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Text(transporter['phone'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Expanded(child: Text('${transporter['zone']}, ${transporter['district']}, ${transporter['state']}', style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransporterDetailsPage(
                          transporterId: transporter['id'],
                          token: widget.token,
                          transporter: transporter,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('View Full Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransporterStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDeliveryPersonsList() {
    if (_isLoadingDeliveryPersons) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF9C27B0)));
    }

    if (deliveryPersons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delivery_dining_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('No delivery persons found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Container(
      color: Color(0xFFF5F7FA),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: deliveryPersons.length,
        itemBuilder: (context, index) => _buildDeliveryPersonAccordion(deliveryPersons[index]),
      ),
    );
  }

  Widget _buildDeliveryPersonAccordion(Map<String, dynamic> dp) {
    bool isExpanded = expandedDeliveryPersonId == dp['id'];
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expandedDeliveryPersonId = isExpanded ? null : dp['id']),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFAB47BC), Color(0xFF9C27B0)]),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: dp['imageUrl'] != null && dp['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                              dp['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.delivery_dining, size: 28, color: Colors.white),
                            )
                          : Icon(Icons.delivery_dining, size: 28, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(dp['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: dp['isAvailable'] ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                dp['isAvailable'] ? 'Available' : 'Busy',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: dp['isAvailable'] ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(dp['vehicleNumber'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildDeliveryPersonExpandedContent(dp),
        ],
      ),
    );
  }

  Widget _buildDeliveryPersonExpandedContent(Map<String, dynamic> dp) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTransporterStatBox('Orders', dp['totalOrders'].toString(), Icons.shopping_bag, Colors.purple)),
              SizedBox(width: 8),
              Expanded(child: _buildTransporterStatBox('Rating', dp['rating'], Icons.star, Colors.amber)),
              SizedBox(width: 8),
              Expanded(child: _buildTransporterStatBox('Vehicle', dp['vehicleType'].toUpperCase(), Icons.two_wheeler, Colors.blue)),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple.shade300)),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Text(dp['phone'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.badge, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Expanded(child: Text(dp['licenseNumber'], style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Expanded(child: Text(dp['currentLocation'], style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeliveryPersonDetailsPage(
                          deliveryPersonId: dp['id'],
                          token: widget.token,
                          deliveryPerson: dp,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.visibility, size: 18),
                  label: Text('View Full Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : color),
            SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showAdminProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(widget.user['name'] ?? 'Admin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
            SizedBox(height: 4),
            Text(widget.user['email'] ?? 'admin@farmercrate.com', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('Administrator', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}