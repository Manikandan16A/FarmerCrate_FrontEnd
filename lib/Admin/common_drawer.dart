import 'package:flutter/material.dart';
import '../auth/Signin.dart';
import 'admin_homepage.dart';
import 'user_management.dart';
import 'adminreport.dart';
import 'admin_orders_page.dart';

class AdminDrawer extends StatelessWidget {
  final String token;
  final dynamic user;
  final int currentIndex;

  const AdminDrawer({
    Key? key,
    required this.token,
    required this.user,
    this.currentIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage your platform',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home_rounded, color: Colors.green[600]),
            title: const Text('Home'),
            selected: currentIndex == 0,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminManagementPage(token: token, user: user),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.manage_accounts_rounded, color: Colors.green[600]),
            title: const Text('Management'),
            selected: currentIndex == 1,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminUserManagementPage(token: token, user: user),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart_rounded, color: Colors.green[600]),
            title: const Text('Orders'),
            selected: currentIndex == 2,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminOrdersPage(token: token, user: user),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics_rounded, color: Colors.green[600]),
            title: const Text('Reports'),
            selected: currentIndex == 3,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportsPage(token: token, user: user),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_rounded, color: Colors.green[600]),
            title: const Text('Profile'),
            selected: currentIndex == 4,
            onTap: () {
              Navigator.pop(context);
              _showAdminProfile(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[600]),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAdminProfile(BuildContext context) {
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
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              user['name'] ?? 'Admin',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            SizedBox(height: 4),
            Text(
              user['email'] ?? 'admin@farmercrate.com',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Administrator',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}