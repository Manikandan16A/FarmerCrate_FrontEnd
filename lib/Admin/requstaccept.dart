import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Signin.dart';
import 'ConsumerManagement.dart';
import 'Farmeruser.dart';

class AdminFarmerPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const AdminFarmerPage({Key? key, required this.token, required this.user}) : super(key: key);

  @override
  State<AdminFarmerPage> createState() => _AdminFarmerPageState();
}

class _AdminFarmerPageState extends State<AdminFarmerPage> {
  List<Farmer> farmers = [];
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchFarmers();
  }

  Future<void> _fetchFarmers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      print(response.body);

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> data = responseData['data'];
        setState(() {
          farmers = data.map((json) => Farmer.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load farmers');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching farmers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFarmer(String farmerId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Delete Farmer',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this farmer? This action cannot be undone.',
            style: TextStyle(color: Color(0xFF424242)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF757575)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.delete(
                    Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/$farmerId'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer ${widget.token}',
                    },
                  );

                  if (response.statusCode == 200) {
                    setState(() {
                      farmers.removeWhere((farmer) => farmer.id == farmerId);
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Farmer deleted successfully'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  } else {
                    throw Exception('Failed to delete farmer');
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting farmer: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleVerification(String farmerId) async {
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/$farmerId/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'isVerified': !farmers.firstWhere((farmer) => farmer.id == farmerId).isVerified,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final farmerIndex = farmers.indexWhere((farmer) => farmer.id == farmerId);
          if (farmerIndex != -1) {
            farmers[farmerIndex].isVerified = !farmers[farmerIndex].isVerified;
          }
        });

        final farmer = farmers.firstWhere((farmer) => farmer.id == farmerId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              farmer.isVerified ? 'Farmer verified successfully' : 'Farmer unverified',
            ),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      } else {
        throw Exception('Failed to update verification status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApproveDialog(Farmer farmer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve Farmer'),
          content: const Text('Do you want to verify this farmer account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _approveFarmer(farmer.id);
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveFarmer(String farmerId) async {
    try {
      final response = await http.put(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/$farmerId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farmer account verified successfully')),
        );
        _fetchFarmers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to verify farmer account')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.green[800]),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
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
                setState(() { _currentIndex = 0; });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.pending_actions, color: Colors.green[600]),
              title: const Text('Farmer Management'),
              onTap: () {// Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUserManagementPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.pending_actions, color: Colors.green[600]),
              title: const Text('Consumer Management'),
              onTap: () {// Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  CustomerManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.green[600]),
              title: const Text('Profile'),
              onTap: () {
                setState(() { _currentIndex = 2; });
                Navigator.pop(context);
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
      ),
      body: Container(
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
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farmer Management',
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20),
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Manage farmer accounts and verification',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: screenWidth * 0.025,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Farmers',
                      farmers.length.toString(),
                      Icons.group,
                    ),
                    Container(
                      height: screenHeight * 0.06,
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    _buildStatItem(
                      'Verified',
                      farmers.where((f) => f.isVerified).length.toString(),
                      Icons.verified,
                    ),
                    Container(
                      height: screenHeight * 0.06,
                      width: 1,
                      color: const Color(0xFFE0E0E0),
                    ),
                    _buildStatItem(
                      'Pending',
                      farmers.where((f) => !f.isVerified).length.toString(),
                      Icons.pending,
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                  child: farmers.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.agriculture,
                          size: screenWidth * 0.2,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'No farmers found',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                      : SingleChildScrollView(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: screenHeight * 0.025),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        childAspectRatio: screenWidth / (screenHeight * 0.2),
                        mainAxisSpacing: screenHeight * 0.02,
                      ),
                      itemCount: farmers.length,
                      itemBuilder: (context, index) {
                        final farmer = farmers[index];
                        return _buildFarmerCard(farmer);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
          currentIndex: _currentIndex,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions, size: 24),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF2E7D32),
          size: screenWidth * 0.07,
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: const Color(0xFF424242),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmerCard(Farmer farmer) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: screenWidth * 0.025,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.075),
                  ),
                  child: farmer.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(screenWidth * 0.075),
                          child: Image.network(
                            farmer.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  farmer.name.split(' ').map((n) => n[0]).take(2).join(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            farmer.name.split(' ').map((n) => n[0]).take(2).join(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                SizedBox(width: screenWidth * 0.05),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              farmer.name,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (farmer.isVerified)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenWidth * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                              child: Text(
                                'VERIFIED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.025,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(Icons.email, farmer.email),
                                _buildDetailRow(Icons.phone, farmer.mobileNumber),
                                _buildDetailRow(Icons.location_on, farmer.address),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(Icons.landscape, farmer.zone),
                                _buildDetailRow(Icons.grass, farmer.state),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: farmer.isVerified
                          ? const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : const LinearGradient(
                        colors: [Color(0xFF8BC34A), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: (farmer.isVerified
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800))
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        onTap: () => _showApproveDialog(farmer),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.01,
                            vertical: screenWidth * 0.018,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                farmer.isVerified ? Icons.verified : Icons.pending_actions,
                                size: screenWidth * 0.04,
                                color: Colors.white,
                              ),
                              SizedBox(width: screenWidth * 0.01),
                              Text(
                                farmer.isVerified ? 'Verified' : 'Verify',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => _deleteFarmer(farmer.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        elevation: 2,
                        minimumSize: Size(screenWidth * 0.12, screenHeight * 0.04),
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.018),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        onTap: () => _showFarmerDetailsDialog(farmer),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.01,
                            vertical: screenWidth * 0.018,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: screenWidth * 0.04,
                                color: Colors.white,
                              ),
                              SizedBox(width: screenWidth * 0.01),
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.01),
      child: Row(
        children: [
          Icon(
            icon,
            size: screenWidth * 0.035,
            color: const Color(0xFF757575),
          ),
          SizedBox(width: screenWidth * 0.015),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                color: const Color(0xFF424242),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showFarmerDetailsDialog(Farmer farmer) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FarmerDetailsFullScreen(farmer: farmer, onVerificationToggle: _toggleVerification),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}

class _FarmerDetailsFullScreen extends StatelessWidget {
  final Farmer farmer;
  final Function(String) onVerificationToggle;

  const _FarmerDetailsFullScreen({
    required this.farmer,
    required this.onVerificationToggle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
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
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Text(
                        'Farmer Details',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenWidth * 0.02,
                      ),
                      decoration: BoxDecoration(
                        gradient: farmer.isVerified
                            ? const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        )
                            : const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                        ),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        boxShadow: [
                          BoxShadow(
                            color: (farmer.isVerified
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800))
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            farmer.isVerified ? Icons.verified : Icons.pending,
                            color: Colors.white,
                            size: screenWidth * 0.04,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            farmer.isVerified ? 'VERIFIED' : 'PENDING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: screenWidth * 0.25,
                              height: screenWidth * 0.25,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.125),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: farmer.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(screenWidth * 0.125),
                                child: Image.network(
                                  farmer.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        farmer.name.split(' ').map((n) => n[0]).take(2).join(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.08,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                                  : Center(
                                child: Text(
                                  farmer.name.split(' ').map((n) => n[0]).take(2).join(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.08,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.04),
                            Text(
                              farmer.name,
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1B5E20),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            Text(
                              farmer.email,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: const Color(0xFF757575),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Personal Information',
                        Icons.person,
                        [
                          _buildInfoTile(Icons.phone, 'Mobile Number', farmer.mobileNumber),
                          _buildInfoTile(Icons.cake, 'Age', '${farmer.age} years'),
                          _buildInfoTile(Icons.location_on, 'Address', farmer.address),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Location Details',
                        Icons.map,
                        [
                          _buildInfoTile(Icons.landscape, 'Zone', farmer.zone),
                          _buildInfoTile(Icons.location_city, 'State', farmer.state),
                          _buildInfoTile(Icons.domain, 'District', farmer.district),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Banking Details',
                        Icons.account_balance,
                        [
                          _buildInfoTile(Icons.account_balance_wallet, 'Account Number', farmer.accountNumber),
                          _buildInfoTile(Icons.code, 'IFSC Code', farmer.ifscCode),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      _buildInfoSection(
                        'Account Information',
                        Icons.info,
                        [
                          _buildInfoTile(Icons.calendar_today, 'Created At', farmer.createdAt),
                        ],
                        screenWidth,
                      ),
                      SizedBox(height: screenWidth * 0.08),
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.07,
                        decoration: BoxDecoration(
                          gradient: farmer.isVerified
                              ? const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          boxShadow: [
                            BoxShadow(
                              color: (farmer.isVerified
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF4CAF50))
                                  .withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                            onTap: () {
                              onVerificationToggle(farmer.id);
                              Navigator.of(context).pop();
                            },
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    farmer.isVerified ? Icons.cancel : Icons.verified,
                                    color: Colors.white,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    farmer.isVerified ? 'Unverify Farmer' : 'Verify Farmer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.05),
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

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.isEmpty ? const Color(0xFF9E9E9E) : const Color(0xFF424242),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Farmer {
  final String id;
  final String name;
  final String email;
  final String mobileNumber;
  final String address;
  final String zone;
  final String state;
  final String district;
  final int age;
  final String accountNumber;
  final String ifscCode;
  final String imageUrl;
  final String createdAt;
  bool isVerified;

  Farmer({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.zone,
    required this.state,
    required this.district,
    required this.age,
    required this.accountNumber,
    required this.ifscCode,
    required this.imageUrl,
    required this.createdAt,
    required this.isVerified,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      address: json['address'] ?? '',
      zone: json['zone'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      age: json['age'] ?? 0,
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      imageUrl: json['image_url'] ?? '',
      createdAt: json['created_at'] ?? '',
      isVerified: json['isVerified'] ?? false,
    );
  }
}