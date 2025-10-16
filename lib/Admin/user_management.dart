import 'package:flutter/material.dart';
import '../auth/Signin.dart';
import 'admin_homepage.dart';
import 'adminreport.dart';
import 'farmer_details_page.dart';
import 'ConsumerManagement.dart';
import 'transpoter_mang.dart';

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
  
  // Mock farmer data
  List<Map<String, dynamic>> farmers = [
    {'id': 'FARM001', 'name': 'John Farmer', 'email': 'john@example.com', 'phone': '+91 9876543210', 'products': 12, 'orders': 8, 'customers': 25, 'revenue': 45000},
    {'id': 'FARM002', 'name': 'Sarah Green', 'email': 'sarah@example.com', 'phone': '+91 9876543211', 'products': 8, 'orders': 5, 'customers': 15, 'revenue': 32000},
    {'id': 'FARM003', 'name': 'Mike Brown', 'email': 'mike@example.com', 'phone': '+91 9876543212', 'products': 15, 'orders': 12, 'customers': 30, 'revenue': 58000},
    {'id': 'FARM004', 'name': 'Lisa White', 'email': 'lisa@example.com', 'phone': '+91 9876543213', 'products': 10, 'orders': 7, 'customers': 20, 'revenue': 38000},
  ];
  
  // Mock customer data
  List<Map<String, dynamic>> customers = [
    {'id': 'CUST001', 'name': 'Alice Johnson', 'email': 'alice@example.com', 'phone': '+91 9876543220', 'orders': 15, 'spent': 12500, 'lastOrder': '2024-01-15'},
    {'id': 'CUST002', 'name': 'Bob Smith', 'email': 'bob@example.com', 'phone': '+91 9876543221', 'orders': 10, 'spent': 8500, 'lastOrder': '2024-01-14'},
    {'id': 'CUST003', 'name': 'Carol Davis', 'email': 'carol@example.com', 'phone': '+91 9876543222', 'orders': 20, 'spent': 15000, 'lastOrder': '2024-01-16'},
    {'id': 'CUST004', 'name': 'David Wilson', 'email': 'david@example.com', 'phone': '+91 9876543223', 'orders': 8, 'spent': 6500, 'lastOrder': '2024-01-13'},
  ];

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
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  SizedBox(height: 4),
                  Text('Manage your platform', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_rounded, color: Colors.green[600]),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminManagementPage(token: widget.token, user: widget.user)));
              },
            ),
            ListTile(
              leading: Icon(Icons.manage_accounts_rounded, color: Colors.green[600]),
              title: const Text('Management'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.analytics_rounded, color: Colors.green[600]),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsPage(token: widget.token, user: widget.user)));
              },
            ),
            ListTile(
              leading: Icon(Icons.person_rounded, color: Colors.green[600]),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _showAdminProfile();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[600]),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);
              },
            ),
          ],
        ),
      ),
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
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminManagementPage(token: widget.token, user: widget.user)));
          } else if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Orders page coming soon'),
                backgroundColor: Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsPage(token: widget.token, user: widget.user)));
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
                    child: Icon(Icons.person, size: 28, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(farmer['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatBox('Products', farmer['products'].toString(), Icons.inventory, Colors.blue)),
              SizedBox(width: 8),
              Expanded(child: _buildStatBox('Orders', farmer['orders'].toString(), Icons.shopping_cart, Colors.orange)),
              SizedBox(width: 8),
              Expanded(child: _buildStatBox('Customers', farmer['customers'].toString(), Icons.people, Colors.purple)),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.currency_rupee, color: Colors.green[700], size: 20),
                    Text('Total Revenue', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
                Text('₹${farmer['revenue']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
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
                    child: Icon(Icons.person, size: 28, color: Colors.white),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Customer details page coming soon'),
                        backgroundColor: Color(0xFF1976D2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
