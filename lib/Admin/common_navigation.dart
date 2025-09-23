import 'package:flutter/material.dart';
import '../Signin.dart';
import 'adminreport.dart';
import 'total_order.dart';
import 'ConsumerManagement.dart';
import 'Farmeruser.dart';
import 'transpoter_mang.dart';

class AdminNavigation {
  static PreferredSizeWidget buildAppBar(BuildContext context, String title, {VoidCallback? onRefresh}) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 5,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: Colors.green[800]),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        'FarmerCrate Admin',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.green[800]),
            onPressed: onRefresh,
          ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.green[800]),
          onPressed: () {},
        ),
      ],
    );
  }

  static Widget buildDrawer(BuildContext context, dynamic user, String token) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green[600],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FarmerCrate Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.green[600]),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminUserManagementPage(
                    token: token,
                    user: user,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.pending_actions, color: Colors.green[600]),
            title: const Text('User Management'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminUserManagementPage(
                    token: token,
                    user: user,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.people, color: Colors.green[600]),
            title: const Text('Consumer Management'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerManagementScreen(
                    token: token,
                    user: user,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.analytics, color: Colors.green[600]),
            title: const Text('Reports'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportsPage(token: token),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.local_shipping, color: Colors.green[600]),
            title: const Text('Transporter Management'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterManagementPage(
                    token: token,
                    user: user,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart, color: Colors.green[600]),
            title: const Text('Total Orders'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersManagementPage(
                    user: user,
                    token: token,
                  ),
                ),
              );
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

  static Widget buildBottomNavigationBar(BuildContext context, int currentIndex, dynamic user, String token) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.blueGrey,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        currentIndex: currentIndex,
        elevation: 0,
        onTap: (index) {
          // Handle navigation based on selected index
          switch (index) {
            case 0: // Home
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminUserManagementPage(
                    token: token,
                    user: user,
                  ),
                ),
              );
              break;
            case 1: // Total Orders
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersManagementPage(
                    user: user,
                    token: token,
                  ),
                ),
              );
              break;
            case 2: // Report
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportsPage(token: token),
                ),
              );
              break;
            case 3: // Profile/Consumer Management
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerManagementScreen(
                    token: token,
                    user: user,
                  ),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, size: 24),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics, size: 24),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 24),
            label: 'Consumers',
          ),
        ],
      ),
    );
  }

  static Widget buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F5E8),
            Color(0xFFC8E6C9),
            Color(0xFFA5D6A7),
            Color(0xFF81C784),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }
}
