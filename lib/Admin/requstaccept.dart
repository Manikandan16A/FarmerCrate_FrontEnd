import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminFarmerPage extends StatefulWidget {
  const AdminFarmerPage({Key? key}) : super(key: key);

  @override
  State<AdminFarmerPage> createState() => _AdminFarmerPageState();
}

class _AdminFarmerPageState extends State<AdminFarmerPage> {
  List<Farmer> farmers = [];
  bool isLoading = true;

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
      // Replace with your actual API endpoint
      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/pending'),
        headers: {
          'Content-Type': 'application/json',
          // Add any necessary authentication headers
          // 'Authorization': 'Bearer your_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
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
                  // Replace with your actual delete API endpoint
                  final response = await http.delete(
                    Uri.parse('https://your-api-endpoint.com/api/farmers/$farmerId'),
                    headers: {
                      'Content-Type': 'application/json',
                      // Add any necessary authentication headers
                      // 'Authorization': 'Bearer your_token',
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
      // Replace with your actual verification API endpoint
      final response = await http.put(
        Uri.parse('https://your-api-endpoint.com/api/farmers/$farmerId/verify'),
        headers: {
          'Content-Type': 'application/json',
          // Add any necessary authentication headers
          // 'Authorization': 'Bearer your_token',
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

  void _navigateToSignUp() {
    // Navigate to sign up page - replace with your actual navigation
    Navigator.pushNamed(context, '/signup');
  }

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
            stops: [0.0, 0.3, 0, 1.0],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
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

              // Stats Card
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

              // Farmers List
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
                      : GridView.builder(
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
            ],
          ),
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
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Row(
          children: [
            // Avatar
            Container(
              width: screenWidth * 0.15,
              height: screenWidth * 0.15,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.075),
              ),
              child: Center(
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

            // Farmer Details
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
                            _buildDetailRow(Icons.phone, farmer.phone),
                            _buildDetailRow(Icons.location_on, farmer.location),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(Icons.landscape, farmer.farmSize),
                            _buildDetailRow(Icons.grass, farmer.cropType),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: screenWidth * 0.05),

            // Action Buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Verification Button
                ElevatedButton(
                  onPressed: () => _toggleVerification(farmer.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: farmer.isVerified
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE0E0E0),
                    foregroundColor: farmer.isVerified
                        ? Colors.white
                        : const Color(0xFF424242),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    elevation: farmer.isVerified ? 2 : 0,
                    minimumSize: Size(screenWidth * 0.2, screenHeight * 0.04),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        farmer.isVerified ? Icons.verified : Icons.pending,
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        farmer.isVerified ? 'Verified' : 'Unverified',
                        style: TextStyle(fontSize: screenWidth * 0.03),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenWidth * 0.02),

                // Delete Button
                ElevatedButton(
                  onPressed: () => _deleteFarmer(farmer.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    foregroundColor: const Color(0xFFD32F2F),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    elevation: 0,
                    minimumSize: Size(screenWidth * 0.2, screenHeight * 0.04),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete, size: screenWidth * 0.04),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        'Delete',
                        style: TextStyle(fontSize: screenWidth * 0.03),
                      ),
                    ],
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
}

class Farmer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String farmSize;
  final String cropType;
  bool isVerified;

  Farmer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.farmSize,
    required this.cropType,
    required this.isVerified,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) {
    return Farmer(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      farmSize: json['farmSize'] ?? '',
      cropType: json['cropType'] ?? '',
      isVerified: json['isVerified'] ?? false,
    );
  }
}