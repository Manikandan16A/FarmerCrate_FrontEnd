import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'common_navigation.dart';

class Customer {
  final int id;
  final String customerName;
  final String mobileNumber;
  final String email;
  final String address;
  final String zone;
  final String state;
  final String district;
  final int? age;
  final String? imageUrl;
  final bool firstLoginCompleted;
  final String createdAt;
  final String updatedAt;

  Customer({
    required this.id,
    required this.customerName,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.zone,
    required this.state,
    required this.district,
    this.age,
    this.imageUrl,
    required this.firstLoginCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    print('Customer JSON: $json');
    return Customer(
      id: json['customer_id'] ?? json['id'] ?? 0,
      customerName: json['name'] ?? json['customer_name'] ?? 'Unknown',
      mobileNumber: json['mobile_number'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      address: json['address'] ?? 'N/A',
      zone: json['zone'] ?? 'N/A',
      state: json['state'] ?? 'N/A',
      district: json['district'] ?? 'N/A',
      age: json['age'],
      imageUrl: json['image_url'],
      firstLoginCompleted: json['first_login_completed'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class CustomerManagementScreen extends StatefulWidget {
  final String token;
  final dynamic user;

  const CustomerManagementScreen({Key? key, required this.token, this.user}) : super(key: key);

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  String _searchQuery = '';
  List<Customer> customers = [];
  bool _isLoading = true;
  int _currentIndex = 0; // Home tab is selected

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== Fetching Customers ===');
      print('Token: ${widget.token}');

      final response = await http.get(
        Uri.parse('https://farmercrate.onrender.com/api/admin/customers'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> customerList = data['data'] as List;
          print('Found ${customerList.length} customers');

          setState(() {
            customers = customerList
                .map((customerJson) => Customer.fromJson(customerJson))
                .toList();
            _isLoading = false;
          });

          print('Successfully loaded ${customers.length} customers');

        } else {
          print('API returned success: false or no data');
          setState(() {
            customers = [];
            _isLoading = false;
          });
          _showErrorSnackBar('No customer data available');
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Authentication failed. Please login again.');
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching customers: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Network error: $e');
    }
  }

  Future<void> _deleteCustomer(int customerId) async {
    try {
      print('Deleting customer with ID: $customerId');
      final response = await http.delete(
        Uri.parse('https://farmercrate.onrender.com/api/admin/customers/$customerId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            customers.removeWhere((customer) => customer.id == customerId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to delete customer');
        }
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Failed to delete customer');
      }
    } catch (e) {
      print('Error deleting customer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting customer: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text('Are you sure you want to delete customer "${customer.customerName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCustomer(customer.id);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumer Management'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCustomers,
            tooltip: 'Refresh',
          ),
        ],
      ),
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
                child: _isLoading ? _buildLoadingWidget() : _buildCustomerList(),
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
                Icons.people_alt_outlined,
                size: 60,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading Customers...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait while we fetch customer details',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _fetchCustomers,
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
                hintText: 'Search customers...',
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

  Widget _buildCustomerList() {
    final filteredCustomers = customers.where((customer) {
      return _searchQuery.isEmpty ||
          customer.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.mobileNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.zone.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.state.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.district.toLowerCase().contains(_searchQuery.toLowerCase());
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
          // Show count and filter status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Customers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '${filteredCustomers.length} customer${filteredCustomers.length != 1 ? 's' : ''}',
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
            child: filteredCustomers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredCustomers.length,
              itemBuilder: (context, index) {
                return _buildCustomerCard(filteredCustomers[index]);
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
              'No customers found',
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

  Widget _buildCustomerCard(Customer customer) {
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
          backgroundImage: customer.imageUrl != null ? NetworkImage(customer.imageUrl!) : null,
          radius: 25,
          backgroundColor: Colors.green[100],
          child: customer.imageUrl == null
              ? Text(
            customer.customerName.split(' ').map((e) => e[0]).join(''),
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 20,
            ),
          )
              : null,
        ),
        title: Text(
          customer.customerName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(customer.email, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text('${customer.zone}, ${customer.state}', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(customer),
        ),
        onTap: () => _showUserDetails(customer),
      ),
    );
  }

  void _showUserDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: customer.imageUrl != null ? NetworkImage(customer.imageUrl!) : null,
                        radius: 30,
                        backgroundColor: Colors.green[100],
                        child: customer.imageUrl == null
                            ? Text(
                          customer.customerName.split(' ').map((e) => e[0]).join(''),
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 20,
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
                              customer.customerName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            Text(
                              'Customer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.person, 'Customer ID:', 'CUST${customer.id.toString().padLeft(3, '0')}'),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.email, 'Email:', customer.email),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone, 'Phone:', customer.mobileNumber),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on, 'Address:', customer.address),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.map, 'Zone:', customer.zone),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_city, 'State:', customer.state),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.home, 'District:', customer.district),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.cake, 'Age:', customer.age != null ? '${customer.age} years' : 'Not specified'),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today, 'Member Since:', _formatDate(customer.createdAt)),
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
          ),
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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