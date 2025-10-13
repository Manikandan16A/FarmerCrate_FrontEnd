import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'transporter_dashboard.dart';
import 'order_status_page.dart';
import 'order_history_page.dart';
import 'vehicle_page.dart';

class ProfilePage extends StatefulWidget {
  final String? token;

  const ProfilePage({super.key, this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/transporters/profile'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profileData = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: profileData?['name']);
    final mobileController = TextEditingController(text: profileData?['mobile_number']);
    final emailController = TextEditingController(text: profileData?['email']);
    final ageController = TextEditingController(text: profileData?['age']?.toString());
    final addressController = TextEditingController(text: profileData?['address']);
    final zoneController = TextEditingController(text: profileData?['zone']);
    final districtController = TextEditingController(text: profileData?['district']);
    final stateController = TextEditingController(text: profileData?['state']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Profile', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: mobileController, decoration: InputDecoration(labelText: 'Mobile', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: ageController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Age', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: zoneController, decoration: InputDecoration(labelText: 'Zone', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: districtController, decoration: InputDecoration(labelText: 'District', border: OutlineInputBorder())),
              SizedBox(height: 12),
              TextField(controller: stateController, decoration: InputDecoration(labelText: 'State', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateProfile({
                'name': nameController.text,
                'mobile_number': mobileController.text,
                'email': emailController.text,
                'age': int.tryParse(ageController.text) ?? 0,
                'address': addressController.text,
                'zone': zoneController.text,
                'district': districtController.text,
                'state': stateController.text,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2E7D32)),
            child: Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/transporters/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully'), backgroundColor: Color(0xFF4CAF50)),
        );
        _fetchProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    Widget page;
    switch (index) {
      case 0:
        page = TransporterDashboard(token: widget.token);
        break;
      case 1:
        page = OrderStatusPage(token: widget.token);
        break;
      case 2:
        page = OrderHistoryPage(token: widget.token);
        break;
      case 3:
        page = VehiclePage(token: widget.token);
        break;
      default:
        return;
    }
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8F0),
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(Icons.person, size: 50, color: Color(0xFF2E7D32)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            profileData?['name'] ?? 'Transporter',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            profileData?['email'] ?? 'N/A',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoCard('Contact', profileData?['mobile_number'] ?? 'N/A', Icons.phone),
                          _buildInfoCard('Age', profileData?['age']?.toString() ?? 'N/A', Icons.cake),
                          _buildInfoCard('Address', profileData?['address'] ?? 'N/A', Icons.location_on),
                          _buildInfoCard('Zone', profileData?['zone'] ?? 'N/A', Icons.map),
                          _buildInfoCard('District', profileData?['district'] ?? 'N/A', Icons.location_city),
                          _buildInfoCard('State', profileData?['state'] ?? 'N/A', Icons.public),
                          _buildInfoCard('Unique ID', profileData?['unique_id'] ?? 'N/A', Icons.badge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Tracking'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Vehicles'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF2E7D32), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
