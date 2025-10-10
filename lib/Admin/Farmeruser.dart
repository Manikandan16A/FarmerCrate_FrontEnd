import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'common_navigation.dart';

class AdminUserManagementPage extends StatefulWidget {
  final String token;
  final dynamic user;

  const AdminUserManagementPage({Key? key, required this.token, this.user}) : super(key: key);

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  String _searchQuery = '';
  List<UserData> users = [];
  bool _isLoading = true; // Add loading state
  int _currentIndex = 0; // Home tab is selected

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch only Farmers
      final farmersResponse = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (farmersResponse.statusCode == 200) {
        final data = json.decode(farmersResponse.body);
        print('Farmers data: ${data['data']}');
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            users = (data['data'] as List).map((json) => UserData.fromJson(json, 'Farmer')).toList();
            print('Loaded ${users.length} farmers');
            if (users.isNotEmpty) {
              print('First farmer - id: ${users[0].id}, uniqueId: ${users[0].uniqueId}');
            }
            _isLoading = false;
          });
        } else {
          setState(() {
            users = [];
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load farmers');
      }
    } catch (e) {
      print('Error fetching farmers: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching farmers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      print('Deleting farmer with ID: $userId');
      final response = await http.delete(
        Uri.parse('https://farmercrate.onrender.com/api/admin/farmers/$userId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            users.removeWhere((user) => user.uniqueId == userId || user.id == userId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Farmer deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to delete farmer');
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error. Please contact administrator.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: Status ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting farmer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(UserData user) {
    print('Delete confirmation - id: ${user.id}, uniqueId: ${user.uniqueId}');
    final deleteId = user.id.isNotEmpty ? user.id : user.uniqueId;
    print('Will use ID: $deleteId');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Farmer'),
          content: Text('Are you sure you want to delete farmer "${user.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(deleteId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminNavigation.buildAppBar(context, 'Farmer Management', onRefresh: _fetchUsers),
      drawer: AdminNavigation.buildDrawer(context, widget.user ?? {}, widget.token),
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
          child: Column(
            children: [
              _buildSearchSection(),
              Expanded(
                child: _isLoading ? _buildLoadingWidget() : _buildUserList(), // Show loading or content
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminNavigation.buildBottomNavigationBar(context, _currentIndex, widget.user ?? {}, widget.token),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading animation with agriculture theme
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.agriculture,
                size: 60,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading Farmers...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait while we fetch farmer details',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Circular progress indicator with green color
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            // Optional: Add a refresh button in case of loading issues
            TextButton.icon(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search farmers...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF4CAF50)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUserList() {
    final filteredUsers = users.where((user) {
      // Apply search filter only
      return _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.zone.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.district.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          // Show filter status and count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Farmers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '${filteredUsers.length} farmer${filteredUsers.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                return _buildUserCard(filteredUsers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No farmers found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Try adjusting your search',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserData user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(user.imageUrl),
          radius: 25,
          backgroundColor: Colors.green[100],
          child: user.imageUrl.isEmpty
              ? Icon(Icons.person, color: Colors.green[700], size: 30)
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text('${user.zone}, ${user.state}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getUserTypeColor(user.userType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getUserTypeColor(user.userType).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                user.userType,
                style: TextStyle(
                  color: _getUserTypeColor(user.userType),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(user),
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  void _showUserDetails(UserData user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.imageUrl),
                      radius: 30,
                      backgroundColor: Colors.green[100],
                      child: user.imageUrl.isEmpty
                          ? Text(
                        user.name.split(' ').map((e) => e[0]).join(''),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            user.userType,
                            style: TextStyle(
                              fontSize: 14,
                              color: _getUserTypeColor(user.userType),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoRow(Icons.person, 'User ID:', user.uniqueId),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.email, 'Email:', user.email),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.phone, 'Phone:', user.mobileNumber),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.location_on, 'Address:', user.address),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.map, 'Zone:', user.zone),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.location_city, 'State:', user.state),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.location_on, 'District:', user.district),
                const SizedBox(height: 16),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'Farmer':
        return Colors.green;
      case 'Transporter':
        return Colors.blue;
      case 'Consumer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                TextSpan(
                  text: ' $value',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class UserData {
  final String id;
  final String uniqueId;
  final String name;
  final String email;
  final String mobileNumber;
  final String address;
  final String zone;
  final String state;
  final String district;
  final bool verifiedStatus;
  final int? age;
  final String accountNumber;
  final String ifscCode;
  final String imageUrl;
  final String userType;

  UserData({
    required this.id,
    required this.uniqueId,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.address,
    required this.zone,
    required this.state,
    required this.district,
    required this.verifiedStatus,
    this.age,
    required this.accountNumber,
    required this.ifscCode,
    required this.imageUrl,
    required this.userType,
  });

  factory UserData.fromJson(Map<String, dynamic> json, String userType) {
    return UserData(
      id: json['farmer_id']?.toString() ?? json['id']?.toString() ?? '',
      uniqueId: json['global_farmer_id']?.toString() ?? json['unique_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      address: json['address'] ?? '',
      zone: json['zone'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      verifiedStatus: json['is_verified_by_gov'] ?? false,
      age: json['age'],
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      imageUrl: json['image_url'] ?? '',
      userType: userType,
    );
  }
}