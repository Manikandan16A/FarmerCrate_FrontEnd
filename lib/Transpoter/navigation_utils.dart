import 'package:flutter/material.dart';
import 'transporter_dashboard.dart';
import 'order_status_page.dart';
import 'order_history_page.dart';
import 'vehicle_page.dart';
import 'profile_page.dart';

class TransporterNavigationUtils {
  static Widget buildTransporterDrawer(BuildContext context, String? token, int selectedIndex, Function(int) onItemTapped) {
    return Drawer(
      child: Container(
        color: Colors.white,
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
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.local_shipping, size: 40, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text('Transporter', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  SizedBox(height: 4),
                  Text('Dashboard', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
                ],
              ),
            ),
            SizedBox(height: 8),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 0, selectedIndex == 0, () {
              Navigator.pop(context);
              if (selectedIndex != 0) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TransporterDashboard(token: token)));
              }
            }),
            _buildDrawerItem(Icons.track_changes, 'Order Tracking', 1, selectedIndex == 1, () {
              Navigator.pop(context);
              if (selectedIndex != 1) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OrderStatusPage(token: token)));
              }
            }),
            _buildDrawerItem(Icons.history, 'Order History', 2, selectedIndex == 2, () {
              Navigator.pop(context);
              if (selectedIndex != 2) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OrderHistoryPage(token: token)));
              }
            }),
            _buildDrawerItem(Icons.local_shipping, 'Vehicles', 3, selectedIndex == 3, () {
              Navigator.pop(context);
              if (selectedIndex != 3) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VehiclePage(token: token)));
              }
            }),
            _buildDrawerItem(Icons.person, 'Profile', 4, selectedIndex == 4, () {
              Navigator.pop(context);
              if (selectedIndex != 4) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfilePage(token: token)));
              }
            }),
            Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
                icon: Icon(Icons.logout, size: 20),
                label: Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildDrawerItem(IconData icon, String title, int index, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Color(0xFF2E7D32).withOpacity(0.1) : Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2E7D32) : Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : Color(0xFF2E7D32), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Color(0xFF2E7D32) : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: Colors.red, size: 24),
            ),
            SizedBox(width: 12),
            Text('Logout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to logout?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: Icon(Icons.logout, size: 18),
            label: Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}