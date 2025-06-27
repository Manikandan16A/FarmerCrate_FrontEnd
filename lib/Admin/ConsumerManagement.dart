import 'package:flutter/material.dart';


class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final int age;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.age,
  });
}

class CustomerManagementScreen extends StatefulWidget {
  @override
  _CustomerManagementScreenState createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  List<Customer> customers = [
    Customer(
      id: 'USR001',
      name: 'John Customer',
      email: 'john.customer@email.com',
      phone: '+1234567890',
      location: 'California, USA',
      age: 32,
    ),
    Customer(
      id: 'USR004',
      name: 'Emma Customer',
      email: 'emma.customer@email.com',
      phone: '+1234567891',
      location: 'New York, USA',
      age: 28,
    ),
  ];

  void _deleteCustomer(Customer customer) {
    setState(() {
      customers.remove(customer);
    });
  }

  void _showUserInfo(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 30,
                      child: Text(
                        customer.name.split(' ').map((e) => e[0]).join(''),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
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
                SizedBox(height: 24),
                _buildInfoRow(Icons.person, 'User ID:', customer.id),
                SizedBox(height: 16),
                _buildInfoRow(Icons.email, 'Email:', customer.email),
                SizedBox(height: 16),
                _buildInfoRow(Icons.phone, 'Phone:', customer.phone),
                SizedBox(height: 16),
                _buildInfoRow(Icons.location_on, 'Location:', customer.location),
                SizedBox(height: 16),
                _buildInfoRow(Icons.cake, 'Age:', '${customer.age} years'),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green[600],
          size: 20,
        ),
        SizedBox(width: 12),
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

  void _showDeleteDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete User',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 16),
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete user "${customer.name}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteCustomer(customer);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Customer Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green,
            padding: EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Total Users: ${customers.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.grey[50]!,
                                  Colors.white,
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {},
                                splashColor: Colors.green.withOpacity(0.1),
                                highlightColor: Colors.green.withOpacity(0.05),
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header Section
                                      Row(
                                        children: [
                                          // Avatar with enhanced styling
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.green[300]!,
                                                  Colors.green[500]!,
                                                  Colors.green[700]!,
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green.withOpacity(0.4),
                                                  spreadRadius: 0,
                                                  blurRadius: 12,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              backgroundColor: Colors.transparent,
                                              radius: 32,
                                              child: Text(
                                                customer.name.split(' ').map((e) => e[0]).join(''),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 20),
                                          // Name and ID Section
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  customer.name,
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.grey[800],
                                                    letterSpacing: 0.3,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: Colors.grey[300]!,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.tag,
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        customer.id,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey[700],
                                                          fontWeight: FontWeight.w600,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 20),

                                      // Customer Badge
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.green[50]!,
                                                  Colors.green[100]!,
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(25),
                                              border: Border.all(
                                                color: Colors.green[200]!,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green.withOpacity(0.1),
                                                  spreadRadius: 0,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.green[600],
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Active Customer',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 24),

                                      // Action Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green[400]!,
                                                    Colors.green[600]!,
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withOpacity(0.3),
                                                    spreadRadius: 0,
                                                    blurRadius: 12,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                borderRadius: BorderRadius.circular(16),
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(16),
                                                  onTap: () => _showUserInfo(customer),
                                                  child: Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 16),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.info_outline_rounded,
                                                          size: 20,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'User Info',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.red[400]!,
                                                    Colors.red[600]!,
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red.withOpacity(0.3),
                                                    spreadRadius: 0,
                                                    blurRadius: 12,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                borderRadius: BorderRadius.circular(16),
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(16),
                                                  onTap: () => _showDeleteDialog(customer),
                                                  child: Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 16),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.delete_outline_rounded,
                                                          size: 20,
                                                          color: Colors.white,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 0.5,
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
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}